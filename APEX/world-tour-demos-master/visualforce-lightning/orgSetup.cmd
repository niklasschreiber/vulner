git clone https://github.com/dreamhouseapp/dreamhouse-sfdx
cp DreamhouseLeads.page dreamhouse-sfdx\force-app\main\default\pages\DreamhouseLeads.page
cp DreamhouseLeads.page-meta.xml dreamhouse-sfdx\force-app\main\default\pages\DreamhouseLeads.page-meta.xml
cp DreamhouseProspects.cls dreamhouse-sfdx\force-app\main\default\classes\DreamhouseProspects.cls
cp DreamhouseProspects.cls-meta.xml dreamhouse-sfdx\force-app\main\default\classes\DreamhouseProspects.cls-meta.xml
cd dreamhouse-sfdx
sfdx force:org:create -s -f config/project-scratch-def.json -a vf2lightning-wt18
sfdx force:source:push
sfdx force:user:permset:assign -n dreamhouse
sfdx force:data:tree:import --plan ..\data\lead-plan.json
sfdx force:org:open -p /one/one.app#/n/Sample_Data_Import