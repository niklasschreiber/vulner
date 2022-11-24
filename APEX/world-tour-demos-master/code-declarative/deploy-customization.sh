#!/bin/bash


# Set parameters
PROD_ORG_ALIAS="dh"
if [ "$#" -eq 1 ]; then
  PROD_ORG_ALIAS="$1"
fi


echo ""
echo "Deploying customization to org alias:      $PROD_ORG_ALIAS"
echo ""

# Install script
sfdx force:source:convert -d mdapiout && /
sfdx force:mdapi:deploy -d mdapiout --wait 100 -u $PROD_ORG_ALIAS
EXIT_CODE="$?"
rm -rf mdapiout

# Check exit code
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Deployment completed."
else
    echo "Deployment failed."
fi
exit $EXIT_CODE
