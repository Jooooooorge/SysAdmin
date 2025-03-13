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


ActualizarDatos -Array $Servidores
while ($true)
{
    $opc = MenuServidores
    MenuDescarga -opc $opc -Servidores $Servidores
}


