function InstalarADDS_Pro {
    InstalarADDS -Dominio "diadelnino.com" -NetBiosName "DANONINO"
    ConfigADDS -Name1 "Grupo1" -Name2 "Grupo2"
    AddUserStatic -Dominio "diadenino.com" -Nombre "Jorge" -Contrasena "Jorge123$" -Grupo "Grupo1"
    AddUserStatic -Dominio "diadenino.com" -Nombre "Sebas" -Contrasena "Sebas123$" -Grupo "Grupo2"
    EstablecerHorarioGrupo1 -Nombre "Jorge"
    EstablecerHorarioGrupo2 -Nombre "Sebas"
}
function InstalarADDS{
    param(
        [String] $Dominio, 
        [String] $NetBiosName
        )
    
    # Instalar el rol de Active Directory Domain Services
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

    # Importar el módulo de AD
    Import-Module ADDSDeployment

    # Configurar el nuevo dominio
    Install-ADDSForest -DomainName $Dominio -DomainNetbiosName $NetBiosName -InstallDns 

}

function ConfigADDS {
    param (
        [String] $Name1,
        [String] $Name2
    )
    New-ADGroup -Name $Name1 -SamAccountName $Name1 -GroupScopte Global -GroupCategory Security
    New-ADGroup -Name $Name2 -SamAccountName $Name2 -GroupScopte Global -GroupCategory Security
    New-ADOrganizationalUnit -Name $Name1 -ProtectedFromAccidentalDeletion $true
    New-ADOrganizationalUnit -Name $Name2 -ProtectedFromAccidentalDeletion $true
    
}

function AddUserStatic {
    param(
        [String] $Dominio,
        [String] $Nombre,
        [String] $Contrasena,
        [String] $Grupo
    )
    $Seg = $Dominio.Split(".")
    $Seg0 = $Seg[0]
    $Seg1 = $Seg[1]

    New-ADUser -Name $Nombre -GivenName $Nombre -Surname $Nombre -SamAccountName $Nombre -UserPrincipalName "$Nombre@$Dominio" -Path "OU=$Grupo,DC=$Seg0,DC=$Seg1" -ChangePasswordAtLogon $true -AccountPassword (ConvertTo-SecureString $Contrasena -AsPlainText -Force) -Enabled $true
    Add-ADGroupMember -Identity $Grupo -Members $Nombre    
}

function EstablecerHorarioGrupo1 {
    param (
        [string] $Nombre 
    )
    # Definiendo el horario de acceso
    # 3 bytes por dia, 1 bit por hora
    # Permitiendo logon de L a S, de 8am a 3pm (hora 15)
    [byte[]]$horario = @(0,128,63,0,128,63,0,128,63,0,128,63,0,128,63,0,128,63,0,128,63)
    Get-ADUser -Identity $Nombre | Set-ADUser -Replace @{logonhours = $horario}
}
 
function EstablecerHorarioGrupo2 {
    param (
        [string] $Nombre 
    )
    # Definiendo el horario de acceso
    # 3 bytes por dia, 1 bit por hora
    # Permitiendo logon de L a S, de 3pm a 2am
    [byte[]]$horario = @(255,1,192,255,1,192,255,1,192,255,1,192,255,1,192,255,1,192,255,1,192)
    Get-ADUser -Identity $Nombre | Set-ADUser -Replace @{logonhours = $horario}
}

function nuevoUsuarioAD {
    param(
        [string] $Dominio
        )
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
