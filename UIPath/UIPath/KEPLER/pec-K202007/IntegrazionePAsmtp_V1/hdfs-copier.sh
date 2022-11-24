#!/bin/bash
usage(){
	echo "$0 <local_path> <remote_path>";
	echo "  copies file/folder from <local_path> to HDFS <remote_path>";
}
	if [ "$#" -ne 2 ]; then
	  echo "Number of passed arguments ($#) does not match number of expected arguments (2). Aborting..."
	  usage
	  exit 2
	fi

	if [ -z "$1" ]; then
	  echo "Missing local source path - Aborting..."
	  usage
	  exit 2;
	fi
	if [ -z "$2" ]; then
	  echo "Missing remote destination path - Aborting..."
	  exit 2;
	fi
	if [  "$2" = "/" ]; then

	  echo "the destination path cannot be root-path Aborting..."
	  exit 2

	fi

localPath=$1;
destPath=$2;

export HADOOP_USER_NAME=hdfs;

hdfs dfs -mkdir -p $destPath;

hdfs dfs -chmod -R 777 $destPath;

hdfs dfs -copyFromLocal -f $localPath $destPath;

echo $localPath has been copied into remote path $destPath;
