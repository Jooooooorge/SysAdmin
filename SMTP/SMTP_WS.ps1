# Ruta de instalación
$xamppUrl = "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/7.4.33/xampp-windows-x64-7.4.33-0-VS16-installer.exe/download"
$xamppInstaller = "$env:TEMP\xampp-installer.exe"
$squirrelUrl = "https://sourceforge.net/projects/squirrelmail/files/latest/download"
$squirrelZip = "$env:TEMP\squirrelmail.zip"
$squirrelDir = "C:\xampp\htdocs\squirrelmail"

Write-Host "Descargando XAMPP..."
Invoke-WebRequest -Uri $xamppUrl -OutFile $xamppInstaller

Write-Host "Instalando XAMPP..."
Start-Process -FilePath $xamppInstaller -ArgumentList "--mode unattended" -Wait

# Espera que termine de instalar
Start-Sleep -Seconds 10

# Iniciar Apache y Mercury
Write-Host "Iniciando Apache y Mercury..."
Start-Process "C:\xampp\xampp-control.exe"
Start-Sleep -Seconds 10

# Activar Mercury (manual o por línea de comandos si se hace vía scripts)
# Alternativamente, usa nssm para ejecutarlos como servicio

# Descargar SquirrelMail
Write-Host "Descargando SquirrelMail..."
Invoke-WebRequest -Uri $squirrelUrl -OutFile $squirrelZip

Write-Host "Extrayendo SquirrelMail..."
Expand-Archive -Path $squirrelZip -DestinationPath "C:\xampp\htdocs\"

# Mover carpeta extraída a nombre estándar (puede variar según ZIP)
$squirrelExtracted = Get-ChildItem "C:\xampp\htdocs\" | Where-Object { $_.Name -like "squirrelmail*" -and $_.PSIsContainer } | Select-Object -First 1
Rename-Item -Path $squirrelExtracted.FullName -NewName "squirrelmail"

# Configurar PHP (si es necesario)
Write-Host "Habilitando extensiones IMAP y mbstring..."
$phpIni = "C:\xampp\php\php.ini"
(gc $phpIni) -replace "; extension=imap", "extension=imap" `
    -replace "; extension=mbstring", "extension=mbstring" | Set-Content $phpIni

# Reiniciar Apache
Write-Host "Reiniciando Apache..."
& "C:\xampp\apache_stop.bat"
Start-Sleep -Seconds 3
& "C:\xampp\apache_start.bat"

# Mostrar IP y URL
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet" | Where-Object { $_.IPAddress -notlike "169.*" }).IPAddress
Write-Host "`nServidor Web listo. Accede a: http://$ip/squirrelmail"

