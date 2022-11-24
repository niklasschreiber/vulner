#!/bin/bash

# Set parameters
PROD_ORG_ALIAS="wt-api-prod"

echo ""
echo "Deploying content to production:"
echo "- Prod org alias:      $PROD_ORG_ALIAS"
echo ""

# Install script
sfdx force:source:convert -d mdapiout && /
sfdx force:mdapi:deploy -d mdapiout --wait 100 -u $PROD_ORG_ALIAS
EXIT_CODE="$?"
rm -rf mdapiout

# Check exit code
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Production deployment completed."
else
    echo "Production deployment failed."
fi
exit $EXIT_CODE
