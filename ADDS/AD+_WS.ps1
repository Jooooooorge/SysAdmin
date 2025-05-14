function Instalar-ActiveDirectory(){
    if(-not((Get-WindowsFeature -Name AD-Domain-Services).Installed)){
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    }
    else{
        Write-Host "Active Directory ya se encuentra instalado, omitiendo instalación..."
    }
}

function Configurar-DominioAD(){
    if((Get-WmiObject Win32_ComputerSystem).Domain -eq "dia-nino.com"){
        echo "El dominio ya se encuentra configurado, omitiendo configuración..."
    }
    else{
        Import-Module ADDSDeployment
        Install-ADDSForest -DomainName "dia-nino.com" -DomainNetbiosName "DIANINO" -InstallDNS
    }
}

function Crear-UnidadesOrganizativas(){
    try {
        if((Get-ADGroup -Filter "Name -eq 'grupo1'") -and (Get-ADGroup -Filter "Name -eq 'grupo2'") -and (Get-ADOrganizationalUnit -Filter "Name -eq 'grupo1'") -and (Get-ADOrganizationalUnit -Filter "Name -eq 'grupo2'")){
            echo "Los grupos ya se encuentran creados en este equipo"
        }
        else{
            New-ADGroup -Name "grupo1" -SamAccountName "grupo1" -GroupScope Global -GroupCategory Security
            New-ADGroup -Name "grupo2" -SamAccountName "grupo2" -GroupScope Global -GroupCategory Security
            echo "Grupos creados correctamente"
        }
    }
    catch {
        echo $Error[0].ToString()
    }
}

function Es-ContrasenaValida($contrasena) {
    return ($contrasena.Length -ge 8 -and
            $contrasena -match '[A-Z]' -and
            $contrasena -match '[a-z]' -and
            $contrasena -match '\d' -and
            $contrasena -match '[^a-zA-Z\d]')
}

function Crear-Usuario(){
    try {
        $nombreUsuario = Read-Host "Ingresa el nombre de usuario"
        $contrasena = Read-Host "Ingresa la contrasena"
        $grupo = Read-Host "Ingresa el grupo de la que sera parte el usuario (grupo1/grupo2)"
        if(($grupo -ne "grupo1") -and ($grupo -ne "grupo2")){
            echo "Ingresa un grupo valido (grupo1/grupo2)"
        }
        elseif(-not(Es-ContrasenaValida -contrasena $contrasena)){
            echo "El password no es lo suficientemente seguro"
        }
        else{
            New-ADUser -Name $nombreUsuario -GivenName $nombreUsuario -Surname $nombreUsuario -SamAccountName $nombreUsuario -UserPrincipalName "$nombreUsuario@dia-nino.com" -Path "OU=$grupo,DC=dia-nino,DC=com" -ChangePasswordAtLogon $true -AccountPassword (ConvertTo-SecureString $contrasena -AsPlainText -Force) -Enabled $true
            Add-ADGroupMember -Identity $grupo -Members $nombreUsuario
            Configurar-Horarios -nombreUsuario $nombreUsuario -grupo $grupo
            echo "Cuenta creada correctamente"
        }
    }
    catch {
        echo $Error[0].ToString()
    }
}

function Configurar-PermisosAplicaciones(){ 
    try {
        # Los nombres de las políticas no tienen nada que ver, pero así funcionan
        # Bloquear bloc de notas para el grupo2
        # Esta parte funciona correctamente, bloquea el bloc de notas
        if(Get-GPO -Name "Bloquear solo notepad" -ErrorAction SilentlyContinue){
            echo "La regla para el grupo2 ya se encuentra creada"
        }
        else{
            New-GPO -Name "Bloquear solo notepad" | Out-Null
            New-GPLink -Name "Bloquear solo notepad" -Target "OU=grupo2,DC=dia-nino,DC=com"

            Set-GPRegistryValue -Name "Bloquear solo notepad" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
            -ValueName "DisallowRun" -Type DWord -Value 1

            Set-GPRegistryValue -Name "Bloquear solo notepad" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" `
            -ValueName "1" -Type String -Value "notepad.exe"
 
            Set-GPPermissions -Name "Bloquear solo notepad" -TargetName "grupo2" -TargetType Group -PermissionLevel GpoApply

            echo "Regla para el grupo dos creada correctamente"
        }

        # Bloquear todo menos bloc de notas para el grupo1
        if(Get-GPO -Name "Permitir solo notepad" -ErrorAction SilentlyContinue){
            echo "La regla para el grupo1 ya se encuentra creada"
        }
        else{
            New-GPO -Name "Permitir solo notepad" | Out-Null
            New-GPLink -Name "Permitir solo notepad" -Target "OU=grupo1,DC=dia-nino,DC=com"

            Set-GPRegistryValue -Name "Permitir solo notepad" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
            -ValueName "RestrictRun" -Type DWord -Value 1

            Set-GPRegistryValue -Name "Permitir solo notepad" `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\RestrictRun" `
            -ValueName "1" -Type String -Value "notepad.exe"

            Set-GPPermission -Name "Permitir solo notepad" -TargetName "grupo1" -TargetType Group -PermissionLevel GpoApply

            echo "Regla para el grupo uno creada correctamente"
        }
    }
    catch {
        echo $Error[0].ToString()
    }
}

