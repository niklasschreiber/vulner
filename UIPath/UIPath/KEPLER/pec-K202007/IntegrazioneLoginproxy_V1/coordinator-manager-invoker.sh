#!/bin/bash

usage(){
echo "$0 deploy <zip_file> <local_destination_path> <start_date> <end_date> <oozie_server> <name_node>"
echo "  deploys coordinators contained in zip_file unpacking it to <local_destination_path> setting <start_date> , <end_date> , <oozie_server> and <name_node> "
}


checkArguments(){

  if [ "$1" -ne "$2" ]; then
    echo "the number of passed arguments ($1) does not match the expected argument ($2)"
    return 2;
  else
    return 0;  
  fi
}

KEY=$1;


case $KEY in

        deploy)
        
			checkArguments $# 10;
			argOk=$?;
        
				if [ $argOk -ne 0 ]; then
				  usage;
				  exit 2
				fi
				if [ -z "$2" ]; then
				  echo $0: usage: zip file containing coordinatoor directory missing
				  exit 1
				fi
				if [ -z "$3" ]; then
                                  echo $0: missing destination path of unzipped file
                                  exit 1
                                fi
				if [ -z "$4" ]; then
                                  echo $0: usage: missing start date to be set for the coordinators
                                  exit 1
                                fi
				if [ -z "$5" ]; then
                                  echo $0: usage: missing end date to be set for the coordinators
                                  exit 1
                                fi
				if [ -z "$6" ]; then
				   echo $0: usage: a oozie server to be set in coordinators property file is missing.
				   usage;
				   exit 1
				fi
				if [ -z "$7" ]; then
				   echo $0: usage: name node to be set in coordinators property file is missing.
				   usage;
				   exit 1
				fi
				if [ -z "$8" ]; then
                                   echo $0: usage: jobTracker to be set in coordinators property file is missing.
                                   usage;
                                   exit 1
                fi
				if [ -z "$9" ]; then
                                   echo $0: usage: hive jdbc to be set in coordinators property file is missing.
                                   usage;
                                   exit 1
                fi
				if [ -z "$10" ]; then
                                   echo $0: usage: hive password to be set in coordinators property file is missing.
                                   usage;
                                   exit 1
                fi

				
				zipFile=$2;
				destPath=$3;
				startDate=$4;
				endDate=$5;
				folderName=${zipFile%-*};
				folderName=${folderName#*/};
				oozieServer=$6
				nameNode=$7
				jobTracker=$8
				hiveJdbc=$9
				passwordHive=${10}
                                export oozieServer=$6

				
				if [ -d $destPath ]; then
				
					echo "unzipping the file $zipFile into $destPath";
					unzip $zipFile -d $destPath;
					zipOk=$?;
					if [ $zipOk = 0 ]; then 
						basePath=$destPath/$folderName;
					else
						echo "Cannot unzip $zipFile into $destPath - Invalid zip file";
						exit -1;
					fi
						
				else
					echo "cannot unzip the file - the path $destPath does not exist";
					exit -1;
						
				fi
				
				funout=$?;
				if [ $funout != 0 ]; then
					exit -1;
				fi
				
          if
					source coordinatorManager.sh set-start-date $startDate $destPath
					source coordinatorManager.sh set-end-date $endDate $destPath &&
					source coordinatorManager.sh set-name-node $nameNode $destPath &&
					source coordinatorManager.sh set-job-tracker $jobTracker $destPath &&
					source coordinatorManager.sh set-hive-jdbc $hiveJdbc $destPath &&
					source coordinatorManager.sh set-hive-password $passwordHive $destPath &&
					source coordinatorManager.sh start-all $destPath &&
           
		  source coordinatorManager.sh status PREP;
          then 
            echo "all the coordinators  have been started"       
          else 
            echo "FATAL ERROR OCCURED while starting the coordinators . Aborting..."
            exit 2;
          fi
					
        ;;
				

	 deploy-sqoop)
        
			checkArguments $# 13;
			argOk=$?;
        
				if [ $argOk -ne 0 ]; then
				  usage;
				  exit 2
				fi
				if [ -z "$2" ]; then
				  echo $0: usage: zip file containing coordinatoor directory missing
				  exit 1
				fi
				if [ -z "$3" ]; then
                                  echo $0: missing destination path of unzipped file
                                  exit 1
                                fi
				if [ -z "$4" ]; then
                                  echo $0: usage: missing start date to be set for the coordinators
                                  exit 1
                                fi
				if [ -z "$5" ]; then
                                  echo $0: usage: missing end date to be set for the coordinators
                                  exit 1
                                fi
				if [ -z "$6" ]; then
				   echo $0: usage: a oozie server to be set in coordinators property file is missing.
				   usage;
				   exit 1
				fi
				if [ -z "$7" ]; then
				   echo $0: usage: name node to be set in coordinators property file is missing.
				   usage;
				   exit 1
				fi
				if [ -z "$8" ]; then
                                   echo $0: usage: jobTracker to be set in coordinators property file is missing.
                                   usage;
                                   exit 1
                fi
				if [ -z "$9" ]; then
                                   echo $0: usage: hive jdbc to be set in coordinators property file is missing.
                                   usage;
                                   exit 1
                fi
				if [ -z "$10" ]; then
                                   echo $0: usage: hive password to be set in coordinators property file is missing.
                                   usage;
                                   exit 1
                fi
				if [ -z "$11" ]; then
									echo $0: usage: db server to be set in coordinators property file is missing.
									usage;
									exit 1
				fi
				if [ -z "$12" ]; then
									echo $0: usage: db username to be set in coordinators property file is missing.
									usage;
									exit 1
				fi
				if [ -z "$13" ]; then
									echo $0: usage: db password to be set in coordinators property file is missing.
									usage;
									exit 1
				fi
				
				zipFile=$2;
				destPath=$3;
				startDate=$4;
				endDate=$5;
				folderName=${zipFile%-*};
				folderName=${folderName#*/};
				oozieServer=$6
				nameNode=$7
				jobTracker=$8
				hiveJdbc=$9
				passwordHive=${10}
				dbServer=${11}
				dbUsername=${12}
				dbPassword=${13}
                export oozieServer=$6

				
				if [ -d $destPath ]; then
				
					echo "unzipping the file $zipFile into $destPath";
					unzip $zipFile -d $destPath;
					zipOk=$?;
					if [ $zipOk = 0 ]; then 
						basePath=$destPath/$folderName;
					else
						echo "Cannot unzip $zipFile into $destPath - Invalid zip file";
						exit -1;
					fi
						
				else
					echo "cannot unzip the file - the path $destPath does not exist";
					exit -1;
						
				fi
				
				funout=$?;
				if [ $funout != 0 ]; then
					exit -1;
				fi
				
          if
					source coordinatorManager.sh set-start-date $startDate $destPath
					source coordinatorManager.sh set-end-date $endDate $destPath &&
					source coordinatorManager.sh set-name-node $nameNode $destPath &&
					source coordinatorManager.sh set-job-tracker $jobTracker $destPath &&
					source coordinatorManager.sh set-hive-jdbc $hiveJdbc $destPath &&
					source coordinatorManager.sh set-hive-password $passwordHive $destPath &&
					source coordinatorManager.sh set-db-server $dbServer $destPath &&
					source coordinatorManager.sh set-db-username $dbUsername $destPath &&
					source coordinatorManager.sh set-db-password $dbPassword $destPath &&
					source coordinatorManager.sh start-all $destPath &&

           
		  source coordinatorManager.sh status PREP;
          then 
            echo "all the coordinators  have been started"       
          else 
            echo "FATAL ERROR OCCURED while starting the coordinators . Aborting..."
            exit 2;
          fi
					
        ;;			
				
				
				
        status)
        
      checkArguments $# 2;
      argOk=$?;
      
      if [ $argOk -ne 0 ]; then
        usage;
        exit -1
      fi
      
			if [ -z "$2" ]; then
                             echo usage: $0 $1 <status>  - status missing;
						
                              exit 1
			fi
			
			funout=$?;
        
			if [ $funout != 0 ]; then
					exit -1;
			fi
      
			status=$2;
			source coordinatorManager.sh status $status
			;;
      
      help)
      usage;;
      *)
      echo "$KEY is not a recognize command"
      usage;;
      esac
               
