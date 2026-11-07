param location string = resourceGroup().location
param vnetName string = 'vnet-landing'
param vnetAddressPrefix string = '10.0.0.0/16'
param subnetName string = 'default'
param subnetPrefix string = '10.0.1.0/24'
param gatewaySubnetPrefix string = '10.0.255.0/27'

param publicIpName string = 'pip-vpngw'
param vpnGatewayName string = 'vpngw-azure'

param localGatewayName string = 'lng-onprem'
param localGatewayIpAddress string = '192.168.1.1/24' // Replace with your on-prem static public IP
param localAddressPrefixes array = ['192.168.1.0/24'] // Replace with your on-prem subnets

param connectionName string = 'conn-azure-to-onprem'
// Replace this for your auth if using Entra ID
param sharedKey string = 'SAS-based authentication'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]
  }
}
// #TODO param for static and dynamic IP
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = {
  name: vpnGatewayName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'vpngw-ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'GatewaySubnet')
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    enableBgp: false
  }
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2024-05-01' = {
  name: localGatewayName
  location: location
  properties: {
    gatewayIpAddress: localGatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: localAddressPrefixes
    }
  }
}

resource connection 'Microsoft.Network/connections@2024-05-01' = {
  name: connectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: vpnGateway.id
      properties: {}
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties: {}
    }
    connectionType: 'IPsec'
    sharedKey: sharedKey
  }
}
