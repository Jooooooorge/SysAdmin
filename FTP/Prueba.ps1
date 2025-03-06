# *********************************************************************************************************
# Práctica 5
# Elaborar un servidor FTP que permita administrar usuarios y les de acceso a las
# siguientes carpetas:
#   - MiUsuario
#   - Grupo
#   - Publico

# Configuración de la IP estática
Import-Module ..\FUNC\WS.ps1 -Force

# Instalación del servicio y validación 
if (Get-WindowsFeature | Where-Object { $_.Name -like "*ftp*" -and $_.Installed }) {
    Write-Host "FTP Server está instalado."
} else {
    Write-Host "FTP Server instalándose..."
    ConfigurarIpEstatica
    Install-WindowsFeature -Name Web-FTP-Server -IncludeManagementTools -IncludeAllSubFeature

    if (Get-WindowsFeature | Where-Object { $_.Name -like "*FTP-Server*" -and $_.Installed }) {
        Write-Host "FTP Server instalado correctamente."
    }

    try {
        # Configuración del servicio web
        Import-Module WebAdministration

        # Crear el sitio FTP
        New-WebFTPSite -Name "FTPServer" -IPAddress "192.168.1.111" -Port 21 -PhysicalPath "C:\FTPServer" -Force

        # Crear la carpeta raíz del sitio
        if (!(Test-Path "C:\FTPServer")) {
            New-Item -Path "C:\FTPServer" -ItemType Directory
            New-Item -Path "C:\FTPServer\UsuariosLocales" -ItemType Directory
            New-Item -Path "C:\FTPServer\Reprobados" -ItemType Directory
            New-Item -Path "C:\FTPServer\Recursadores" -ItemType Directory
            New-Item -Path "C:\FTPServer\Publico" -ItemType Directory
        }

        # Asignar la carpeta raíz al sitio
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name PhysicalPath -Value 'C:\FTPServer'

        # Configuración del usuario anónimo
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $true
        Add-WebConfiguration "/system.ftpServer/security/authorization" -Location FTPServer -PSPath IIS:\ -Value @{accessType="Allow";users="?";permissions="Read"}
        icacls "C:\FTPServer\Publico" /grant "IUSR:(OI)(CI)(R)" /t

        # Autenticación básica
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true

        # Permitir la política SSL
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslAllow"
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslAllow"

        # Aislamiento de usuarios
        Set-ItemProperty "IIS:\Sites\FTPServer" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly"

        # Reiniciar servicio
        Restart-WebItem -PSPath 'IIS:\Sites\FTPServer'
    } catch {
        Write-Host "Ocurrió un error en la configuración del IIS: $_"
    }
}

# Menú de administración de usuarios
while ($true) {
    Write-Host "==========================="
    Write-Host "======= SERVICIO FTP ======="
    Write-Host "[1] Iniciar Sesión"
    Write-Host "[2] Agregar Usuario"
    Write-Host "[3] Editar Usuario"
    Write-Host "[4] Salir"
    $opc = Read-Host "Selecciona una opción:"

    switch ($opc) {
        1 {
            # Iniciar Sesión
            $Usuario = Read-Host "Usuario"
            $Contra = Read-Host "Contraseña" -AsSecureString
            $Contra = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Contra))

            try {
                $webclient = New-Object System.Net.WebClient
                $webclient.Credentials = New-Object System.Net.NetworkCredential($Usuario, $Contra)
                $remoteDir = "ftp://192.168.1.111/UsuariosLocales/$Usuario/"
                $files = $webclient.DownloadString($remoteDir)
                Write-Host "Inicio de sesión exitoso. Archivos en tu directorio: $files"
            } catch {
                Write-Host "Error: Credenciales incorrectas o no se pudo conectar al servidor."
            }
        }

        2 {
            # Agregar Usuario
            Write-Host "AGREGAR USUARIO"

            # Capturar Datos
            $Usuario = Read-Host "Usuario"
            $Contra = Read-Host "Contraseña" -AsSecureString
            $Grupo = Read-Host "[1] Recursadores | [2] Reprobados"

            # Asignar el grupo correspondiente
            if ($Grupo -eq 1) {
                $Grupo = "Recursadores"
            } elseif ($Grupo -eq 2) {
                $Grupo = "Reprobados"
            }

            
            # Crear el usuario
            try {
                # Crear el usuario
                New-LocalUser -Name $Usuario -Password $Contra -FullName $Usuario -ErrorAction Stop

                # Configurar que la contraseña nunca expire
                Set-LocalUser -Name $Usuario -PasswordNeverExpires $true

                # Asignar el usuario al grupo
                Add-LocalGroupMember -Group $Grupo -Member $Usuario -ErrorAction Stop

                Write-Host "Usuario $Usuario creado correctamente y asignado al grupo $Grupo."
            } catch {
                Write-Host "Error al crear el usuario: $_"
            }

            # Crear la carpeta del usuario
            if (!(Test-Path "C:\FTPServer\UsuariosLocales\$Usuario")) {
                New-Item -Path "C:\FTPServer\UsuariosLocales\$Usuario" -ItemType Directory
            }

            # Otorgar permisos
            icacls "C:\FTPServer\UsuariosLocales\$Usuario" /grant "${Usuario}:(OI)(CI)(M)" /t
            icacls "C:\FTPServer\$Grupo" /grant "${Usuario}:(OI)(CI)(M)" /t
            icacls "C:\FTPServer\Publico" /grant "${Usuario}:(OI)(CI)(M)" /t
        }

        3 {
            # Editar Usuario (Pendiente de implementación)
            Write-Host "Opción no implementada aún."
        }

        4 {
            # Salir
            Write-Host "Saliendo..."
            return
        }

        default {
            Write-Host "Opción no válida. Inténtalo de nuevo."
        }
    }
}