<#
.Synopsis
   Deploys all Data Factories (v2) contained inside a root to Azure.
.DESCRIPTION
   This script will deploy all data factories that comply with the following convention:
   
    <{datafactoriesRoot}> --> <dir1> --> * template.json
                                         * params_<{deployEnvironment}>.json
                          --> <dir2> --> * template.json
                                         * params_<{deployEnvironment}>.json
                          --> <dir3> --> * template.json
                                         * params_<{deployEnvironment}>.json							 
							   
   For each directory found inside the root, calls deployArmTemplate.ps1
   
   The following variables are supported:
   
   deployEnvironment : Required. Defines the environment of deployment.
   resourceGroup : Azure Resource Group where the Data Factories will be deployed to
   datafactoriesRoot: Defines the root folder where the data factories subfolders are located. Defaults to path where the script is being run from
   deployArmTemplateScriptPath: Required. The path where deployArmTemplate.ps1 is located.
   
.EXAMPLE
   ./deployAllDataFactories.ps1 -deployEnvironment Int -datafactoriesRoot . -deployArmTemplateScriptPath .
.EXAMPLE
	./deployAllDataFactories.ps1 -deployEnvironment Dev -deployArmTemplateScriptPath "C:\Development\AzureStuff\PowershellScripts" -datafactoriesRoot "C:\Development\MyDataFactories"
#>

Param(
  [string]$deployEnvironment = $(Throw "Deployment environment wasn't provided"),
  [string]$resourceGroup = $(Throw "ResourceGroup name must be provided"),
  [string]$datafactoriesRoot = $PSScriptRoot,
  [string]$deployArmTemplateScriptPath = $(Throw "Deploy ARM template script path wasn't provided")
)

Write-Host "Running Deploy All Data Factories script with the following variables: "
Write-Host "deployEnvironment $deployEnvironment"
Write-Host "resourceGroup $resourceGroup"
Write-Host "datafactoriesRoot $datafactoriesRoot"
Write-Host "deployArmTemplateScriptPath $deployArmTemplateScriptPath"

$dir = dir $datafactoriesRoot | ?{$_.PSISContainer}

foreach ($d in $dir)
{
    $path = $d.FullName
	. $deployArmTemplateScriptPath\deployArmTemplate.ps1 -deployEnvironment $deployEnvironment -templatesDirectory $path	
}