# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 6 
# Descripción:
# Dar la opción al usuario para elegir entre 3 servidores diferentes: Ejemplo
<#
    [1] Apache
    [2] Tomcat
    [3] IIS
#> 
<#
    Al seleccionar x opción se debera mostrar la ultima versión de la versión LTS y la versión de 
    desarollo de cada uno
    Apache
    LTS 2.4.777
    DEV 2.4.69
#>
# Funciones necesarias
Import-Module ..\FUNC\WS.ps1 -Force

# Variables
$Servidores =  @()
$opc = 0

$Servidores =@(
    [PSCustomObject]@{
        NombreLTS = "ApacheLTS"
        VersionLTS = ""
        EnlaceLTS = "https://www.apachelounge.com/download"
        PatronLTS = '\/VS17\/binaries\/httpd-\d{1,}\.\d{1,}\.\d{1,}-\d{1,}-win64-VS\d{2}\.zip'
        PatronVersion = '(\d{1,}\.\d{1,}\.\d{1,})'
    }

    <#[PSCustomObject]@{
        NombreLTS = "Nginx"
        VersionLTS = ""
        EnlaceLTS = "link devarar"
        PatronLTS = ''
        
        NombreDEV = ""
        VersionDEV = ""
        EnlaceDEV = ""
        PatronDEV = ''
    } #>
)

# Descargar el instalador de Google Chrome
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile "$env:TEMP\chrome_installer.exe"

# Instalar Google Chrome en modo silencioso
Start-Process -FilePath "$env:TEMP\chrome_installer.exe" -ArgumentList "/silent /install" -Wait

# Verificar la instalación
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $chromePath) {
    Write-Output "Google Chrome se instaló correctamente en: $chromePath"
} else {
    Write-Output "Error: No se pudo instalar Google Chrome."
}

# Abrir Google Chrome (opcional)
Start-Process -FilePath $chromePath

<#ActualizarDatos -Array $Servidores
While($true){
    $opc = MenuServidores
    MenuDescarga -opc $opc -Servidores $Servidores
}#>


