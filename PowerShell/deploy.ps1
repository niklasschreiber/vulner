set-executionpolicy unrestricted

Import-Module WebAdministration
$iisAppPoolName = "ControlloDispaccioDSPWs"
$iisAppPoolDotNetVersion = "v4.0"
$iisAppName = "ControlloDispaccioDSPWs"
$eventLogSourceName = "ControlloDispaccioDSPWs"

$iisDefaultSite = "Default Web Site"
$directoryPath = "C:\STAR\ControlloDispaccioDSPWs"
$deploySourceFolderName = "deploy"
#For older powershell prior v3.0
$scriptPath = split-path -parent $MyInvocation.MyCommand.Path

if( -Not (Test-Path -Path $directoryPath ) )
{
    Write-Host "Directory $directoryPath  not exist...creating" -ForegroundColor Yellow
    New-Item -ItemType directory -Path $directoryPath
} else {
    Write-Host "Directory $directoryPath  already exist" -ForegroundColor Yellow
	Write-Host "Deleting old files..." -ForegroundColor Yellow
	Remove-Item -Path $directoryPath\* -recurse -Force
}

Write-Host "Coping new files..." -ForegroundColor Yellow
#Copy-Item -Path $PSScriptRoot\$deploySourceFolderName\* -Destination $directoryPath -recurse -Force
Copy-Item -Path $scriptPath\$deploySourceFolderName\* -Destination $directoryPath -recurse -Force

#navigate to the app pools root
cd IIS:\AppPools\

#check if the app pool exists
if (!(Test-Path $iisAppPoolName -pathType container))
{
    Write-Host "Application pool $iisAppPoolName  not exist...creating" -ForegroundColor Yellow
    #create the app pool
    $appPool = New-Item $iisAppPoolName
    $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
} else {
    Write-Host "Application pool $iisAppPoolName  alreading exist" -ForegroundColor Yellow
}

#navigate to the sites root
cd IIS:\Sites\

#check if the site exists

if (-Not (Test-Path ("IIS:\Sites\$iisDefaultSite\$iisAppName")))
{
    Write-Host "Web App $iisAppName  not exist...creating" -ForegroundColor Yellow
    New-WebApplication -Name $iisAppName -Site $iisDefaultSite -PhysicalPath $directoryPath -ApplicationPool $iisAppPoolName
} else {
    Write-Host "Web App $iisAppName  already exists" -ForegroundColor Yellow
}

$logFileExists = Get-EventLog -list | Where-Object {$_.logdisplayname -eq $eventLogSourceName} 
if (! $logFileExists) {
    Write-Host "Creating event log source $eventLogSourceName" -ForegroundColor Yellow
    New-EventLog -Source $eventLogSourceName -LogName $eventLogSourceName
} else {
    Write-Host "Event log source $eventLogSourceName already exist" -ForegroundColor Yellow
}

