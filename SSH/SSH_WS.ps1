#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH
Import-Module ..\FUNC\WS.ps1 -Force

# Cofiguración IP estatica
ConfigurarIpEstatica

# Verificar si OpenSSH está instalado
$sshFeature = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshFeature.State -ne 'Installed') {
    Write-Host "Instalando OpenSSH Server..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
} else {
    Write-Host "OpenSSH Server ya está instalado."
}

# Iniciar el servicio SSHD
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Configurar firewall para permitir SSH
if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Host "Regla de firewall agregada para permitir conexiones SSH."
} else {
    Write-Host "La regla de firewall para SSH ya existe."
}
