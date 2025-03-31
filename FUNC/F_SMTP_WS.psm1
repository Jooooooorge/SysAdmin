function mostrarMenu {
    write-host "[1] Crear Usuario"
    write-host "[2] Salir"
    Write-host "Selecciona una opción:"
    $opc = read-host
    return $opc
}

function configDNS {
    # Solicitar al usuario el dominio y la IP
    Write-Host "DEBUG*** Iniciando configuración.." -ForegroundColor Yellow
    $dominio =  "midominio.local"
    $ip = "192.168.1.200"

    # Instalar el rol de servidor DNS si no está instalado
    Install-WindowsFeature -Name DNS -IncludeManagementTools -Restart

    # Configurar el servidor DNS para resolver peticiones
    # Crear una zona DNS para el dominio ingresado
    Add-DnsServerPrimaryZone -Name $dominio -ZoneFile "$dominio.dns" -DynamicUpdate "NonSecureAndSecure"

    # Crear el registro A para el dominio ingresado y asignar la IP proporcionada
    Add-DnsServerResourceRecordA -ZoneName $dominio -Name "@" -AllowUpdateAny -IPv4Address $ip
    Add-DnsServerResourceRecordA -Name "www" -ZoneName "$dominio" -AllowUpdateAny -IPv4Address "$ip"

    # Crear la zona inversa para buscar por IP
    $ipSeg = $ip.Split('.')
    $ipInversa = "$($ipSeg[2]).$($ipSeg[1]).$($ipSeg[0]).in-addr.arpa"
    Add-DnsServerPrimaryZone -Name $ipInversa -ZoneFile "$ipInversa.dns" -DynamicUpdate "NonSecureAndSecure"
    Add-DnsServerResourceRecordPtr -Name "$($ipSeg[3])" -ZoneName "$ipInversa" -PtrDomainName "$dominio"

    # Configurar firewall para permitir ICMP
    New-NetFirewallRule -DisplayName "Ping" -Direction Inbound -Protocol ICMPv4 -Action Allow

    # Reinicio de servidor
    Restart-Service DNS
        
    # Configurar el servidor DNS para responder a consultas (forwarders)
    Write-Host "El servidor fue configurado correctamente!!"
        
}

function installSMTP {
    # Ruta de instalación
    Write-Host "DEBUG*** Iniciando instalación.." -ForegroundColor Yellow

    $installerPath = "C:\MailEnable-Setup.exe"
    $downloadUrl = "https://www.mailenable.com/Standard64.EXE"

    Write-Host " Descargando MailEnable..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

    Write-Host " Descarga completada." -ForegroundColor Green

    # Instalar MailEnable de forma silenciosa
    Write-Host " Instalando MailEnable..." -ForegroundColor Cyan
    Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait
    Write-Host " Instalación completada." -ForegroundColor Green

    # Configurar reglas de Firewall para SMTP y POP3
    Write-Host " Configurando Firewall..." -ForegroundColor Cyan
    New-NetFirewallRule -DisplayName "SMTP (25)" -Direction Inbound -Protocol TCP -LocalPort 25 -Action Allow
    New-NetFirewallRule -DisplayName "POP3 (110)" -Direction Inbound -Protocol TCP -LocalPort 110 -Action Allow
    New-NetFirewallRule -DisplayName "IMAP (143)" -Direction Inbound -Protocol TCP -LocalPort 143 -Action Allow

    Write-Host " Servicio instalado." -ForegroundColor Green
    
}

function configSMTP
{
    param (
        [String] $MailEnablePath, 
        [String] $PostOffice,
        [String] $Domain
        
    )
    $Mailbox = "admin"
    $Password = "admin123"

    # Agregar Post Office (Dominio)
    Write-Host "🔹 Creando Post Office: $PostOffice..." -ForegroundColor Cyan
    Start-Process -FilePath "$MailEnablePath\MEPOCMD.EXE" -ArgumentList "/ADD $PostOffice PWD=adminpass" -Wait

    # Agregar Dominio al Post Office
    Write-Host "🔹 Agregando dominio: $Domain..." -ForegroundColor Cyan
    Start-Process -FilePath "$MailEnablePath\MEPOCMD.EXE" -ArgumentList "/ADD-DOMAIN $PostOffice $Domain" -Wait

    # Crear Mailbox
    Write-Host "🔹 Creando Mailbox: $Mailbox@$Domain..." -ForegroundColor Cyan
    Start-Process -FilePath "$MailEnablePath\MEBMCMD.EXE" -ArgumentList "/ADD-MAILBOX $PostOffice $Mailbox $Password" -Wait

    # Configurar SMTP y POP3
    Write-Host "🔹 Habilitando SMTP y POP3..." -ForegroundColor Cyan
    Start-Process -FilePath "$MailEnablePath\MESMTPCMD.EXE" -ArgumentList "/ENABLE" -Wait
    Start-Process -FilePath "$MailEnablePath\MEPOPCMD.EXE" -ArgumentList "/ENABLE" -Wait

    Write-Host " Configuración del servicio de correo completada" -ForegroundColor Green
}

function addUser
{
    param (
        [String] $MailEnablePath,
        [String] $PostOffice,
        [String] $User,
        [String] $Password
    )


    Write-Host "Debugg** Creando usuario"
    Start-Process -FilePath "$MailEnablePath\MEBMCMD.EXE" -ArgumentList "/ADD-MAILBOX $PostOffice $User $Password" -Wait
}

function checkUser {
    param (
        [String] $User
    )
    # Patrón regex: solo letras y números, longitud entre 1 y 20 caracteres.
    $pattern = '^[a-zA-Z0-9]{1,20}$'
    
    if ($User -match $pattern) {
        Write-Host "El nombre de usuario '$User' es válido." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "El nombre de usuario es inválido. Debe contener solo caracteres alfanuméricos, sin espacios y máximo 20 caracteres." -ForegroundColor Red
        return $false
    }
}

function checkPassword
{
    param
    (
        [String] $Password
    )

    $pattern = '^(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z0-9]).{8,20}$'
    if ($Password -match $pattern) {
        Write-Host "La contraseña es válida." -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "La contraseña es inválida. Debe tener entre 8 y 20 caracteres, contener al menos una mayúscula, un número y un carácter especial." -ForegroundColor Red
        return $false
    }
}