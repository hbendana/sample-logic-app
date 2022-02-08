targetScope = 'subscription'

param principalId string
param roleId string
param roleNameGuid string = newGuid()

var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleNameGuid
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionId
    principalId: principalId
  }
} 
