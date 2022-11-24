#!/bin/bash
SRCFILE=$1
if [ ! -f "$SRCFILE" ]; then
    echo "file doesn't exist"
    exit 1
fi
WORKDIR=`mktemp -d -t customization`
tar zxvf $1 -C $WORKDIR
cp -Rvp customizations/* $WORKDIR/apache-tomcat-*
CUSTOMIZED_TAR=$PWD/customized/`basename $SRCFILE`
(cd $WORKDIR; tar zcvf $CUSTOMIZED_TAR *)
rm -rf "$WORKDIR"

