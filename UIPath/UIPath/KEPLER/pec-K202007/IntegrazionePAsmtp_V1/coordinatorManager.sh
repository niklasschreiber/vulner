#!/bin/sh

OOZIE_SERVER=http://$oozieServer:11000/oozie
CMD_STATUS='oozie jobs -oozie $OOZIE_SERVER -jobtype coordinator -filter status=$STATUS'
CMD_START='oozie job -oozie $OOZIE_SERVER -config $CONFIG -run'
CMD_STOP='oozie job -oozie $OOZIE_SERVER -kill $JOB_ID'

KEY=$1


if [ -z "$1" ]; then
    echo "Invalid command: use '--help' for details"
    exit 1
fi

case $KEY in

        start-all)
                if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help' for help details
                        exit 1
                fi

                COORD_FILES="$2/*"
                for file in $COORD_FILES
                do
                        echo "["$KEY"] - Starting coordinator $file..."
                        CONFIG=$file
                        eval "$CMD_START"
                done

                echo "["$KEY"] - Starting all coordinators...";;

        start)
                if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_file]
                        echo use '--help' for help details
                        exit 1
                fi

                CONFIG=$2
                echo "["$KEY"] - Starting coordinator $CONFIG"
                eval "$CMD_START";;

        stop)
                if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [coordinator_job_id]
                        echo use '--help' for help details
                        exit 1
                fi

                JOB_ID=$2
                echo "["$KEY"] - Stopping job coordinator $JOB_ID"
                eval "$CMD_STOP";;


        status)
                if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [jobtype]
                        echo use '--help' for help details
                        exit 1
                fi
                STATUS=${2}
                echo "["$KEY"] - Shows $STATUS jobs ..."
                eval "$CMD_STATUS";;

        set-start-date)
                if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [start-date]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator start_date $2 in $entry..."
                        CMD_START_DATE='sed -i "/start_date=/c\start_date=${2}" ${entry}'
                        eval "${CMD_START_DATE}"
                done
                echo "["$KEY"} - Setted coordinator start_date"
        ;;

        set-end-date)
                if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [end-date]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator end_date $2 in $entry..."
                        CMD_END_DATE='sed -i "/end_date=/c\end_date=${2}" ${entry}'
                        eval "${CMD_END_DATE}"
                done
                echo "["$KEY"} - Setted coordinator end_date"
        ;;
		set-name-node)
                 if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [name-node]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator namenode $2 in $entry..."
                        CMD_OOZIE_SERVER='sed -i "/nameNode=/c\nameNode=${2}" ${entry}'
                        eval "${CMD_OOZIE_SERVER}"
                done
                echo "["$KEY"} - Setted coordinator name_node"
        ;;
		set-job-tracker)
		 if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [job-tracker]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator jobTracker $2 in $entry..."
                        CMD_OOZIE_SERVER='sed -i "/jobTracker=/c\jobTracker=${2}:8050" ${entry}'
                        eval "${CMD_OOZIE_SERVER}"
                done
                echo "["$KEY"} - Setted coordinator job tracker"
		;;

                set-hive-jdbc)
		 if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [hiveJdbc]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator hiveJdbc $2 in $entry..."
                        CMD_OOZIE_SERVER='sed -i "/hiveJdbc=/c\hiveJdbc=$2" ${entry}'
                        eval "${CMD_OOZIE_SERVER}"
                done
                echo "["$KEY"} - Setted coordinator hiveJdbc"
		;;

                set-hive-password)
		 if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [passwordHive]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator hiveJdbc $2 in $entry..."
                        CMD_OOZIE_SERVER='sed -i "/passwordHive=/c\passwordHive=$2" ${entry}'
                        eval "${CMD_OOZIE_SERVER}"
                done
                echo "["$KEY"} - Setted coordinator passwordHive"
		;;
		
		
		
		set-db-server)
		 if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [dbServer]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator dbServer $2 in $entry..."
                        CMD_OOZIE_SERVER='sed -i "/dbServer=/c\dbServer=${2}" ${entry}'
                        eval "${CMD_OOZIE_SERVER}"
                done
                echo "["$KEY"} - Setted coordinator db-server"
		;;
		
		set-db-username)
		 if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [dbUsername]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator dbUsername $2 in $entry..."
                        CMD_OOZIE_SERVER='sed -i "/dbUsername=/c\dbUsername=${2}" ${entry}'
                        eval "${CMD_OOZIE_SERVER}"
                done
                echo "["$KEY"} - Setted coordinator db-username"
		;;
		
		set-db-password)
		 if [ -z "$2" ]; then
                        echo Missing argument for option: $1 [dbPassword]
                        echo use '--help command' for help details
                        exit 1
                fi
                if [ -z "$3" ]; then
                        echo Missing argument for option: $1 [coordinator_properties_directory]
                        echo use '--help command' for help details
                        exit 1
                fi

                COORD_FILES=$3
                i=$((${#COORD_FILES}-1))
                last_char=${COORD_FILES:$i:1}
                if [ "$last_char" != "/" ];
                    then
                        COORD_FILES="$COORD_FILES/*"
                    else
                        COORD_FILES="$COORD_FILES*"
                fi

                for entry in $COORD_FILES
                do
                        echo "["$KEY"] - Replacing coordinator dbPassword $2 in $entry..."
                        CMD_OOZIE_SERVER='sed -i "/dbPassword=/c\dbPassword=${2}" ${entry}'
                        eval "${CMD_OOZIE_SERVER}"
                done
                echo "["$KEY"} - Setted coordinator db-password"
		;;
		
		
		
        --help)
                echo "Usage:
				- start-all <coordinator_properties_directory> --> creates and starts all coordinator jobs related to the properties files inside the directory passed
                - start <coordinator_properties_file> --> creates and starts a coordinator job related to the properties file passed
                - stop <coordinator_job_id> --> kill a job coordinator
                - status --> <jobtype> returns all the coordinators job having the specified jobtype
                - set-start-date <start-date> <coordinator_properties_directory> --> sets the start date to all coordinators properties files inside the directory passed
                - set-end-date <end-date> <coordinator_properties_directory> --> sets the end date to all coordinators properties files inside the directory passed
				- set-name-node <name-node> <coordinator_properties_directory> --> sets the name node host to all coordinators properties files inside the directory passed
				- set-job-tracker <jobtracker> <coordinator_properties_directory> --> sets the jobtracker host to all coordinators properties files inside the directory passed
                                - set-hive-Jdbc <hiveJdbc> <coordinator_properties_directory> --> sets the hiveJdbc to all coordinators properties files inside the directory passed
                                - set-hive-password <passwordHive> <coordinator_properties_directory> --> sets the hivePassword to all coordinators properties files inside the directory passed";;

        *)      echo "Invalid command: use '--help command' for details";;

esac
