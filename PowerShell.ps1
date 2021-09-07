##OLIMPIADAS AZURE - TFTEC
## Conectando no Azure
Connect-AzAccount

## Definindo as variaveis de rede
$ResourceGroup  = "RG-TFTEC"
$Location       = "Westus2"
$vNetName       = "VNET-PS"
$AddressSpace   = "192.168.0.0/16"
$SubnetIPRange  = "192.168.0.0/24"
$SubnetIPRange2 = "192.168.1.0/24"
$SubnetName     = "SUB-LAN-WIN"
$SubnetName2    = "SUB-LAN-LNX"

## Criar Resource Groups
New-AzResourceGroup -Name $ResourceGroup -Location $Location

## Criar a Virtual Network
$vNetwork = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName -AddressPrefix $AddressSpace -Location $location

## Criar as Subnets
Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vNetwork -AddressPrefix $SubnetIPRange
Add-AzVirtualNetworkSubnetConfig -Name $SubnetName2 -VirtualNetwork $vNetwork -AddressPrefix $SubnetIPRange2

## Criar o Network Security Group e liberar as porta 3389 e 22 para acesso RDP e SSH
$nsgRuleVMAccessRDP = New-AzNetworkSecurityRuleConfig -Name 'ALLOW-RDP-3389' -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix $SubnetIPRange -DestinationPortRange 3389 -Access Allow
$nsgRuleVMAccessSSH = New-AzNetworkSecurityRuleConfig -Name 'ALLOW-SSH-22' -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix $SubnetIPRange2 -DestinationPortRange 22 -Access Allow
$networkSecurityGroupWIN = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $Location -Name "NSG-WIN" -SecurityRules $nsgRuleVMAccessRDP
$networkSecurityGroupLNX = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $Location -Name "NSG-LNX" -SecurityRules $nsgRuleVMAccessSSH

## Setar NSG para Subnets
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vNetwork -Name $SubnetName -AddressPrefix $SubnetIPRange -NetworkSecurityGroup $networkSecurityGroupWIN
Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vNetwork -Name $SubnetName2 -AddressPrefix $SubnetIPRange2 -NetworkSecurityGroup $networkSecurityGroupLNX
Set-AzVirtualNetwork -VirtualNetwork $vNetwork



## Definir as variaveis da maquina virtual
$vNet       = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName
$Subnet     = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vNet
$vmName     = "VM-WIN01"
$pubName    = "MicrosoftWindowsServer"
$offerName  = "WindowsServer"
$skuName    = "2019-Datacenter"
$vmSize     = "Standard_DS1_v2"
$pipName    = "$vmName-pip" 
$nicName    = "$vmName-nic"
$osDiskName = "$vmName-OsDisk"
$osDiskType = "Standard_LRS"

## Definir credinciais de admin da VM
$adminUsername = 'admin.tftec'
$adminPassword = 'Olimpiadas@12345'
$adminCreds    = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force)

## Criar IP publico e interface de rede NIC
$pip = New-AzPublicIpAddress -Name $pipName -ResourceGroupName $ResourceGroup -Location $location -AllocationMethod Static 
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroup -Location $location -SubnetId $Subnet.Id -PublicIpAddressId $pip.Id

## Adicionando as configuracoes da maquina virtual
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

## Setando os parametros do sistema operacional 
Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $adminCreds

## Setando a imagem utilizada na maquina virtual
Set-AzVMSourceImage -VM $vmConfig -PublisherName $pubName -Offer $offerName -Skus $skuName -Version 'latest'

## Setando as configuracoes de disco
Set-AzVMOSDisk -VM $vmConfig -Name $osDiskName -StorageAccountType $osDiskType -CreateOption fromImage

## Desabilitando o diagnostico de boot
Set-AzVMBootDiagnostic -VM $vmConfig -Disable

## Criando a maquina virtual
New-AzVM -ResourceGroupName $ResourceGroup -Location $location -VM $vmConfig


## VM 2
## Definir as variaveis da maquina virtual
$vNet       = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName
$SubnetLNX  = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName2 -VirtualNetwork $vNet
$vmName     = "VM-LNX01"
$pubName    = "Canonical"
$offerName  = "UbuntuServer"
$skuName    = "18.04-LTS"
$vmSize     = "Standard_DS1_v2"
$pipName    = "$vmName-pip" 
$nicName    = "$vmName-nic"
$osDiskName = "$vmName-OsDisk"
$osDiskType = "Standard_LRS"

## Definir credinciais de admin da VM LNX
$adminUsername = 'admintftec'
$adminPassword = 'Olimpiadas@12345'
$adminCreds    = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force)

## Criar IP publico e interface de rede NIC
$pip = New-AzPublicIpAddress -Name $pipName -ResourceGroupName $ResourceGroup -Location $location -AllocationMethod Static 
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroup -Location $location -SubnetId $SubnetLNX.Id -PublicIpAddressId $pip.Id

## Adicionando as configuracoes da maquina virtual
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

## Setando os parametros do sistema operacional 
Set-AzVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmName -Credential $adminCreds

## Setando a imagem utilizada na maquina virtual
Set-AzVMSourceImage -VM $vmConfig -PublisherName $pubName -Offer $offerName -Skus $skuName -Version 'latest'

## Setando as configuracoes de disco
Set-AzVMOSDisk -VM $vmConfig -Name $osDiskName -StorageAccountType $osDiskType -CreateOption fromImage

## Desabilitando o diagnostico de boot
Set-AzVMBootDiagnostic -VM $vmConfig -Disable

## Criando a maquina virtual
New-AzVM -ResourceGroupName $ResourceGroup -Location $location -VM $vmConfig





## Definir as variaveis da maquina virtual
$vNet       = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName
$Subnet     = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vNet
$vmName     = "VM-WIN02"
$pubName    = "MicrosoftWindowsServer"
$offerName  = "WindowsServer"
$skuName    = "2012-R2-Datacenter"
$vmSize     = "Standard_B2s"
$pipName    = "$vmName-pip" 
$nicName    = "$vmName-nic"
$osDiskName = "$vmName-OsDisk"
$osDiskType = "Standard_LRS"

## Definir credinciais de admin da VM
$adminUsername = 'admin.tftec'
$adminPassword = 'Olimpiadas@12345'
$adminCreds    = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force)

## Criar IP publico e interface de rede NIC
$pip = New-AzPublicIpAddress -Name $pipName -ResourceGroupName $ResourceGroup -Location $location -AllocationMethod Static 
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroup -Location $location -SubnetId $Subnet.Id -PublicIpAddressId $pip.Id

## Adicionando as configuracoes da maquina virtual
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

## Setando os parametros do sistema operacional 
Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $adminCreds

## Setando a imagem utilizada na maquina virtual
Set-AzVMSourceImage -VM $vmConfig -PublisherName $pubName -Offer $offerName -Skus $skuName -Version 'latest'

## Setando as configuracoes de disco
Set-AzVMOSDisk -VM $vmConfig -Name $osDiskName -StorageAccountType $osDiskType -CreateOption fromImage

## Desabilitando o diagnostico de boot
Set-AzVMBootDiagnostic -VM $vmConfig -Disable

## Criando a maquina virtual
New-AzVM -ResourceGroupName $ResourceGroup -Location $location -VM $vmConfig
