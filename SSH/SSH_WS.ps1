#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH
Import-Module ..\FUNC\WS.psm1 -Force

# Cofiguración IP estatica
ConfigurarIpEstatica

# Verificar si OpenSSH está instalado
$sshFeature = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshFeature.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue *>$null
}

# Iniciar el servicio SSHD
Start-Service sshd -ErrorAction SilentlyContinue *>$null
Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue *>$null

# Definir el nuevo puerto SSH
$nuevoPuerto = 2222

# Modificar el archivo de configuración de SSH
$sshdConfigPath = "C:\ProgramData\ssh\sshd_config"

# Asegurar que el archivo permite escritura
if ((Get-Content $sshdConfigPath) -match "^#?Port ") {
    (Get-Content $sshdConfigPath) -replace "^#?Port\s+\d+", "Port $nuevoPuerto" | Set-Content $sshdConfigPath
} else {
    Add-Content $sshdConfigPath "`nPort $nuevoPuerto"
}

# Abrir el nuevo puerto en el firewall
New-NetFirewallRule -Name "SSH-Custom-Port" -DisplayName "SSH Custom Port" -Direction Inbound -Protocol TCP -Action Allow -LocalPort $nuevoPuerto -ErrorAction SilentlyContinue *>$null

# Reiniciar el servicio SSHD para aplicar los cambios
Restart-Service sshd -Force -ErrorAction SilentlyContinue *>$null

Write-Host "SSH configurado en el puerto $nuevoPuerto y firewall actualizado"
