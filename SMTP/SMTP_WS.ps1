# Rutas y URLs
$xamppUrl = "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/5.6.40/xampp-win32-5.6.40-0-VC11-installer.exe/download"
$xamppInstaller = "$env:TEMP\xampp5-installer.exe"
$squirrelUrl = "https://sourceforge.net/projects/squirrelmail/files/latest/download"
$squirrelZip = "$env:TEMP\squirrelmail.zip"
$xamppPath = "C:\xampp"
$squirrelTarget = "$xamppPath\htdocs\squirrelmail"

# Función para verificar existencia de archivos o carpetas
function Check-Exists($path, $desc) {
    if (!(Test-Path $path)) {
        Write-Error "❌ $desc no encontrado en: $path. Abortando..."
        exit 1
    }
    else {
        Write-Host "✅ $desc encontrado."
    }
}

# Descargar instalador de XAMPP
Write-Host "`n🔽 Descargando XAMPP 5.6.40..."
Invoke-WebRequest -Uri $xamppUrl -OutFile $xamppInstaller -UseBasicParsing
Check-Exists $xamppInstaller "Instalador de XAMPP"

# Ejecutar instalador en modo gráfico (no tiene modo silencioso oficial en esta versión)
Write-Host "`n⚙️ Ejecutando instalador de XAMPP (por favor instalá manualmente en C:\xampp)"
Start-Process -FilePath $xamppInstaller -Wait

# Verificar instalación
Check-Exists "$xamppPath\xampp-control.exe" "XAMPP Control Panel"
Check-Exists "$xamppPath\apache\bin\httpd.exe" "Apache Server"
Check-Exists "$xamppPath\MercuryMail\mercury.exe" "Mercury Mail"

# Descargar SquirrelMail
Write-Host "`n🔽 Descargando SquirrelMail..."
Invoke-WebRequest -Uri $squirrelUrl -OutFile $squirrelZip -UseBasicParsing
Check-Exists $squirrelZip "Archivo ZIP de SquirrelMail"

# Extraer SquirrelMail
Write-Host "📂 Extrayendo SquirrelMail..."
Expand-Archive -Path $squirrelZip -DestinationPath "$xamppPath\htdocs" -Force

# Detectar carpeta extraída y renombrar
$squirrelExtracted = Get-ChildItem "$xamppPath\htdocs" | Where-Object { $_.Name -like "squirrelmail*" -and $_.PSIsContainer } | Select-Object -First 1
if ($squirrelExtracted) {
    Rename-Item -Path $squirrelExtracted.FullName -NewName "squirrelmail" -Force
    Write-Host "✅ SquirrelMail extraído en: $squirrelTarget"
}
else {
    Write-Error "❌ Carpeta extraída de SquirrelMail no encontrada. Abortando..."
    exit 1
}

# Habilitar extensiones en php.ini
$phpIni = "$xamppPath\php\php.ini"
Check-Exists $phpIni "Archivo php.ini"

Write-Host "🛠️ Activando extensiones IMAP y mbstring..."
(Get-Content $phpIni) -replace ";extension=imap", "extension=imap" `
    -replace ";extension=mbstring", "extension=mbstring" | Set-Content $phpIni

# Verificar activación
$iniContent = Get-Content $phpIni
if ($iniContent -match "extension=imap" -and $iniContent -match "extension=mbstring") {
    Write-Host "✅ Extensiones activadas correctamente"
}
else {
    Write-Error "❌ No se pudieron activar extensiones PHP"
    exit 1
}

# Reiniciar Apache
Write-Host "🔁 Reiniciando Apache..."
& "$xamppPath\apache_stop.bat"
Start-Sleep -Seconds 2
& "$xamppPath\apache_start.bat"

# Mostrar dirección local
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" | Where-Object { $_.IPAddress -notlike "169.*" }).IPAddress
Write-Host "`n🌐 SquirrelMail disponible en: http://$ip/squirrelmail"
