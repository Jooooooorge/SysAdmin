#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH

# Cofiguración IP estatica
# Datos fijos
$IpAddress = "192.168.0.120"
$PrefixLenght = 24
$GateWay = "192.168.0.1"
New-NetIPAddress -IPAddress $IpAddress -PrefixLength $PrefixLenght -DefaultGateway $GateWay
Set-DnsClientDohServerAddress -InterfaceIndex 4 -ServerAddress ("8.8.8.8") 
# Para usar el cliente de ssh 
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Iniciar el servicio
Start-Service sshd

# Al estar activo el Firewall de windows, es necesario agregar la siguiente regla
New-NetFirewallRule -Name 'OpenSSH-Server' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

