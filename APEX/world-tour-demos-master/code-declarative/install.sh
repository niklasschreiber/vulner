#!/bin/bash

ORG_ALIAS="dh"

# Install script for the LWC org
echo ""
echo "Installing org with alias: $ORG_ALIAS"
echo ""

echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u $ORG_ALIAS &> /dev/null
echo ""

echo "Cloning Dreamhouse repo..."
git clone git@github.com:dreamhouseapp/dreamhouse-lwc.git && \
cd dreamhouse-lwc && \
echo "" && \

echo "Creating scratch org..." && \
sfdx force:org:create -s -f config/project-scratch-def.json -d 30 -a $ORG_ALIAS && \
echo "" && \

echo "Pushing source..." && \
sfdx force:source:push -u $ORG_ALIAS && \
echo "" && \

echo "Assigning permissions..." && \
sfdx force:user:permset:assign -n dreamhouse -u $ORG_ALIAS && \
echo "" && \

echo "Importing sample data..." && \
sfdx force:data:tree:import -p ./data/sample-data.json -u $ORG_ALIAS && \
echo "" && \

# Deploy WT customization
cd ..
./deploy-customization.sh $ORG_ALIAS && \

# Clean temp Dreamhouse git repo
rm -fr dreamhouse-lwc && \

echo "Opening org..." && \
sfdx force:org:open -p lightning/n/Settings -u $ORG_ALIAS

EXIT_CODE="$?"

# Check exit code
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "Installation completed."
else
    echo "Installation failed."
fi
exit $EXIT_CODE
