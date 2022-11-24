#!/bin/bash
usage(){

	echo "$0 "" <command> <options>"
	echo ""
	echo "list of available commands:"
	echo ""
	echo "hdfs-transfer	" "	<local_path> <remote_destination>"
	echo ""
	echo "         copies a file/folder from <localPath> to <remote_destination> "
	echo ""

	echo "deploy	" "	<coordinators_zip_path> <local_destination_path> <start_date> <end_date> <oozie_server> <nema_node>"
	echo ""
	echo "	deploys and starts coodirnator that are contained in the coordinator_zip_path"
	echo "	The start date and the end date are customizable"
	echo "	oozie server and name node are customizable"
	echo ""	
	
	echo "status	" "	<status>	" "shows all the coordinators that are in the status <status>";

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

        hdfs-transfer)
        
        checkArguments "$#" 3 ;
        argOk=$?;
        if [ $argOk -ne 0 ]; then
          usage;
          exit 2;
				fi
				if [ -z "$2" ]; then
                        echo $0: usage:   local  directory missing.
			usage;
                        exit 1
                fi
				
                if [ -z "$3" ]; then
                        echo $0: usage:   hdfs destination directory missing.
			usage;
                        exit 1
                fi

				localPath=$2;
				destinationPath=$3;
				source hdfs-copier.sh $localPath $destinationPath;

				;;
          
        deploy)
        
        checkArguments "$#" 10;
        argOk=$?;
        
          if [ $argOk -ne 0 ]; then
			  usage;
			  exit 2;
		  fi
          if [ -z "$2" ]; then
			  echo $0: usage: zip containing coordinators missing.
			  usage;
			  exit 1
          fi
          if [ -z "$3" ]; then
			  echo $0: usage: local destination path is missing  missing.
			  usage;
			  exit 1
          fi
	  if [ -z "$4" ]; then
			  echo $0: usage: a start date to be set in coordinators property file is missing.
			  usage;
			  exit 1
          fi
	  if [ -z "$5" ]; then
                         echo $0: usage: an end date to be set in coordinators property file is missing.
         	         usage;
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
                          echo $0: usage: job tracker to be set in coordinators property file is missing.
                          usage;
                          exit 1
          fi
		  if [ -z "$9" ]; then
                          echo $0: usage: hive jdbc connection to be set in coordinators property file is missing.
                          usage;
                          exit 1
          fi
		  if [ -z "${10}" ]; then
                          echo $0: usage: password hive connection to be set in coordinators property file is missing.
                          usage;
                          exit 1
          fi
				
        funout=$?;
        
       
				
				if [ $funout != 0	]; then
					exit -1;
				
				fi

				zipPath=$2;
				localDestinationPath=$3;
				startDate=$4;
				endDate=$5;
				oozieServer=$6
				nameNode=$7
				jobTracker=$8
				hiveJdbc=$9
				passwordHive=${10}

				source coordinator-manager-invoker.sh deploy $zipPath $localDestinationPath $startDate $endDate $oozieServer $nameNode $jobTracker $hiveJdbc $passwordHive
			
          ;;

		  
        deploy-sqoop)
        
        checkArguments "$#" 13;
         argOk=$?;
        
          if [ $argOk -ne 0 ]; then
			  usage;
			  exit 2;
		  fi
          if [ -z "$2" ]; then
			  echo $0: usage: zip containing coordinators missing.
			  usage;
			  exit 1
          fi
          if [ -z "$3" ]; then
			  echo $0: usage: local destination path is missing  missing.
			  usage;
			  exit 1
          fi
	  if [ -z "$4" ]; then
			  echo $0: usage: a start date to be set in coordinators property file is missing.
			  usage;
			  exit 1
          fi
	  if [ -z "$5" ]; then
                         echo $0: usage: an end date to be set in coordinators property file is missing.
         	         usage;
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
                          echo $0: usage: job tracker to be set in coordinators property file is missing.
                          usage;
                          exit 1
          fi
		   if [ -z "$9" ]; then
                          echo $0: usage: jdbc hive to be set in coordinators property file is missing.
                          usage;
                          exit 1
          fi
		   if [ -z "$10" ]; then
                          echo $0: usage: password for hive to be set in coordinators property file is missing.
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
				
        funout=$?;
        
       
				
				if [ $funout != 0	]; then
					exit -1;
				
				fi

				zipPath=$2;
				localDestinationPath=$3;
				startDate=$4;
				endDate=$5;
				oozieServer=$6;
				nameNode=$7;
				jobTracker=$8;
				hiveJdbc=$9;
				passwordHive=${10};
				dbServer=${11};
				dbUsername=${12};
				dbPassword=${13}
				source coordinator-manager-invoker.sh deploy-sqoop $zipPath $localDestinationPath $startDate $endDate $oozieServer $nameNode $jobTracker $hiveJdbc $passwordHive $dbServer $dbUsername $dbPassword
			
          ;;

		  
		  
	    help)
			usage
		;;
		
		status)
			checkArguments "$#" 2;
			argOk=$?;
      
			  if [ $argOk -ne 0 ]; then
					usage;
					exit 2;
			  fi
				
			  if [ -z "$2" ]; then
						echo usage: $0 $1 "<status>"  - status missing;
									usage;
						exit 1
			  fi
			  status=$2;
			  source coordinator-manager-invoker.sh 
			  funout=$?;
				if [ $funout != 0	]; then
					exit -1;				
							
				fi
			  source coordinator-manager-invoker.sh status $status

			;;
        *)
		echo "$KEY not recognized as a command";
		 usage
		;;
        esac
		
