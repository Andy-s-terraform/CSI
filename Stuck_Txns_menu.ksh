#!/bin/ksh
# Author:       AndrewSmith
#
# Display menu with which to run the Stuck Txns checks
# using a here document
#############
#FUNCTIONS
#############

LOGFILE="/app/cis/batch/daily/data_exercises/stuck_Txns/previous_runs_log.txt"

# Create lock file to prevent dual running
if [ -f /app/cis/batch/daily/data_exercises/stuck_Txns/lockfile ]
then
	echo "================================================"
	echo "Warning: /app/cis/batch/daily/data_exercises/stuck_Txns/stuck_Txns_menu.ksh already running...check with colleagues and try later."
	echo "To continue, you must delete /app/cis/batch/daily/data_exercises/stuck_Txns/lockfile"
	echo "================================================"
	exit 1
else

	touch /app/cis/batch/daily/data_exercises/stuck_Txns/lockfile
fi

. /app/cis/batch/daily/data_exercises/stuck_Txns/myfunc

source /app/cis/batch/daily/script/profile/dynamicproperties.ksh

DB_CONNECT="$ODS_USER/$ODS_PASSWORD@$ODS_ORACLE_SID"

STXN_SCRIPTS="/app/cis/batch/daily/data_exercises/stuck_Txns"
#############
TDAY=$(date '+%y%m%d')

RUN_DT=$(date '+%d-%m-%Y %H:%M')

EXIT_FLG=0

echo 
echo " "
echo -e "Enter the NINO relating to the stuck txn incident: \c"
read NINO

grep $NINO $LOGFILE

if [ $? -eq 0 ]
then
	echo " "
	echo "Warning: $NINO already exists in $LOGFILE"
	echo " "
	echo "Incident No.    NINO         Date"
	echo "------------    ----         ----"
	grep $NINO $LOGFILE
	echo " "
	echo -e "\033[33mDo you wish to continue? \033[0m \c"
	getyn
	
	if [ $? -eq 0 ]
	then
		EXIT_FLG=0
	else
		EXIT_FLG=1

		if [ -f /app/cis/batch/daily/data_exercises/stuck_Txns/lockfile ]
		then
			rm /app/cis/batch/daily/data_exercises/stuck_Txns/lockfile
		fi
	fi
else
	EXIT_FLG=0
fi

if [ $EXIT_FLG -eq 0 ]
then

echo " "
echo -e "Enter Enter a TechNow incident Number: \c"
read INC

echo "$INC    $NINO    $RUN_DT" >> $LOGFILE

while true
do

echo 

cat <<!


                                Stuck Txns Check Menu
                                =====================

		       Working with INCIDENT & NINO: $INC   $NINO

                       Option 1 - PSCS - Check Staging
                       Option 2 - PSCS - Update Error flags in Staging to 'N'
                       Option 3 - PSCS - Check Claim Count

                       Option 4 - CACS - Check Staging
                       Option 5 - CACS - Update Error flags in Staging to 'N'

                       Option 6 - NTC  - Check Staging
                       Option 7 - NTC  - Update Error flags in Staging to 'N'

                       Option 8 - Check/Update BATCH_DATE
                       Option 9 - Reset threads to 'ready for start'
                      Option 10 - Check ERROR_LOG partitions
                      Option 11 - Run Partition Management to create new ERROR_LOG partitions
                      Option 12 - Run PSCS Process
                      Option 13 - Run CACS Process
                      Option 14 - Run NTC  Process
                      Option 15 - Check ERROR_LOG Table for processing error message

                       Option q - Quit the menu

!

#set -x

# ask the user to enter their choice
echo -e "
      Please enter an Option: \c"

# store chosen option in variable called CHOICE
read CHOICE JUNK        # JUNK for extra input

# now use case to execute chosen option
case "$CHOICE" in       # quotes in case nothing typed in
         1) sqlplus $DB_CONNECT @$STXN_SCRIPTS/pscs_staging_check.sql $NINO
	    echo " "
	    echo -e "\033[33mMake a note of the FILE_ID and LINE_NUMBER of the transaction in error...\033[0m"
            pause
            ;;
         2) $STXN_SCRIPTS/pscs_set_flags_to_N.ksh $NINO
	    sqlplus $DB_CONNECT @$STXN_SCRIPTS/pscs_staging_check.sql $NINO
            pause
            ;;
        3) sqlplus $DB_CONNECT @$STXN_SCRIPTS/pscs_check_Claim_Count.sql $NINO
           pause
           ;;
        4) sqlplus $DB_CONNECT @$STXN_SCRIPTS/cacs_staging_check.sql $NINO
           echo " "
           echo -e "\033[33mMake a note of the FILE_ID and LINE_NUMBER of the transaction in error...\033[0m"
           pause
           ;;
        5) $STXN_SCRIPTS/cacs_set_flags_to_N.ksh $NINO
           sqlplus $DB_CONNECT @$STXN_SCRIPTS/cacs_staging_check.sql $NINO
           pause
           ;;
        6) sqlplus $DB_CONNECT @$STXN_SCRIPTS/ntc_staging_check.sql $NINO
           echo " "
           echo -e "\033[33mMake a note of the FILE_ID and LINE_NUMBER of the transaction in error...\033[0m"
           pause
           ;;
        7) $STXN_SCRIPTS/ntc_set_flags_to_N.ksh $NINO
           sqlplus $DB_CONNECT @$STXN_SCRIPTS/ntc_staging_check.sql $NINO 
           pause
           ;;
        8) sqlplus $DB_CONNECT @$STXN_SCRIPTS/update_batch_date.sql
           pause
           ;;
        9) /app/cis/batch/daily/script/cis_thread_reset_wrapper_ods_night.ksh
            pause
            ;;
        10) sqlplus $DB_CONNECT @$STXN_SCRIPTS/check_error_log_partitions.sql
	    pause
            ;;
        11) /app/cis/batch/daily/script/cis_part_mgmt_ods.ksh
            pause
            ;;
        12) /app/cis/batch/daily/script/cis_pscs_process.ksh
            pause
            ;;
        13) /app/cis/batch/daily/script/cis_cacs_process.ksh
            pause
            ;;
        14) /app/cis/batch/daily/script/cis_ntc_process.ksh
            pause
            ;;
        15) echo "  DATE              Error Message"
	    echo "  ----              -------------"
	    sqlplus $DB_CONNECT @$STXN_SCRIPTS/error_log_check.sql $NINO | egrep 'CACS|No person_role|Functional Error|Trying to convert|ORA-06502|No claim available|Multiple open payment'
            pause
            ;;
        q) echo -e "      Quit requested.
                                "
		rm /app/cis/batch/daily/data_exercises/stuck_Txns/lockfile
                exit 0
           ;;
        *) echo -e "
                 \tSorry - $CHOICE is not a valid option"
           pause
           ;;
esac

#echo -e -n " Press any key to continue"
#read KEY1

done

else

	echo "Exit requested."
	rm /app/cis/batch/daily/data_exercises/stuck_Txns/lockfile
fi