function Configurar-Auditoria(){
    try {
        $nombreGpo = "Auditoria dominio"
        if (-not (Get-GPO -Name $nombreGpo -ErrorAction SilentlyContinue)) {
            New-GPO -Name $nombreGpo
            New-GPLink -Name $nombreGpo -Target "DC=dia-nino,DC=com"

            Set-GPRegistryValue -Name $nombreGpo `
            -Key "HKLM\Software\Policies\Microsoft\Windows\System\Audit" `
            -ValueName "Auditar" -Type DWord -Value 1

            AuditPol /set /subcategory:"Acceso de servicio del directorio" /success:enable /failure:enable
            AuditPol /set /subcategory:"Cambios de servicio de directorio" /success:enable /failure:enable

            echo "Configuracion de auditoria realizada correctamente "
        }
        else {
            echo "La regla de auditoria ya se encuentra creada"
        }
    }
    catch {
        echo $Error[0].ToString()
    }
}

function Configurar-ContrasenasSeguras(){
    try {
        Set-ADDefaultDomainPasswordPolicy -Identity "dia-nino.com" `
        -MinPasswordLength 8 `
        -ComplexityEnabled $true `
        -PasswordHistoryCount 1 `
        -MinPasswordAge "1.00:00:00" `
        -MaxPasswordAge "30.00:00:00"

        echo "Regla de passwords seguros configurada correctamente"
    }
    catch {
        echo $Error[0].ToString()
    }
}

function Configurar-Horarios($nombreUsuario, $grupo){
    try {
        if($grupo -eq "grupo1"){
            # Horas de 8am a 3pm
            [byte[]]$horasGrupoUno = @(0,128,63,0,128,63,0,128,63,0,128,63,0,128,63,0,128,63,0,128,63)
            Get-ADUser -Identity $nombreUsuario | Set-ADUser -Replace @{logonhours = $horasGrupoUno}
            echo "Se ha configurado el horario del grupo uno para $nombreUsuario"
        }
        elseif($grupo -eq "grupo2"){
            # Horas de 3pm a 2am
            [byte[]]$horasGrupoDos = @(255,1,192,255,1,192,255,1,192,255,1,192,255,1,192,255,1,192,255,1,192) 
            Get-ADUser -Identity $nombreUsuario | Set-ADUser -Replace @{logonhours = $horasGrupoDos}
            echo "Se ha configurado el horario del grupo dos para $nombreUsuario"
        }
        else{
            echo "Grupo invalido"
        }
    }
    catch {
        echo $Error[0].ToString()
    }
}

function Configurar-AlmacenamientoArchivos(){
    try {
        $nombreCuotaGrupoUno = "Cuota5MbGrupoUno"
        $nombreCuotaGrupoDos = "Cuota10MbGrupoDos"

        if (-not (Get-GPO -Name $nombreCuotaGrupoUno -ErrorAction SilentlyContinue)) {
            New-GPO -Name $nombreCuotaGrupoUno | Out-Null
            echo "GPO $nombreCuotaGrupoUno creada"
        } else {
            echo "GPO $nombreCuotaGrupoUno ya existe"
        }

        if (-not (Get-GPO -Name $nombreCuotaGrupoDos -ErrorAction SilentlyContinue)) {
            New-GPO -Name $nombreCuotaGrupoDos | Out-Null
            echo "GPO $nombreCuotaGrupoDos creada"
        } else {
            echo "GPO $nombreCuotaGrupoDos ya existe"
        }

        Set-GPRegistryValue -Name $nombreCuotaGrupoUno `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
            -ValueName "MaxProfileSize" `
            -Type DWord -Value 5000

        Set-GPRegistryValue -Name $nombreCuotaGrupoDos `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
            -ValueName "MaxProfileSize" `
            -Type DWord -Value 10000

        New-GPLink -Name $nombreCuotaGrupoUno -Target "OU=grupo1,DC=dia-nino,DC=com" -Enforced "Yes"
        New-GPLink -Name $nombreCuotaGrupoDos -Target "OU=grupo2,DC=dia-nino,DC=com" -Enforced "Yes"

        echo "Regla de limites de almacenamiento de archivos creada correctamente"
    }
    catch {
        echo $Error[0].ToString()
    }
}

while($true){
    echo "Menu de opciones"
    echo "1. Instalar y configurar Active Directory"
    echo "2. Crear grupos"
    echo "3. Crear usuario"
    echo "4. Configurar politicas de aplicaciones"
    echo "5. Configurar auditoria de eventos y passwords seguros"
    echo "6. Configurar almacenamiento de archivos"
    echo "7. Salir"
    $opc = Read-Host "Selecciona una opcion"

    if($opc -eq "7"){
        echo "Saliendo..."
        break
    }

    switch($opc){
        "1"{
            Instalar-ActiveDirectory
            Configurar-DominioAD
        }
        "2"{
            Crear-UnidadesOrganizativas
        }
        "3"{
            Crear-Usuario
        }
        "4"{
            Configurar-PermisosAplicaciones
        }
        "5" {
            Configurar-Auditoria
            Configurar-ContrasenasSeguras
        }
        "6"{
            Configurar-AlmacenamientoArchivos
        }
        default { echo "Selecciona una opcion valida (1..7)"}
    }
    echo ""
}