#!/bin/bash

RAID_MANAGER=/usr/bin/raidmgr_static
RAID_STATUS_FILE="/var/log/RAID_STATUS4LCD"
FROM_EMAIL="FROMEMAIL@ADDRESS.COM(ODROIDXU4)"
TO_EMAIL="TOEMAIL@ADDRESS.COM"
LOGFILE="/var/log/JMICRON_RAID_CONTROLLER.log"

date | tee $LOGFILE
##The Following call to the RAID manager using DC C0
#outputs the controller info, which is fairly detailed, and happens to also include the RAID status.
## SR C0  would work as well, but would only show information about the RAID.
$RAID_MANAGER << endl | tee -a $LOGFILE
DC C0
EX
endl
sleep 1

RAID_STATUS=`grep RaidStatus $LOGFILE | awk '{ print $NF }'`
echo | tee -a $LOGFILE
echo | tee -a $LOGFILE
echo "The current JMicron RAID controller status is: $RAID_STATUS" | tee -a $LOGFILE

##Possible RAID STATES
##Broken
##Degrade
##Rebuilding
##Normal

case $RAID_STATUS in
    Degrade)
      echo "Degraded" > $RAID_STATUS_FILE
      printf "`date`\nYour RAID is in a DEGRADED STATE!\n\nIt is recommended that an investigation and repair or \nreplacement of the failing drive be done as soon as possible.\nUse $RAID_MANAGER to determine which drive has failed.\n" | mailx -a "From: ${FROM_EMAIL}" -s "!!!DEGRADED RAID!!!" ${TO_EMAIL}
      ;;
  Broken)
      echo "Broken" > $RAID_STATUS_FILE
      printf "`date`\nYour RAID is in a BROKEN STATE!\n\nIt is recommended that an investigation and repair be done as soon as possible.\n" | mailx -a "From: ${FROM_EMAIL}" -s "!!!BROKEN RAID!!!" ${TO_EMAIL}
      ;;
  Rebuilding)
      echo "Rebuilding" > $RAID_STATUS_FILE
      printf "`date`\nYour RAID is currently rebuilding.\n" | mailx -a "From: ${FROM_EMAIL}" -s "Rebuilding RAID..." ${TO_EMAIL}
      ;;
  Normal)
      echo "Normal" > $RAID_STATUS_FILE
      printf "`date`\nYour RAID is Normal\n"
      ;;
  *)
      echo "Unknown" > $RAID_STATUS_FILE
      printf "`date`\nHmm, Not sure what's going on with the RAID.  Your RAID status is unknown. This isn't necessarily a bad thing, it just means we couldn't grab the status\n" | mailx -a "From $FROM_EMAIL" -s "Unknown RAID Status..." ${TO_EMAIL}
      ;;
esac
