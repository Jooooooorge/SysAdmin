# *********************************************************************************************************
# Práctica 5
# Elaborar un servidor FTP que permita administrar usuarios y les de acceso a las
# siguientes carpetas
# Usuario 
#   -MiUsuario
#   -Grupo
#   -Publico

# Instalación del servicio y validación 
if (Get-WindowsFeature | Where-Object { $_.Name -like "*ftp*" -and $_.Installed })
{
    Write-Host "FTP Server está instalado."
} else {
    Write-Host "FTP Server instalandose..."
    install-windowsfeature web-ftp-server -includemanagementtools -includeallsubfeature 
    if (Get-WindowsFeature | Where-Object { $_.Name -like "*FTP-Server*" -and $_.Installed }) 
    {
        Write-Host "FTP Server instalado correctamente"
    }
}

Import-Module WebAdministration

#Configuración del servicio
New-WebFTPSite -Name "FTPServer" -IPAddress "*" -Port 21

# Crear la carpete raíz del sitio:
if (!(Test-Path "C:\FTPServer"))
{
    mkdir "c:\FTP\"
}

# Asignar la carpeta raíz al sitio
Set-ItemProperty "IIS:\Sites\FTPServer" -Name PhysicalPath -value 'c:\FTPServer'


# Usuarios
# ---------------------------------------------------------------------
# Activar la autenticacíon anonima ** Cambiar el nombre
Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $true
Add-WebConfiguration "/system.ftpServer/security/authorization" -Location FTPServer -PSPath IIS:\ -Value @{accessType="Allow";users="?";permissions="Read"}

#Crear las reglas de permisos para los usuarios
Add-WebConfiguration "/system.ftpServer/security/authorization" -Location FTPServer 
-PSPath IIS:\ -Value @{accessType="Allow";roles="Cuenta local";permissions="Read,Write"}


