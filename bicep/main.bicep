// Global parameters
@minLength(4)
@maxLength(30)
@description('string used for naming all resources')
param name string

@description('New GUID used for naming role assignment')
param guidValue string = newGuid()

@description('location for all resources')
param location string = resourceGroup().location

@description('Subscription ID')
param subscriptionId string = subscription().subscriptionId

// Authorization related parameters
@description('Contributor Role definition ID')
param roleDefinitionId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

// Naming variables
var managedIdentityName = 'mi-${name}'
var logicAppName = 'la-${name}'
var logAnalyticsWorkspaceName = 'law-${name}'

//Authentication related resources
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guidValue
  properties: {
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: managedIdentity.properties.principalId
  }
} 

//Logic App related resources
resource apiConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: 'arm'
  kind: 'V1'
  location: location
  properties: {
    displayName: 'arm'
    customParameterValues: {}
    alternativeParameterValues: {}
    parameterValueType: 'Alternative'
    api: {
      name: 'arm'
      displayName: 'Azure Resource Manager'
      description: 'Azure Resource Manager exposes the APIs to manage all of your Azure resources.'
      id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/arm'
      type: 'Microsoft.Web/locations/managedApis'
    }
  }
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
     '${managedIdentity.id}' : {}
    }
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            method: 'POST'
            schema: {
              properties: {
                hybrid: {
                  type: 'boolean'
                }
                location: {
                  type: 'string'
                }
                requestId: {
                  type: 'string'
                }
                resourceGroup: {
                  type: 'string'
                }
                subnet1Name: {
                  type: 'string'
                }
                subnet1Prefix: {
                  type: 'string'
                }
                subnet2Name: {
                  type: 'string'
                }
                subnet2Prefix: {
                  type: 'string'
                }
                subscriptionId: {
                  type: 'string'
                }
                vnetAddressPrefix: {
                  type: 'string'
                }
                vnetName: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
        }
      }
      actions: {
        Condition: {
          actions: {
            Compose_hybrid: {
              runAfter: {}
              type: 'Compose'
              inputs: {
                subnet1Name: {
                  value: '@triggerBody()?[\'subnet1Name\']'
                }
                subnet1Prefix: {
                  value: '@triggerBody()?[\'subnet1Prefix\']'
                }
                subnet2Name: {
                  value: '@triggerBody()?[\'subnet2Name\']'
                }
                subnet2Prefix: {
                  value: '@triggerBody()?[\'subnet2Prefix\']'
                }
                vnetAddressPrefix: {
                  value: '@triggerBody()?[\'vnetAddressPrefix\']'
                }
                vnetName: {
                  value: '@triggerBody()?[\'vnetName\']'
                }
              }
            }
            Create_or_update_a_template_deployment_hybrid: {
              runAfter: {
                Compose_hybrid: [
                  'Succeeded'
                ]
              }
              type: 'ApiConnection'
              inputs: {
                body: {
                  properties: {
                    mode: 'Incremental'
                    parameters: '@outputs(\'Compose_hybrid\')'
                    templateLink: {
                      uri: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.network/vnet-two-subnets/azuredeploy.json'
                    }
                  }
                }
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'arm\'][\'connectionId\']'
                  }
                }
                method: 'put'
                path: '/subscriptions/@{encodeURIComponent(triggerBody()?[\'subscriptionId\'])}/resourceGroups/@{encodeURIComponent(triggerBody()?[\'resourceGroup\'])}/providers/Microsoft.Resources/deployments/@{encodeURIComponent(triggerBody()?[\'requestId\'])}'

                queries: {
                  wait: true
                  'x-ms-api-version': '2016-06-01'
                }
              }
            }
            Response_hybrid: {
              runAfter: {
                Create_or_update_a_template_deployment_hybrid: [
                  'Succeeded'
                ]
              }
              type: 'Response'
              kind: 'Http'
              inputs: {
                body: {
                  deploymentId: '@body(\'Create_or_update_a_template_deployment_hybrid\')?[\'id\']'
                  resourceGroupId: '@body(\'Create_or_update_a_resource_group\')?[\'id\']'
                  status: '@body(\'Create_or_update_a_template_deployment_hybrid\')?[\'properties\']?[\'provisioningState\']'
                }
                headers: {
                  'Content-Type': 'application/json'
                }
                statusCode: 200
              }
            }
          }
          runAfter: {
            Create_or_update_a_resource_group: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Compose_native: {
                runAfter: {}
                type: 'Compose'
                inputs: {
                  subnet1Name: {
                    value: '@triggerBody()?[\'subnet1Name\']'
                  }
                  subnet2Name: {
                    value: '@triggerBody()?[\'subnet2Name\']'
                  }
                  vnetName: {
                    value: '@triggerBody()?[\'vnetName\']'
                  }
                }
              }
              Create_or_update_a_template_deployment_native: {
                runAfter: {
                  Compose_native: [
                    'Succeeded'
                  ]
                }
                type: 'ApiConnection'
                inputs: {
                  body: {
                    properties: {
                      mode: 'Incremental'
                      parameters: '@outputs(\'Compose_native\')'
                      templateLink: {
                        uri: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.network/vnet-two-subnets/azuredeploy.json'
                      }
                    }
                  }
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'arm\'][\'connectionId\']'
                    }
                  }
                  method: 'put'
                  path: '/subscriptions/@{encodeURIComponent(triggerBody()?[\'subscriptionId\'])}/resourceGroups/@{encodeURIComponent(triggerBody()?[\'resourceGroup\'])}/providers/Microsoft.Resources/deployments/@{encodeURIComponent(triggerBody()?[\'requestId\'])}'
                  queries: {
                    wait: true
                    'x-ms-api-version': '2016-06-01'
                  }
                }
              }
              Response_native: {
                runAfter: {
                  Create_or_update_a_template_deployment_native: [
                    'Succeeded'
                  ]
                }
                type: 'Response'
                kind: 'Http'
                inputs: {
                  body: {
                    deploymentId: '@body(\'Create_or_update_a_template_deployment_native\')?[\'id\']'
                    resourceGroupId: '@body(\'Create_or_update_a_resource_group\')?[\'id\']'
                    status: '@body(\'Create_or_update_a_template_deployment_native\')?[\'properties\']?[\'provisioningState\']'
                  }
                  headers: {
                    'Content-Type': 'application/json'
                  }
                  statusCode: 200
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@triggerBody()?[\'hybrid\']'
                  '@true'
                ]
              }
            ]
          }
          type: 'If'
        }
        Create_or_update_a_resource_group: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: {
              location: '@triggerBody()?[\'location\']'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'arm\'][\'connectionId\']'
              }
            }
            method: 'put'
            path: '/subscriptions/@{encodeURIComponent(triggerBody()?[\'subscriptionId\'])}/resourcegroups/@{encodeURIComponent(triggerBody()?[\'resourceGroup\'])}'
            queries: {
              'x-ms-api-version': '2016-06-01'
            }
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          arm: {
            connectionId: apiConnection.id
            connectionName: 'arm'
            connectionProperties: {
              authentication: {
                identity: managedIdentity.id
                type: 'ManagedServiceIdentity'
              }
            }
            id: '/subscriptions/${subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/arm'
          }
        }
      }
    }

  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagSettings'
  scope: logicApp
  properties: {
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' ={
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}
