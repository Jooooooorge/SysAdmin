#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH
Import-Module ..\FUNC\WS.ps1 -Force
# Cofiguración IP estatica
ConfigurarIpEstatica

# Para usar el cliente de ssh
if(Get-Service -Name SSHD -ne $null) 
{
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

}
# Iniciar el servicio
Start-Service sshd

# Al estar activo el Firewall de windows, es necesario agregar la siguiente regla
New-NetFirewallRule -Name 'OpenSSH-Server' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

