#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH
Import-Module ..\FUNC\WS.psm1 -Force

# Cofiguración IP estatica
ConfigurarIpEstatica

# Verificar si OpenSSH está instalado
$sshFeature = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshFeature.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue
}

# Iniciar el servicio SSHD
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue

# Configurar firewall para permitir SSH
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}
Write-Host "SSH Instalado y configurado correctamente"

