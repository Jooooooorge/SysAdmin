function mostrarMenu {
    write-host "[1] Crear Usuario"
    Write-host "Selecciona una opción:"
    $opc = read-host
    return $opc
}

function configSMTP {
    # Ruta de instalación
    $installerPath = "C:\MailEnable-Setup.exe"
    $downloadUrl = "https://www.mailenable.com/download.asp"

    Write-Host "🔹 Descargando MailEnable..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

    Write-Host "✅ Descarga completada." -ForegroundColor Green

    # Instalar MailEnable de forma silenciosa
    Write-Host "🔹 Instalando MailEnable..." -ForegroundColor Cyan
    Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait

    Write-Host "✅ Instalación completada." -ForegroundColor Green

    # Configurar reglas de Firewall para SMTP y POP3
    Write-Host "🔹 Configurando Firewall..." -ForegroundColor Cyan
    New-NetFirewallRule -DisplayName "SMTP (25)" -Direction Inbound -Protocol TCP -LocalPort 25 -Action Allow
    New-NetFirewallRule -DisplayName "POP3 (110)" -Direction Inbound -Protocol TCP -LocalPort 110 -Action Allow
    New-NetFirewallRule -DisplayName "IMAP (143)" -Direction Inbound -Protocol TCP -LocalPort 143 -Action Allow

    Write-Host "✅ Configuración de Firewall completada." -ForegroundColor Green
    Write-Host "🚀 MailEnable está listo. Abre su consola de administración para configurar dominios y cuentas."

    
}