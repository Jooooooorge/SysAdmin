#************************************************************************************************
# Script para la automatizar la creación de un servidor DNS en PowerShell
Import-Module .\WS.ps1 -Force
# Cofiguración IP estatica
StaticIpConfig


# Solicitar al usuario el dominio y la IP
$dominio = Read-Host "Ingrese el nombre del dominio (Ejemplo: misitio.com)"
$ip = Read-Host "Ingrese la dirección IP del Dominio (Server: 192.168.0.199)"

# Instalar el rol de servidor DNS si no está instalado
Install-WindowsFeature -Name DNS -IncludeManagementTools -Restart

# Configurar el servidor DNS para resolver peticiones
# Crear una zona DNS para el dominio ingresado
Add-DnsServerPrimaryZone -Name $dominio -ZoneFile "$dominio.dns" -DynamicUpdate "NonSecureAndSecure"

# Crear el registro A para el dominio ingresado y asignar la IP proporcionada
Add-DnsServerResourceRecordA -ZoneName $dominio -Name "@" -AllowUpdateAny -IPv4Address $ip
Add-DnsServerResourceRecordA -Name "www" -ZoneName "$dominio" -AllowUpdateAny -IPv4Address "$ip"

# Crear la zona inversa para buscar por IP
$ipSeg = $ip.Split('.')
$ipInversa = "$($ipSeg[2]).$($ipSeg[1]).$($ipSeg[0]).in-addr.arpa"
Add-DnsServerPrimaryZone -Name $ipInversa -ZoneFile "$ipInversa.dns" -DynamicUpdate "NonSecureAndSecure"
Add-DnsServerResourceRecordPtr -Name "$($ipSeg[3])" -ZoneName "$ipInversa" -PtrDomainName "$dominio"

# Configurar firewall para permitir ICMP
New-NetFirewallRule -DisplayName "Ping" -Direction Inbound -Protocol ICMPv4 -Action Allow

# Reinicio de servidor
Restart-Service DNS
    
# Configurar el servidor DNS para responder a consultas (forwarders)
Write-Host "El servidor fue configurado correctamente!!"