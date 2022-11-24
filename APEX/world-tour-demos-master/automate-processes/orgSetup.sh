#!/bin/bash
# Set up script for Automate Processes @ WT18

git clone https://github.com/dreamhouseapp/dreamhouse-sfdx
cd dreamhouse-sfdx
sfdx force:org:create -s -f config/project-scratch-def.json -a processes-wt18
sfdx force:source:push
sfdx force:user:permset:assign -n dreamhouse
sfdx force:org:open -p /one/one.app#/n/Sample_Data_Import
