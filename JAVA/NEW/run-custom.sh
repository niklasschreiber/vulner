#!/bin/bash
echo "CONTAINER STARTUP"

## added the method
load_container_limits() {
    # Read in container limits and export the as environment variables
    if [ -f "/opt/run-java/container-limits" ]; then
       source "/opt/run-java/container-limits"
    fi
}


# Command line arguments given to this script
args="$*"

## added trust store
ORIGINAL_TRUSTSTORE="$JAVA_HOME/jre/lib/security/cacerts"
MERGED_TRUSTSTORE="/tmp/merged.truststore"
TRUSTSTORE_CERTIFICATES_SEARCH_PATTERN=${TRUSTSTORE_CERTIFICATES_SEARCH_PATTERN:-*}


echo "TRUSTSTORE_CERTIFICATES_PATH_LIST is : $TRUSTSTORE_CERTIFICATES_PATH_LIST"
echo "TRUSTSTORE_CERTIFICATES_SEARCH_PATTERN is : $TRUSTSTORE_CERTIFICATES_SEARCH_PATTERN"

if [[ ! -z "$TRUSTSTORE_CERTIFICATES_PATH_LIST" ]]; then
	TRUSTSTORE_PASS=${TRUSTSTORE_PASSWORD:-changeit}
	keytool -genkey -noprompt -alias temp -dname "CN=none, OU=none, O=none, L=none, S=none, C=IT" -keystore $MERGED_TRUSTSTORE -storepass $TRUSTSTORE_PASS -keypass $TRUSTSTORE_PASS -storetype PKCS12
	keytool -importkeystore -noprompt -srckeystore $ORIGINAL_TRUSTSTORE -srcstorepass changeit -destkeystore $MERGED_TRUSTSTORE -deststorepass $TRUSTSTORE_PASS
	IFS="," read -ra pathList <<< "$TRUSTSTORE_CERTIFICATES_PATH_LIST"
	echo "pathList: $pathList"
	for certpath in "${pathList[@]}"
	do
		if [ -d "$certpath" ]; then
		    echo "certpath: $certpath exist"
		    temp_cert_list=`ls $certpath/$TRUSTSTORE_CERTIFICATES_SEARCH_PATTERN`
		    for entry in $temp_cert_list
		    do
	  			fname=`basename $entry`
  				echo "import $entry ..."
  				echo "alias: $fname"
  				keytool -importcert -noprompt -file $entry -keystore $MERGED_TRUSTSTORE -alias $fname -storepass $TRUSTSTORE_PASS
			done
		else
			echo "certpath: $certpath not found"
			exit -1
		fi
	done
	export JAVA_OPTIONS="${JAVA_OPTIONS:+${JAVA_OPTIONS} } -Djavax.net.ssl.trustStore=$MERGED_TRUSTSTORE -Djavax.net.ssl.trustStorePassword=${TRUSTSTORE_PASS} -Djavax.net.ssl.trustStoreType=PKCS12"
	export JAVA_OPTS="${JAVA_OPTS:+${JAVA_OPTS} } -Djavax.net.ssl.trustStore=$MERGED_TRUSTSTORE -Djavax.net.ssl.trustStorePassword=${TRUSTSTORE_PASS} -Djavax.net.ssl.trustStoreType=PKCS12"
fi

# SETUP OF KEYSTORE
echo "KEYSTORE_FILE_PATH is : $KEYSTORE_FILE_PATH"

if [[ ! -z "$KEYSTORE_FILE_PATH" && ! -z "$KEYSTORE_PASSWORD" ]]; then
	KEYSTORE_KEY_PASSWORD=${KEYSTORE_KEY_PASSWORD:-${KEYSTORE_PASSWORD}}
	export JAVA_OPTIONS="${JAVA_OPTIONS:+${JAVA_OPTIONS} } -Djavax.net.ssl.keyStore=${KEYSTORE_FILE_PATH} -Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASSWORD} -Djavax.net.ssl.keyPassword=${KEYSTORE_KEY_PASSWORD}"
	export JAVA_OPTS="${JAVA_OPTS:+${JAVA_OPTS} } -Djavax.net.ssl.keyStore=${KEYSTORE_FILE_PATH} -Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASSWORD} -Djavax.net.ssl.keyPassword=${KEYSTORE_KEY_PASSWORD}"
fi

# Read in container limits and export the as environment variables
load_container_limits

