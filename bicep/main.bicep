// Global parameters
targetScope = 'subscription'

@minLength(4)
@maxLength(30)
@description('string used for naming all resources')
param name string

@description('location for resource group and all resources')
param location string

@description('Contributor Role definition ID')
param roleId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

// Naming variables
var logAnalyticsWorkspaceName = '${name}-law'
var logicAppName = '${name}-la'
var managedIdentityName = '${name}-mi'
var resourceGroupName = '${name}-rg'

//Resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

//Authentication related resources
module managedIdentity 'managedIdentity.bicep' = {
  name: 'managedIdentityModule'
  scope: resourceGroup
  params: {
    managedIdentityName: managedIdentityName
  }
}
module roleAssignment 'role.bicep' = {
  name: 'roleAssignmentModule'
  scope: subscription()
  params: {
    principalId: managedIdentity.outputs.principalId
    roleId: roleId
  }
} 

//Logic App related resources
module apiConnection 'apiConnection.bicep' = {
  name: 'apiConnectionModule'
  scope: resourceGroup
  params: {}
}

module logicApp 'logicApp.bicep' = {
  name: 'logicAppModule'
  scope: resourceGroup
  params: {
    logicAppName:logicAppName
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    apiConnectionId: apiConnection.outputs.apiConnectionId
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
  }
}

module logAnalyticsWorkspace 'logAnalyticsWorkspace.bicep' ={
  name: 'logAnalyticsWorkspaceModule'
  scope: resourceGroup
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}
