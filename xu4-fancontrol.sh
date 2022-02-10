#!/bin/bash
REFRESH="1"
DISK_TEMP_THRESHOLD="45"
CPU_TEMP_THRESHOLD="60"
FAN_CHANGED="*"

get_disk_dev_info() {
    # Pull disk info from /dev/sd*
    SATA=$(fdisk -l | awk '/^\/dev\/sd/ {printf "%s ", $1}')
}

get_disk_temperature() {
    for i in "${!SATA[@]}"
    do
        # Declare and assign variable separately to avoid masking return value
        DISK_TEMP[$i]="0"
        local t
        t=$(smartctl -a "${SATA[$i]}" -d sat | grep "Temp")
        if (( $? == 0 ))
        then
            local temp=$(echo ${t} | awk '{print $10}')
            DISK_TEMP[$i]="$temp"
        else
            DISK_TEMP[$i]="0"
        fi
    done
}

get_cpu_temperature() {
    for i in 0 1 2 3 4
    do
        _t=$(($(</sys/class/thermal/thermal_zone${i}/temp) / 1000))
        CPU_TEMP[$i]="$_t"
    done
}

fan_on() {
#   origin
#   i2cset -y 1 0x60 0x05 0x00
#   my address
    i2cset -y 0 0x60 0x05 0xf0
}

fan_off() {
#   origin
#   i2cset -y 1 0x60 0x05 0x05
#   my address
    i2cset -y 0 0x60 0x05 0xf5
}

handle_fan() {
    for i in "${!DISK_TEMP[@]}"
    do
        if (( "${DISK_TEMP[$i]}" > "${DISK_TEMP_THRESHOLD}" ))
        then
            if [[ "${FAN_CHANGED}" != "1" ]]
            then
                echo "Turning fan on because disk $i has hit the threshold"
            fi

            FAN_CHANGED="1"
            fan_on
            return
        fi
    done
    
    for i in "${!CPU_TEMP[@]}"
    do
        if (( "${CPU_TEMP[$i]}" > "${CPU_TEMP_THRESHOLD}" ))
        then
            if [[ "${FAN_CHANGED}" != "1" ]]
            then
                echo "Turning fan on because CPU $i has hit the threshold"                
            fi

            FAN_CHANGED="1"
            fan_on
            return
        fi
    done
    
    # No fuss, fan is off
    if [[ "${FAN_CHANGED}" != "0" ]]
    then
        echo "All temps nominal, turning fan off"
        FAN_CHANGED="0"
    fi
    fan_off
}

# Ensure smartctl is installed
which smartctl > /dev/null
if [[ $? -eq 0 ]]; then
    # Continuous loop
    while true; do
        get_disk_dev_info
        get_disk_temperature
        get_cpu_temperature
        handle_fan

        sleep ${REFRESH}
    done
else
    (>&2 echo "smartctl command was not found")
fi