##adding
# PRINT CONTAINER LIMIT
echo "CONTAINER_CORE_LIMIT = $CONTAINER_CORE_LIMIT"
echo "CONTAINER_MAX_MEMORY = $CONTAINER_MAX_MEMORY"

TOMCAT_SERVER_MAX_THREADS_FACTOR=${TOMCAT_SERVER_MAX_THREADS_FACTOR:-256}


if [[ "$TOMCAT_SERVER_MAX_THREADS" =~ ^[0-9]+$ ]]; then
  echo "set TOMCAT_SERVER_MAX_THREADS set in configuration"
elif [[ "$CONTAINER_CORE_LIMIT" =~ ^[0-9]+$ ]]; then
    echo "set TOMCAT_SERVER_MAX_THREADS using CONTAINER_CORE_LIMIT"
    export TOMCAT_SERVER_MAX_THREADS=$(($CONTAINER_CORE_LIMIT * $TOMCAT_SERVER_MAX_THREADS_FACTOR))
elif [[ "$JAVA_CORE_LIMIT" =~ ^[0-9]+$ ]]; then
    echo "set TOMCAT_SERVER_MAX_THREADS using JAVA_CORE_LIMIT"
    export TOMCAT_SERVER_MAX_THREADS=$(($JAVA_CORE_LIMIT * $TOMCAT_SERVER_MAX_THREADS_FACTOR))
else
    echo "set TOMCAT_SERVER_MAX_THREADS with default value"
    export TOMCAT_SERVER_MAX_THREADS=${TOMCAT_SERVER_MAX_THREADS_FACTOR}
fi

# print springboot max thread
echo "TOMCAT_SERVER_MAX_THREADS = $TOMCAT_SERVER_MAX_THREADS"

# set maximum memory ratio to 95% (5% reserved by system)
JAVA_MAX_MEM_RATIO=95
# set minimum memory ratio to 20%
JAVA_INITIAL_MEM_RATIO=20

export GC_MAX_METASPACE_SIZE=${GC_MAX_METASPACE_SIZE:-256}

# print configuration for memory
echo "GC_MAX_METASPACE_SIZE = $GC_MAX_METASPACE_SIZE"
echo "JAVA_INITIAL_MEM_RATIO = $JAVA_INITIAL_MEM_RATIO"
echo "JAVA_MAX_MEM_RATIO = $JAVA_MAX_MEM_RATIO"

# calculate maximum memory that will be used by heap memory
# xss = ThreadStackSize in bytes - generally 1024 bytes for linux x64
# to see default value: java -XX:+PrintFlagsFinal -version | grep ThreadStackSize
# max_mem = CONTAINER_MAX_MEMORY - GC_MAX_METASPACE_SIZE - (TOMCAT_SERVER_MAX_THREADS * xss)
if [[ "$CONTAINER_MAX_MEMORY" =~ ^[0-9]+$ ]]; then
	echo "values ${CONTAINER_MAX_MEMORY} ${GC_MAX_METASPACE_SIZE} ${TOMCAT_SERVER_MAX_THREADS} 1048576"
	max_mem=$(echo "${CONTAINER_MAX_MEMORY} ${GC_MAX_METASPACE_SIZE} ${TOMCAT_SERVER_MAX_THREADS} 1048576" | awk '{printf "%d\n" , ($1-($2*$4)-($3*(1024*1024)))}')
	echo "max_mem = $max_mem"
	ms=$(echo "${max_mem} ${JAVA_MAX_MEM_RATIO} ${JAVA_INITIAL_MEM_RATIO} 1048576" | awk '{printf "%d\n" , ($1*(($2*$3)/10000))/$4 + 0.5}')
	mx=$(echo "${max_mem} ${JAVA_MAX_MEM_RATIO} 1048576" | awk '{printf "%d\n" , ($1*$2)/(100*$3) + 0.5}')
	export JAVA_OPTIONS="${JAVA_OPTIONS:+${JAVA_OPTIONS} } -Xms${ms}m -Xmx${mx}m"
	export JAVA_OPTS="${JAVA_OPTS:+${JAVA_OPTS} } -Xms${ms}m -Xmx${mx}m"
fi


echo "JAVA_OPTIONS are $JAVA_OPTIONS"
echo "JAVA_OPTS are $JAVA_OPTS"
echo "JAVA_ARGS are $JAVA_ARGS"

export JAVA_OPTS="-Dorg.jbpm.var.log.length=1024 ${JAVA_OPTS}"
echo "Finally JAVA_ARGS are JAVA_OPTS"

exec /opt/run-java/run/run-java.sh $args ${JAVA_ARGS}
