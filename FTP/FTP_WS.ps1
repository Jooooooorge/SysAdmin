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
    
        New-WebFTPSite -Name "FTPServer" -IPAddress "192.168.1.111" -Port 21 -Force
    
        # Crear la carpete raíz del sitio:
        if (!(Test-Path "C:\FTPServer"))
        {
            mkdir "c:\FTPServer\"
            mkdir "c:\FTPServer\UsuariosLocales"

            New-LocalGroup -Name Reprobados
            mkdir "c:\FTPServer\Reprobados"
            
            New-LocalGroup -Name Recursadores
            mkdir "c:\FTPServer\Recursadores"

            mkdir "C:\FTPServer\Publico"
        }
    
        # Asignar la carpeta raíz al sitio
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name PhysicalPath -value 'c:\FTPServer'
    
        # Crear la configuración del usuario anonimo
        # Activar la autenticacíon anonima ** Cambiar el nombre
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $true
        Add-WebConfiguration "/system.ftpServer/security/authorization" -Location FTPServer -PSPath IIS:\ -Value @{accessType="Allow";users="?";permissions="Read"}
        icacls "C:\FTPServer\Publico" /grant "IUSR:(OI)(CI)(R)" /t
       
        # Autencitación básica
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true

        # Permitir la politica SSL
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslAllow"
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslAllow"
    
        # Aislamiento de usuarios
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly"
        
        # Reinciar servicio
        Restart-WebItem -PSPath 'IIS:\Sites\FTPServer'    
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
            # Capturar Datos
            $Usuario = Read-Host "Usuario"
            $Contra = Read-Host "Contraseña" -AsSecureString
            $Grupo = Read-Host "[1] Recursadores | [2] Reprobados"
            $Contra = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Contra))             # Intentar conectar al servidor FTP
            try {
                $webclient = New-Object System.Net.WebClient
                $webclient.Credentials = New-Object System.Net.NetworkCredential($Usuario, $Contra)
                $remoteDir = "ftp://192.168.1.111/UsuariosLocales/$username/"
                $files = $webclient.DownloadString($remoteDir)
                Write-Host "Inicio de sesión exitoso. Archivos en tu directorio: $files"
            } catch {
                Write-Host "Error: Credenciales incorrectas o no se pudo conectar al servidor."
            }
        }

        2
        { 
            # Agregar Usuario
            Write-Host "AGREGAR USUARIO"

            # Capturar Datos
            $Usuario = Read-Host "Usuario"
            $Contra = Read-Host "Contraseña" -AsSecureString
            $Grupo = Read-Host "[1] Recursadores | [2] Reprobados"
            $Contra = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Contra)) 
            If($Grupo -eq 1)
            {
                $Grupo = "Recursadores"
            } elseif ($Grupo -eq 2)
            {
                $Grupo = "Reprobados"
            }
            New-LocalUser -Name $Usuario -Password $Contra -Force
            Add-LocalGroupMember -Group $Grupo -Member $Usuario -Verbose

            # Crear la carpete del usuario:
            if (!(Test-Path "C:\FTPServer\\UsuariosLocales\$Usuario"))
            {
                mkdir "c:\FTPServer\UsuariosLocales\$Usuario"                
            }

            # Permitir Acceso al servidor FTP
            Add-WebConfiguration "/system.ftpServer/security/authorization" -Location "FTPServer" -Value @{accessType="Allow";users=$Usuario;permissions="Read,Write"}


            # Otorgar permisos
            icacls "c:\FTPServer\UsuariosLocales\$Usuario" /grant "$Usuario :(OI)(CI)(M)" /t
            icacls "c:\FTPServer\$Grupo" /grant "$Usuario :(OI)(CI)(M)" /t
            icacls "c:\FTPServer\Publico" /grant "$Usuario :(OI)(CI)(M)" /t

            # Reinciar servicios
            Restart-WebItem -PSPath 'IIS:\Sites\FTPServer'
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




