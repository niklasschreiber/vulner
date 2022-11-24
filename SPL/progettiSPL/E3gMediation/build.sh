#!/bin/bash

MEDIATION=e3g
TOOLKITS=/export/home/streamsadmin/workspace/dev/toolkits
FRAMEWORKS=/export/home/streamsadmin/workspace/dev/frameworks
MAIN=com.ti.oss.pm.mediation.ericsson.e3g::E3gMain
OUTPUTDIR=output/com.ti.oss.pm.mediation.ericsson.e3g.E3gMain/Distributed

spl-make-toolkit -i .

sc -M $MAIN --output-directory=$OUTPUTDIR --data-directory=data -a -t $FRAMEWORKS/MediationFramework:$FRAMEWORKS/PMMessagingFramework:$FRAMEWORKS/PMMediationFramework:$FRAMEWORKS/PMKPIFramework:$TOOLKITS/ZkTCP:$TOOLKITS/CdrMediationUtils:$TOOLKITS/MediationUtils:$TOOLKITS/com.ibm.streamsx.file:$TOOLKITS/com.ibm.streamsx.hdfs:$TOOLKITS/com.ibm.streamsx.messaging:$TOOLKITS/RDirScan -- mediationId=$MEDIATION appId=e3g threadedPorts=100000 exporterThread1000=1000 enricherThread100000=100000

