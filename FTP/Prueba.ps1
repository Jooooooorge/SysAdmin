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