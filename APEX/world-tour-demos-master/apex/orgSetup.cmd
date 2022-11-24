cd apexDemo
sfdx force:org:create -s -f config/project-scratch-def.json -a apexDemo-wt18
sfdx force:source:push
sfdx force:user:permset:assign -n apexDemoPerms
sfdx force:data:tree:import --plan ..\data\Line_Item__c-plan.json
