# ======== ======== ======== ======== ======== ======== ======== ========
# Practica 8


function install_mercury {

    # Instalacion de mercury
    $downloadPath = "https://download-us.pmail.com/m32-480.exe"
    $downloadedPath = "$env:HOMEPATH\Downloads\mercury.exe"

    Invoke-WebRequest -Uri $downloadPath -Outfile $downloadedPath -UseBasicParsing -ErrorAction Stop
    cd $env:HOMEPATH\Downloads
    Start-Process .\mercury.exe

    New-NetFirewallRule -DisplayName "SMTP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 25, 110, 143, 587, 993, 995 -Profile Any -Enabled True
}

function install_xampp {
    
    #Seccion de instalacion de XAMPP
    New-Item -Path "C:\Installers" -ItemType Directory -Force | Out-Null

    # Descargar XAMPP (asegurate de tener curl en PowerShell v5+)
    $xamppUrl = "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/5.6.40/xampp-windows-x64-5.6.40-1-VC11-installer.exe/download"
    $outputPath = "C:\Installers\xampp-installer.exe"


    curl.exe -L $xamppUrl -o $outputPath

    # Ejecutar el instalador de XAMPP
    cd "C:\Installers"
    Start-Process -FilePath .\xampp-installer.exe
}
function install_squirrel {
    
    #Seccion de instalacion de SquirrelMail
    # Ruta de instalación de Apache (htdocs)
    $htdocsPath = "C:\xampp\htdocs\squirrelmail"

    # Crear carpeta
    New-Item -Path $htdocsPath -ItemType Directory -Force | Out-Null

    # Descargar desde GitHub
    $zipUrl = "https://sourceforge.net/projects/squirrelmail/files/stable/1.4.22/squirrelmail-webmail-1.4.22.zip/download"
    $zipPath = "C:\Installers\squirrelmail.zip"

    curl.exe -L $zipUrl -o $zipPath

    # Descomprimir el archivo ZIP
    Expand-Archive -Path $zipPath -DestinationPath "C:\Installers" -Force

    # Copiar contenido a htdocs
    $extractedFolder = "C:\Installers\squirrelmail-webmail-1.4.22"
    Copy-Item -Path "$extractedFolder\*" -Destination $htdocsPath -Recurse -Force


    # Crear carpeta de configuración si no existe
    $configFolder = "$htdocsPath\config"
    New-Item -Path $configFolder -ItemType Directory -Force | Out-Null

    #Renombramos y editamos el archivo de configuracion
    Rename-Item -Path C:\xampp\htdocs\squirrelmail\config\config_default.php -NewName "config.php"            #Aqui el dominio que se configuro en la instalacion
    (Get-Content "C:\xampp\htdocs\squirrelmail\config\config.php") -replace '\$domain\s*=\s*''[^'']+'';', '$domain = ''localhost'';' | Set-Content "C:\xampp\htdocs\squirrelmail\config\config.php"
    (Get-Content "C:\xampp\htdocs\squirrelmail\config\config.php") -replace '\$data_dir\s*=\s*''[^'']+'';', '$data_dir = ''C:/xampp/htdocs/squirrelmail/data/'';' | Set-Content "C:\xampp\htdocs\squirrelmail\config\config.php"

    # Configurar permisos (IMPORTANTE)
    Write-Host "Configurando permisos..." -ForegroundColor Cyan
    try {
        $acl = Get-Acl $htdocsPath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Todos", # O "IUSR" si usas IIS
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $htdocsPath -AclObject $acl
    }
    catch {
        Write-Warning "No se pudieron configurar los permisos: $_"
    }

}


function main {
    install_mercury
    install_xampp
    install_squirrel
}

main