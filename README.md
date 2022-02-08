# sample-logic-app
## Prerequisites
To successfully deploy this project, it requires the Azure user have the following:

- An Azure Subscription
- Azure RBAC Role at the Subscription scope of:
    - Owner
    - Contributor + User Access Aministrator
- Azure CLI version 2.20.0 or later installed OR Azure PowerShell version 5.6.0 or later installed
- Azure Bicep CLI installed

## Deploying Sample Solution
### Steps to deploy infrastructure:
The infrastructure for this solution is defined in an Azure Bicep file. The deployment can be performed via your local machine (assuming you meet the prerequisites regarding the installation of Azure CLI or Azure Powershell and Azure Bicep CLI). 

You'll need to either:
- populate the required parameters file `main.parameters.json` found inside the `\bicep` directory
- pass the parameters inline at time of deployment
- or allow the Bicep CLI to prompt you for the required parameters at time of deployment

First things first, you'll need to create a Resource Group to house your infrastructure:

    // via Azure CLI
    az group create --name MyResourceGroup --location westus2

    //via Azure PowerShell
    New-AzResourceGroup -Name MyResourceGroup -Location westus2

Now you can deploy your Bicep file to the recently created Resource Group. Here is an example of how to do so referencing the local parameter file:
    // via Azure CLI
    az deployment group create \
        --name MyBicepDeployment \
        --resource-group MyResourceGroup
        --template-file .\bicep\main.bicep \
        --parameters .\main.parameters.json
    
    // via Azure PowerShell
    New-AzResourceGroupDeployment `
        -Name MyBicepDeployment `
        -ResourceGroupName MyResourceGroup `
        -TemplateFile .\bicep\main.bicep`
        -TemplateParameterFile .\bicep\main.parameters.json 
