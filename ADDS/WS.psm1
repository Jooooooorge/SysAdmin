function InstalarADDS{
    
    # Instalar el rol de Active Directory Domain Services
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    # Importar el módulo de AD
    Import-Module ADDSDeployment

    # Configurar el nuevo dominio
    $Dominio = "jorge.com"  # Cambia esto si quieres otro nombre de dominio
    Install-ADDSForest `
        -DomainName $Dominio `
        -DomainNetbiosName "jorge" `
        -SafeModeAdministratorPassword (ConvertTo-SecureString "Jorge1234$" -AsPlainText -Force) `
        -InstallDns `
        -Force

    New-ADOrganizationalUnit -Name "Cuates" -ProtectedFromAccidentalDeletion $true
    New-ADOrganizationalUnit -Name "No_cuates" -ProtectedFromAccidentalDeletion $true
    
}
function InstalarADDS_Pro {
    $Usuario1 = "Usuario1"
    $Usuario2 = "Usuario2"
    # Instalar el rol de Active Directory Domain Services
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    # Importar el módulo de AD
    Import-Module ADDSDeployment

    # Configurar el nuevo dominio
    $Dominio = "diadelnino.com"  
    Install-ADDSForest `
        -DomainName $Dominio `
        -DomainNetbiosName "diadelnino" `
        -SafeModeAdministratorPassword (ConvertTo-SecureString "Jorge1234$" -AsPlainText -Force) `
        -InstallDns `
        -Force

    # Creación las unidades organizativas UO
    New-ADOrganizationalUnit -Name "Grupo1" -ProtectedFromAccidentalDeletion $true
    New-ADOrganizationalUnit -Name "Grupo2" -ProtectedFromAccidentalDeletion $true
    
    # Separacíon de los componentes del dominio
    $Seg = $Dominio.Split(".")
    $Seg0 = $Seg[0]
    $Seg1 = $Seg[1]
    
    
    # Creación de grupo 1 y grupo 2
    New-ADGroup -Name "Grupo1" -SamAccountName "Grupo1" -GroupCategory Security -GroupScope Global -Path "OU=Grupo1,DC=$Seg0,DC=$Seg1"
    New-ADGroup -Name "Grupo2" -SamAccountName "Grupo2" -GroupCategory Security -GroupScope Global -Path "OU=Grupo2,DC=$Seg0,DC=$Seg1"

    # Creación de los dos usuarios, uno para cada UO
    New-ADUser -Name $Usuario1 `
        -GivenName $Usuario1 `
        -Surname $Usuario1 `
        -SamAccountName $Usuario1 `
        -UserPrincipalName "$Usuario1@$Dominio" `
        -Path "OU=Grupo1,DC=$Seg0,DC=$Seg1" `
        -AccountPassword (ConvertTo-SecureString "Jorge123$" -AsPlainText -Force) `
        -Enabled $true

    New-ADUser -Name $Usuario2 `
        -GivenName $Usuario2 `
        -Surname $Usuario2 `
        -SamAccountName $Usuario2 `
        -UserPrincipalName "$Usuario2@$Dominio" `
        -Path "OU=Grupo2,DC=$Seg0,DC=$Seg1" `
        -AccountPassword (ConvertTo-SecureString "Jorge123$" -AsPlainText -Force) `
        -Enabled $true

    # Llamada a la función de set horarios
    EstablecerHorario_Grupo1 -seg0 $Seg0 -seg1 $Seg1
    EstablecerHorario_Grupo2 -seg0 $Seg0 -seg1 $Seg1
    
    # Llamada al función limitar tamaño
    # LimitarTamaño


}

function LimitarTamaño {
    # Limitar el tamaño
    New-Item -ItemType Directory -Path "D:\Grupo1"
    
    $acl = Get-Acl "D:\Grupo1"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Grupo1","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($rule)
    Set-Acl "D:\Grupo1" $acl

    fsutil quota track D:
    fsutil quota enforce D:
    fsutil quota modify D: 5242880 5242880 Grupo1

    New-Item -ItemType Directory -Path "D:\Grupo2"
    
    # Permisos
    $acl = Get-Acl "D:\Grupo2"
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Grupo2","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($rule)
    Set-Acl "D:\Grupo2" $acl

    # Cuota
    fsutil quota modify D: 10485760 10485760 Grupo2
    
}
function EstablecerHorario_Grupo1 {
    param (
        [string] $seg0, [string] $seg1 
    )
    # Definir la UO
    $UO = "OU=Grupo1,DC=$seg0,DC=$seg1"

    # Obtener todos los usuarios en esa UO
    $usuarios = Get-ADUser -Filter * -SearchBase $UO
    
    # Definiendo el horario de acceso
    # 3 bytes por dia, 1 bit por hora
    # Permitiendo logon de L a S, de 8am a 3pm (hora 14)
    [byte[]]$horario = @(0,128,63,0,128,63,0,128,63,0,128,63,0,128,63,0,128,63,0,128,63)
    
    foreach ($usuario in $usuarios) {
    
        Get-ADUser -Identity $usuario |
        Set-ADUser -Replace @{logonhours = $hours}
    }
}
    
