# *********************************************************************************************************
# Práctica 5
# Elaborar un servidor FTP que permita administrar usuarios y les de acceso a las
# siguientes carpetas
# Usuario 
#   -MiUsuario
#   -Grupo
#   -Publico

# Configuración de la ip estática
Import-Module ..\FUNC\WS.ps1 -Force



# Instalación del servicio y validación 
if (Get-WindowsFeature | Where-Object { $_.Name -like "*ftp*" -and $_.Installed })
{
    Write-Host "FTP Server está instalado."
} else {
    Write-Host "FTP Server instalandose..."
    ConfigurarIpEstatica
    install-windowsfeature web-ftp-server -includemanagementtools -includeallsubfeature 
    if (Get-WindowsFeature | Where-Object { $_.Name -like "*FTP-Server*" -and $_.Installed }) 
    {
        Write-Host "FTP Server instalado correctamente"
    }
    try {
        #Configuración del servicio web
        Import-Module WebAdministration
    
        New-WebFTPSite -Name "FTPServer" -IPAddress "*" -Port 21 -Force
    
        # Crear la carpete raíz del sitio:
        if (!(Test-Path "C:\FTPServer"))
        {
            mkdir "c:\FTPServer\"

            New-LocalGroup -Name Reprobados
            mkdir "c:\FTPServer\Reprobados"
            
            New-LocalGroup -Name Recursadores
            mkdir "c:\FTPServer\Recursadores"

        }
    
        # Asignar la carpeta raíz al sitio
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name PhysicalPath -value 'c:\FTPServer'
    
        # Crear la configuración del usuario anonimo
        # Activar la autenticacíon anonima ** Cambiar el nombre
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $true
        Add-WebConfiguration "/system.ftpServer/security/authorization" -Location FTPServer -PSPath IIS:\ -Value @{accessType="Allow";users="?";permissions="Read"}
        mkdir C:\inetpub\ftproot\FTPAislado\LocalUser\Public
        icacls "C:\inetpub\ftproot\FTPAislado\LocalUser\Public" /grant "IUSR:(OI)(CI)(F)" /t
       
        # Autencitación básica
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true

        # Permitir la politica SSL
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslAllow"
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslAllow"
    
        # Aislamiento de usuarios
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly"
        
        # Reinciar servicio
        Restart-WebItem -PSPath 'IIS:\Sites\FTPAislado'    
    }
    catch {
        Write-Host "Ocurrió un error en la configuración del IIS"
    }
}
# Usuarios
# ---------------------------------------------------------------------
while ($true)
{
    Write-Host "==========================="
    Write-Host "=======SERVICIO FTP========"
    Write-Host "[1] Iniciar Sesión"
    Write-Host "[2] Agregar Usuario"
    Write-host "[3] Editar Usuario"
    Write-Host "[4] Salir"
    $opc = Read-Host "Selecciona una opción:"

    switch ($opc)
    {
        1
        { 
            # Iniciar Sesion
            Write-Host "Iniciar Sesión"
            $Usuario = Read-Host "Usuario:"
            $Contra = Read-Host -AsSecureString "Contraseña:"
        }

        2
        { 
            # Agregar Usuario
            Write-Host "AGREGAR USUARIO"

            # Capturar Datos
            $Usuario = Read-Host "Usuario:"
            $Contra = Read-Host "Contraseña:"
            $Grupo = Read-Host "[1] Recursadores | [2] Reprobados:"
            New-LocalUser -Name $Usuario -Password $Contra
            Add-LocalGroupMember -GroupName $Grupo -Name $Usuario -Verbose

            # Crear la carpete del usuario:
            if (!(Test-Path "C:\FTPServer\$Usuario"))
            {
                mkdir "c:\FTPServer\$Usuario"
                icacls "c:\FTPServer\$Usuario" /grant "A"
            }
            
            # Reinciar servicios
            Restart-WebItem -PSPath 'IIS:\Sites\FTPAislado'
        }
        3{ }
        4{ Return }
        
        default{}
    }
}

# Crear una función que cree el usuario o valide que existe
# Capturar datos
# IF (Usuario.exist)
#   Return $true
# Crearlo


#Crear las reglas de permisos para los usuarios
Add-WebConfiguration "/system.ftpServer/security/authorization" -Location FTPServer 
-PSPath IIS:\ -Value @{accessType="Allow";roles="Cuenta local";permissions="Read,Write"}


