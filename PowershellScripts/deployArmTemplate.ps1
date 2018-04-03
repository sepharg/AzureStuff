<#
.Synopsis
   Deploys a Data Factory (V2) to Azure.
.DESCRIPTION
   This script will deploy the data factories contained in the specified ARM template using the provided parameter configuration files.
   Can be run interactively (will request for Azure login and store a token in C:\Temp\MyAzureProfile.json to avoid having to reenter credentials each time the script is run
   
   The following variables are supported:
   
   deployEnvironment : Defines the environment of deployment. When set, the script appends _{deployEnvironment} to {templateParameterFile} if it hasn't been specified. This is useful when we want have several environments (development, integration, production) and want to keep configuration separated.
   templatesDirectory : Full path to where the ARM template files are located. Defaults to path where the script is being run from
   templateFile : The ARM template file to process. Defaults to "template.json"
   templateParameterFile : Parameters replacement file to apply to {templateFile}. Defaults to "parameters.json"
   subscriptionId : Azure SubscriptionId for login purposes
   tenantId : Azure TenantId for login purposes
   resourceGroup : Azure Resource Group where the Data Factories will be deployed to
.EXAMPLE
   ./deployArmTemplate.ps1 -deployEnvironment Dev
.EXAMPLE
	./deployArmTemplate.ps1 -templateParameterFile "myTestDf_Integration.json" -templatesDirectory "C:\Development\MyDataFactories\MyTestDf"
#>

Param(
  [string]$deployEnvironment,
  [string]$resourceGroup = $(Throw "ResourceGroup name must be provided"),
  [string]$templatesDirectory = $PSScriptRoot,
  [string]$templateFile = "template.json",
  [string]$templateParameterFile = "parameters.json",
  [string]$subscriptionId = $(Throw "Azure SubscriptionId must be provided"),
  [string]$tenantId = $(Throw "Azure TenantId must be provided")
)

Write-Host "Running Deploy ARM Template script with the following variables: "
Write-Host "ResourceGroup $resourceGroup"
Write-Host "templatesDirectory $templatesDirectory"
Write-Host "templateFile $templateFile"
Write-Host "templateParameterFile $templateParameterFile"
Write-Host "subscriptionId $subscriptionId"
Write-Host "tenantId $tenantId"
Write-Host "deployEnvironment $deployEnvironment"

function Login
{
    $needLogin = $true
    Try 
    {
        $content = Get-AzureRmContext
        if ($content) 
        {
            $needLogin = ([string]::IsNullOrEmpty($content.Account))
        } 
    } 
    Catch 
    {
        if ($_ -like "*Login-AzureRmAccount to login*") 
        {
            $needLogin = $true
        } 
        else 
        {
            throw
        }
    }

    if ($needLogin)
    {
		Write-Host "Credentials haven't been provided, will try to login interactively to Azure"
	
       	# Save credentials to avoid having to input them very single time
		$azureProfilePath = "C:\Temp"
		$azureProfileFile = "$azureProfilePath\MyAzureProfile.json"
		if(!(test-path $azureProfilePath))
		{
			Write-Host "Creating $azureProfilePath directory"
			New-Item -ItemType Directory -Force -Path $azureProfilePath
		}
		if (-not (Test-Path $azureProfileFile))
		{
			Login-AzureRmAccount -SubscriptionId $subscriptionId
			Get-AzureRmSubscription -SubscriptionId $subscriptionId -TenantId $tenantId | Set-AzureRmContext
			Write-Host "Saving profile cookie to $azureProfileFile so that you don't have to login interactively every time"
			Save-AzureRmContext -Force -Path $azureProfileFile
		} 
		else
		{
			Import-AzureRmContext -Path $azureProfileFile
		}	
    }
}

# Set Environment
if (!($deployEnvironment -eq '') -and !($templateParameterFile -like "*$deployEnvironment.json*"))
{
	Write-Host "Environment detected, appending '$deployEnvironment' to parameters filename"
	$templateParameterFile = $templateParameterFile.replace(".json", "_$deployEnvironment.json");
}

Login

# Get absolute paths
$templateFile = "$templatesDirectory\$templateFile"
$templateParameterFile = "$templatesDirectory\$templateParameterFile"
 
Write-Host "Deploying to $resourceGroup with file $templateFile and configuration $templateParameterFile..."

New-AzureRmResourceGroupDeployment -Name MyARMDeployment -ResourceGroupName $resourceGroup -TemplateFile $templateFile -TemplateParameterFile $templateParameterFile

Write-Host "Deployment end"