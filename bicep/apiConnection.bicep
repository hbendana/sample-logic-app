resource apiConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'arm'
  kind: 'V1'
  location: resourceGroup().location
  properties: {
    displayName: 'arm'
    customParameterValues: {}
    alternativeParameterValues: {}
    parameterValueType: 'Alternative'
    api: {
      name: 'arm'
      displayName: 'Azure Resource Manager'
      description: 'Azure Resource Manager exposes the APIs to manage all of your Azure resources.'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${resourceGroup().location}/managedApis/arm'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

output apiConnectionId string = apiConnection.id