function EstablecerHorario_Grupo2 {
    param (
        [string] $seg0, [string] $seg1 
    )
    # Definir la UO
    $UO = "OU=Grupo2,DC=$seg0,DC=$seg1"

    # Obtener todos los usuarios en esa UO
    $usuarios = Get-ADUser -Filter * -SearchBase $UO
    
    # Definiendo el horario de acceso
    # 3 bytes por dia, 1 bit por hora
    # Permitiendo logon de L a S, de 3pm a 2am
    [byte[]]$horario = @(255,1,192,255,1,192,255,1,192,255,1,192,255,1,192,255,1,192,255,1,192)
    
    foreach ($usuario in $usuarios) {
    
        Get-ADUser -Identity $usuario |
        Set-ADUser -Replace @{logonhours = $hours}
    }
}

function nuevoUsuarioAD {
    param([string] $Dominio)
    $Seg = $Dominio.Split(".")
    $Seg0 = $Seg[0]
    $Seg1 = $Seg[1]
    while($true){
        while ($true){
            write-host "Ingresa el nombre del usuario:"
            $Usuario = Read-Host

            if(validarUsuario -Usuario $Usuario)
            {
                break
            }
        }
        while ($true){
            write-host "Crea una contraseña:"
            write-host "(8-20 Caracteres, NO espacios, NO caracteres especiales)"
            $Contra = read-host 
            if(validarContra -Contra $Contra)
            {
                break
            }
        }
        while ($true){
            write-host "Ingresa el nombre:"
            $Nombre = Read-Host 
            if(validarNombre -Nombre $Nombre)
            {
                break
            }
        }
            
        while ($true){
            write-host "Ingresa su 1er apellido:"
            $Apellido = Read-Host
            if(validarNombre -Nombre $Apellido)
            {
                break
            }
        }
        while ($true){
            write-host "Elige Grupo"
            write-host "[1] Grupo1"
            write-host "[2] Grupo2"
            write-host "Selecciona una opción:"
            $UO = Read-Host
            if ($UO -eq 1 ) {
                $UO = "Cuates"
                break
            } elseif ($UO -eq 2) {
                $UO = "No_cuates"
                break
            } else {
                write-host "Selecciona una opción valida..."
            }
        }

        #Creación del usuario
        New-ADUser -Name $Usuario `
            -GivenName $Nombre `
            -Surname $Apellido `
            -SamAccountName $Usuario `
            -UserPrincipalName "$Usuario@$Dominio" `
            -Path "OU=$UO,DC=$Seg0,DC=$Seg1" `
            -AccountPassword (ConvertTo-SecureString $Contra -AsPlainText -Force) `
            -Enabled $true

        #Validar que si creo el usario
        if (Get-ADUser -Filter {Name -eq $Usuario}){
            write-host "Usuario creado exitosamente"
            return
        } else {
            Write-host "Usuario no creado"
        }
        
    }
}
function validarContra {
    param([String] $Contra)
    # 8-20 Caracteres, Una Mayuscula,  NO espacios, NO caracteres especiales)"
    if (($Contra.Length -ge 8) -and ($Contra.Length -le 20) -and ($Contra -match "^[a-zA-Z0-9]+$") -and ($Contra -match "[A-Z]")) {
        return $true
    }
    else {
        Write-Host "Contraseña inválida. Debe tener entre 8-20 caracteres, al menos una mayúscula, sin espacios ni caracteres especiales."
        return $false
    }
}
function validarNombre {
    param (
        [string] $Nombre
    )
    # Condiciones 
    <#
        -No espacios
        -No caracteres especiales
    #>    
    if ($Nombre -match "^[a-zA-Z]+$") {
        return $true
    }
    else {
        Write-Host "Nombre inválido. Solo letras permitidas."
        return $false
    }



    return $true
}
function validarUsuario {
    param (
        [string] $Usuario
    )
    # Condiciones 
    <#
        -No espacios
        -Maximo 20 caracteres
        -No caracteres especiales
    #>
    if (($Usuario.Length -le 20) -and ($Usuario -match "^[a-zA-Z0-9]+$")) {
        return $true
    }
    else {
        Write-Host "Usuario inválido. Max 20 caracteres, solo letras y números, sin espacios ni especiales."
        return $false
    }


    return $true
}
