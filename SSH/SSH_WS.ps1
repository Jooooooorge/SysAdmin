#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH
Import-Module .\WS.ps1 -Force
# Cofiguración IP estatica
StaticIpConfig
# Para usar el cliente de ssh 
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Iniciar el servicio
Start-Service sshd

# Al estar activo el Firewall de windows, es necesario agregar la siguiente regla
New-NetFirewallRule -Name 'OpenSSH-Server' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

