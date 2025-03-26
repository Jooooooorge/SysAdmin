# Definición de variables
$CONFIG_FILE = "C:\Windows\System32\inetsrv\config\applicationHost.config"
$GROUP1 = "reprobados"
$GROUP2 = "recursadores"
$SHARED_GROUP = "ftp_compartida"
$GROUP1_DIR = "C:\FTP\reprobados"
$GROUP2_DIR = "C:\FTP\recursadores"
$SHARED_DIR = "C:\FTP\ftp_compartida"
$FTP_SITE_NAME = "FTP"

# Verificar si IIS y FTP están instalados
$iisInstalled = Get-WindowsFeature Web-Server -ErrorAction SilentlyContinue
$ftpInstalled = Get-WindowsFeature Web-Ftp-Server -ErrorAction SilentlyContinue
if (-not $iisInstalled.Installed -or -not $ftpInstalled.Installed) {
    Write-Host "Instalando IIS y FTP Server..." -ForegroundColor Yellow
    try {
        Install-WindowsFeature -Name Web-Server, Web-Ftp-Server -IncludeManagementTools
    }
    catch {
        Write-Host "Error: No se pudo instalar IIS y FTP Server. $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
# Importar módulos necesarios
Import-Module WebAdministration -ErrorAction SilentlyContinue
if (-not (Get-Module WebAdministration)) {
    Write-Host "Error: No se pudo cargar el módulo WebAdministration. Asegúrate de que IIS esté instalado." -ForegroundColor Red
exit 1
}
# Crear grupos si no existen
foreach ($group in @($GROUP1, $GROUP2, $SHARED_GROUP)) {
    if (-not (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue)) {
        Write-Host "Creando grupo $group..." -ForegroundColor Yellow
        New-LocalGroup -Name $group -Description "Grupo FTP para $group"
    }
}
# Crear directorios si no existen
foreach ($dir in @($GROUP1_DIR, $GROUP2_DIR, $SHARED_DIR)) {
    if (-not (Test-Path $dir)) {
        Write-Host "Creando directorio $dir..." -ForegroundColor Yellow
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}
# Establecer permisos de directorios
function Set-DirectoryPermissions {
    # Permisos para el directorio de reprobados
    write-host "Grupos: $GROUP1, $GROUP2, $GROUP1_DIR, $GROUP2_DIR, $SHARED_GROUP"

    $acl = Get-Acl -Path $GROUP1_DIR
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administradores", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($GROUP1, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl -Path $GROUP1_DIR -AclObject $acl

    # Permisos para el directorio de recursadores
    $acl = Get-Acl -Path $GROUP2_DIR
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administradores", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($GROUP2, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl -Path $GROUP2_DIR -AclObject $acl

    # Permisos para el directorio compartido
    $acl = Get-Acl -Path $SHARED_DIR
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\Administradores", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($SHARED_GROUP, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($GROUP1, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($GROUP2, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")

    $acl.AddAccessRule($rule)
    Set-Acl -Path $SHARED_DIR -AclObject $acl
}
# Configurar FTP Server
function Configure-FTPServer {
    # Verificar si el sitio FTP ya existe
    if (-not (Get-WebSite -Name $FTP_SITE_NAME -ErrorAction SilentlyContinue)) {
    Write-Host "Creando sitio FTP..." -ForegroundColor Yellow
    # Crear el sitio FTP
    New-WebFtpSite -Name $FTP_SITE_NAME -Port 21 -PhysicalPath "C:\FTP" -Force
    # Configurar autenticación básica
    Set-ItemProperty "IIS:\Sites\$FTP_SITE_NAME" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true
    # Deshabilitar autenticación anónima
    Set-ItemProperty "IIS:\Sites\$FTP_SITE_NAME" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $false
    # Configurar aislamiento de usuario
    Set-ItemProperty "IIS:\Sites\$FTP_SITE_NAME" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly"
    # Configurar autorización
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow"; users="*"; permissions=1} -PSPath IIS:\ -Location $FTP_SITE_NAME
    
    # Configurar SSL
    $certPath = "C:\Certificates"
    if (-not (Test-Path $certPath)) {
    New-Item -Path $certPath -ItemType Directory -Force | Out-Null
    }
    # ----------------------------------------------
    # Generar certificado autofirmado si no existe
    $certName = "FTPCertificate"
    $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*$certName*" }
    if (-not $cert) {
        Write-Host "Generando certificado SSL..." -ForegroundColor Yellow
        $cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation "Cert:\LocalMachine\My" -FriendlyName $certName
    }

    # Configurar SSL en el sitio FTP
    Set-ItemProperty "IIS:\Sites\$FTP_SITE_NAME" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
    Set-ItemProperty "IIS:\Sites\$FTP_SITE_NAME" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0
    Set-ItemProperty "IIS:\Sites\$FTP_SITE_NAME" -Name ftpServer.security.ssl.serverCertHash -Value $cert.Thumbprint
    
    # Configurar firewall
    $firewallRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*FTP*" }
    if (-not $firewallRules) {
    Write-Host "Configurando reglas de firewall..." -ForegroundColor Yellow
    New-NetFirewallRule -Name "FTP-Server-21" -DisplayName "FTP Server (Port 21)" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow
    New-NetFirewallRule -Name "FTP-Server-Passive" -DisplayName "FTP Server (Passive)" -Direction Inbound -Protocol TCP -LocalPort 1024-65535 -Action Allow
    }
    
    # Reiniciar el sitio FTP
    Restart-WebItem "IIS:\Sites\$FTP_SITE_NAME" -Verbose
    }
}

# Función para validar nombre de usuario
function Test-ValidUsername {
    param (
    [string]$Username
    )
    # Validar longitud y caracteres permitidos (solo letras y números, sin caracteres especiales)
    return $Username -match "^[a-zA-Z0-9]{3,20}$"
}
# Función para validar contraseña
function Test-ValidPassword {
    param (
    [string]$Password
    )
    # Validar longitud, al menos un número y un carácter especial
    return $Password -match "^(?=.*\d)(?=.*[@._*,\-])[A-Za-z\d@._*,\-]{8,14}$"
    }
# Función para mostrar el menú
function Show-Menu {
    # Clear-Host
    Write-Host "1. Agregar usuarios"
    Write-Host "2. Cambiar de grupo"
    Write-Host "3. Eliminar usuario"
    Write-Host "4. Listar usuarios y grupos"
    Write-Host "5. Salir"
}

# Función para gestionar usuarios
function Manage-Users {
    while ($true) {
        Show-Menu
        $option = Read-Host "Seleccione una opción"
        switch ($option) {
            "1" { 
                # Agregar usuario
                $ftpUser = Read-Host "Ingresa el nombre del usuario"

                # Validar nombre de usuario
                if (-not (Test-ValidUsername -Username $ftpUser)) {
                    Write-Host "Error: El nombre de usuario no es válido. Debe tener entre 3 y 20 caracteres y solo puede contener letras y números." -ForegroundColor Red
                    Read-Host "Presione Enter para continuar"
                    continue
                }

                # Verificar si el usuario ya existe
                if (Get-LocalUser -Name $ftpUser -ErrorAction SilentlyContinue) {
                    Write-Host "Error: El usuario ya existe" -ForegroundColor Red
                    Read-Host "Presione Enter para continuar"
                    continue
                }
                $securePassword = Read-Host "Ingrese la contraseña" -AsSecureString
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
                $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

                # Validar contraseña
                if (-not (Test-ValidPassword -Password $plainPassword)) {
                    Write-Host "Error: La contraseña no es válida. Debe tener entre 8 y 14 caracteres, al menos un número y alguno de estos caracteres especiales: @._*,-" -ForegroundColor Red
                    Read-Host "Presione Enter para continuar"
                    continue
                }

                $groupOption = ""
                while ($groupOption -ne "1" -and $groupOption -ne "2") {
                    Write-Host "Selecciona el grupo para el usuario" -ForegroundColor Yellow
                    Write-Host "1. $GROUP1"
                    Write-Host "2. $GROUP2"
                    $groupOption = Read-Host "Opción"
                }
                $ftpGroup = if ($groupOption -eq "1") { $GROUP1 } else { $GROUP2 }
                try {
                    # Crear usuario
                    New-LocalUser -Name $ftpUser -Password $securePassword -FullName $ftpUser -Description "Usuario FTP" -AccountNeverExpires -PasswordNeverExpires

                    # Agregar usuario a los grupos
                    Add-LocalGroupMember -Group $ftpGroup -Member $ftpUser
                    Add-LocalGroupMember -Group $SHARED_GROUP -Member $ftpUser
                    
                    # Crear directorio personal
                    $userDir = "C:\FTP\$ftpUser"
                    if (-not (Test-Path $userDir)) {
                        New-Item -Path $userDir -ItemType Directory -Force | Out-Null
                    }

                    # Crear enlaces simbólicos
                    $userFtpDir = "C:\FTP\LocalUser\$ftpUser"
                    if (-not (Test-Path $userFtpDir)) {
                        New-Item -Path $userFtpDir -ItemType Directory -Force | Out-Null
                    }

                    # Crear enlace simbólico al directorio personal
                    cmd /c mklink /D "$userFtpDir\$ftpUser" "$userDir"
                    
                    # Crear enlace simbólico al directorio del grupo
                    if ($ftpGroup -eq $GROUP1) {
                        cmd /c mklink /D "$userFtpDir\$GROUP1" "$GROUP1_DIR"
                    } else {
                        cmd /c mklink /D "$userFtpDir\$GROUP2" "$GROUP2_DIR"
                    }
                    
                    # Crear enlace simbólico al directorio compartido
                    cmd /c mklink /D "$userFtpDir\$SHARED_GROUP" "$SHARED_DIR" 
                    
                    # Configurar permisos FTP
                    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "$FTP_SITE_NAME/$ftpUser" -Filter "system.ftpServer/security/authorization" -Name "." -ErrorAction SilentlyContinue
                    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow"; users=$ftpUser; permissions=3} -PSPath IIS:\ -Location "$FTP_SITE_NAME/$ftpUser"
                    Write-Host "Usuario creado exitosamente" -ForegroundColor Green
                }
                catch {
                    Write-Host "Error al crear el usuario: $($_.Exception.Message)" -ForegroundColor Red
                }
                Read-Host "Presione Enter para continuar"
            }

            "2" { 
                # Mover usuarios
                $username = Read-Host "Ingresa el nombre del usuario que deseas mover"
                
                # Verificar si el usuario existe
                if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
                    Write-Host "ERROR: El usuario no existe" -ForegroundColor Red
                    Read-Host "Presione Enter para continuar"
                    continue
                }
                
                # Determinar grupo actual
                $currentGroup = ""
                if (Get-LocalGroupMember -Group $GROUP1 -Member $username -ErrorAction SilentlyContinue) {
                    $currentGroup = $GROUP1
                    $newGroup = $GROUP2
                }
                elseif (Get-LocalGroupMember -Group $GROUP2 -Member $username -ErrorAction SilentlyContinue) {
                    $currentGroup = $GROUP2
                    $newGroup = $GROUP1
                }
                else {
                    Write-Host "El usuario no pertenece a ninguno de los grupos principales" -ForegroundColor Red
                    Read-Host "Presione Enter para continuar"
                    continue
                }

                $confirm = Read-Host "¿Deseas mover al usuario $username del grupo $currentGroup al grupo $newGroup? (s/n)"
                if ($confirm -ne "s" -and $confirm -ne "S") {
                    Write-Host "Operación cancelada" -ForegroundColor Yellow
                    Read-Host "Presione Enter para continuar"
                    continue
                }
                try {
                    # Cambiar grupo
                    Remove-LocalGroupMember -Group $currentGroup -Member $username
                    Add-LocalGroupMember -Group $newGroup -Member $username
                    
                    # Actualizar enlaces simbólicos
                    $userFtpDir = "C:\FTP\LocalUser\$username"
                    
                    # Eliminar enlace simbólico anterior
                    if (Test-Path "$userFtpDir\$currentGroup") {
                        Remove-Item "$userFtpDir\$currentGroup" -Force
                    }
                    
                    # Crear nuevo enlace simbólico
                    if ($newGroup -eq $GROUP1) {
                        cmd /c mklink /D "$userFtpDir\$GROUP1" "$GROUP1_DIR"
                    } else {
                        cmd /c mklink /D "$userFtpDir\$GROUP2" "$GROUP2_DIR"
                    }
                    Write-Host "Usuario movido exitosamente del grupo $currentGroup al grupo $newGroup" -ForegroundColor Green
                }
                catch {
                    Write-Host "Error al mover el usuario: $($_.Exception.Message)" -ForegroundColor Red
                }
                Read-Host "Presione Enter para continuar"
                }
            "3" { 
                # Eliminar usuario
                $username = Read-Host "Ingresa el nombre del usuario a eliminar"
                
                # Verificar si el usuario existe
                if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
                    Write-Host "ERROR: El usuario no existe" -ForegroundColor Red
                    Read-Host "Presione Enter para continuar"
                    continue
                }
                
                $confirm = Read-Host "¿Estás seguro de eliminar al usuario $username? (s/n)"
                if ($confirm -eq "s" -or $confirm -eq "S") {
                try {
                    # Eliminar enlaces simbólicos y directorios
                    $userFtpDir = "C:\FTP\LocalUser\$username"
                    if (Test-Path $userFtpDir) {
                        Remove-Item $userFtpDir -Recurse -Force
                    }
                    
                    $userDir = "C:\FTP\$username"
                    if (Test-Path $userDir) {
                        Remove-Item $userDir -Recurse -Force
                    }
                    
                    # Eliminar usuario
                    Remove-LocalUser -Name $username
                    Write-Host "Usuario eliminado exitosamente" -ForegroundColor Green
                }
                catch {
                    Write-Host "Error al eliminar el usuario: $($_.Exception.Message)" -ForegroundColor Red
                }
                }
                else {
                    Write-Host "Operación cancelada" -ForegroundColor Yellow
                }
                    Read-Host "Presione Enter para continuar"
            }
            "4" { 
                # Listar usuarios y grupos
                Write-Host "Usuarios y sus grupos:" -ForegroundColor Cyan
                Write-Host "------------------------" -ForegroundColor Cyan
                $users = Get-LocalUser | Where-Object { $_.Name -ne "Administrator" -and $_.Name -ne "Guest" }
                foreach ($user in $users) {
                    $username = $user.Name
                    $groups = @()
                    if (Get-LocalGroupMember -Group $GROUP1 -Member $username -ErrorAction SilentlyContinue) {
                        $groups += $GROUP1
                    }
                    if (Get-LocalGroupMember -Group $GROUP2 -Member $username -ErrorAction SilentlyContinue) {
                        $groups += $GROUP2
                    }
                    if (Get-LocalGroupMember -Group $SHARED_GROUP -Member $username -ErrorAction SilentlyContinue) {
                        $groups += $SHARED_GROUP
                    }
                    Write-Host "$username : $($groups -join ', ')" -ForegroundColor Yellow
                }
                Read-Host "Presione Enter para continuar"
            }
            "5" { 
                # Salir
                Write-Host "Saliendo del programa..." -ForegroundColor Green
                return
            }
            default {
                Write-Host "Opción inválida" -ForegroundColor Red
                Read-Host "Presione Enter para continuar"
            }
        }
    }
}
    

# Función principal
function Main {
    # Verificar si se ejecuta como administrador
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script debe ejecutarse como administrador. Por favor, reinicie PowerShell como administrador." -ForegroundColor Red
    exit 1
    }
    # Configurar directorios y permisos
    Set-DirectoryPermissions
    # Configurar servidor FTP
    Configure-FTPServer
    # Gestionar usuarios
    Manage-Users
}
# Ejecutar función principal
Main