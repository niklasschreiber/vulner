git clone https://github.com/dreamforce17/purealoe
cd purealoe
sfdx force:org:create -s -f config/project-scratch-def.json -a introLC-wt17
sfdx force:source:push
sfdx force:user:permset:assign -n purealoe
sfdx force:data:tree:import --plan ./data/Harvest_Field__c-plan.json
sfdx force:data:tree:import --plan ./data/Merchandise__c-plan.json 
sfdx force:org:open -p /one/one.app#/n/Field_Management