function IIS {
    # Verificar si los módulos de IIS están instalados
    Write-Host "Verificando si los módulos de IIS están instalados..."
    Get-WindowsFeature -Name IIS

    # Instalar el servicio de Web Server (IIS)
    Write-Host "Instalando el servicio de Web Server (IIS)..."
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools

    # Importar el módulo WebAdministration
    Import-Module WebAdministration

    # Solicitar el puerto al usuario
    $port = Read-Host "¿Qué puerto desea usar para el sitio web? (por defecto: 80) "
    if (-not $port) {
        $port = 80
    }

    # Definir rutas de las carpetas
    $httpPath = "C:\HTTP"
    $pagePath = "$httpPath\Pagina"
    
    # Crear carpetas
    Write-Host "Creando las carpetas..."
    try {
        if (-not (Test-Path $httpPath)) {
            Write-Host "Creando la carpeta raíz del HTTP: $httpPath"
            New-Item -ItemType Directory -Path $httpPath -Force
        } else {
            Write-Host "La carpeta $httpPath ya existe."
        }

        if (-not (Test-Path $pagePath)) {
            Write-Host "Creando la carpeta de la página: $pagePath"
            New-Item -ItemType Directory -Path $pagePath -Force
        } else {
            Write-Host "La carpeta $pagePath ya existe."
        }
    } catch {
        Write-Host "[Error]. No se pudieron crear las carpetas: $_" -ForegroundColor Red
        return
    }

    # Crear un archivo HTML que redirija a la página de IIS Express
    $indexFilePath = "$pagePath\index.html"
    $contenidoHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Internet Information Services</title>
    <meta http-equiv="refresh" content="0; url=https://www.microsoft.com/en-us/download/details.aspx?id=48264" />
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            margin-top: 100px;
            background-color: #0072C6;
            color: white;
        }
        h1 {
            color: white;
        }
        p {
            margin: 20px;
        }
        .loader {
            border: 5px solid #f3f3f3;
            border-radius: 50%;
            border-top: 5px solid #3498db;
            width: 50px;
            height: 50px;
            animation: spin 2s linear infinite;
            margin: 20px auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <h1>Internet Information Services (IIS)</h1>
    <div class="loader"></div>
    <p>Redirigiendo a la página de descarga de IIS 10.0 Express...</p>
    <p>Si no es redirigido automáticamente, <a href="https://www.microsoft.com/en-us/download/details.aspx?id=48264" style="color: white;">haga clic aquí</a>.</p>
</body>
</html>
"@
    Set-Content -Path $indexFilePath -Value $contenidoHTML -Encoding UTF8

    try {
        # Comprobar si existe el sitio Default Web Site
        $defaultSite = Get-Website -Name "Default Web Site" -ErrorAction SilentlyContinue
        
        if ($defaultSite) {
            # Configurar el sitio predeterminado para usar el puerto especificado
            Write-Host "Configurando el sitio predeterminado en IIS..."
            
            # Detener el sitio si está en ejecución
            if ($defaultSite.State -eq "Started") {
                Stop-Website -Name "Default Web Site"
            }
            
            # Configurar el sitio predeterminado para apuntar a nuestra nueva página
            Set-ItemProperty -Path "IIS:\Sites\Default Web Site" -Name physicalPath -Value $pagePath
            Set-ItemProperty -Path "IIS:\Sites\Default Web Site" -Name bindings -Value @{protocol="http";bindingInformation="*:$($port):"}
            
            # Iniciar el sitio
            Start-Website -Name "Default Web Site"
            
            Write-Host "Sitio 'Default Web Site' configurado para usar el puerto $port" -ForegroundColor Green
        } else {
            # Crear un nuevo sitio web
            Write-Host "El sitio 'Default Web Site' no existe. Creando un nuevo sitio web 'Pagina'..."
            
            # Crear el nuevo sitio web
            New-Website -Name "Pagina" -PhysicalPath $pagePath -Port $port
            
            # Iniciar el sitio
            Start-Website -Name "Pagina"
            
            Write-Host "Sitio 'Pagina' creado y configurado para usar el puerto $port" -ForegroundColor Green
        }
    } catch {
        Write-Host "[Error]. No se pudo configurar el sitio en IIS: $_" -ForegroundColor Red
        return
    }

    # Crear regla de firewall
    Write-Host "Creando regla de firewall para el puerto $port..."
    try {
        New-NetFirewallRule -DisplayName "IIS-HTTP" -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -ErrorAction SilentlyContinue
    } catch {
        Write-Host "[Error]. No se pudo crear la regla de firewall: $_" -ForegroundColor Red
        return
    }

    # Verificar que el sitio esté corriendo
    Write-Host "Verificando que el sitio esté corriendo..."
    Get-Website | Where-Object { $.Name -eq "Default Web Site" -or $.Name -eq "Pagina" }
    
    Write-Host "IIS configurado correctamente en el puerto $port. Accede a http://localhost:$port/ para ver la página de descarga de IIS Express." -ForegroundColor Green
}

IIS