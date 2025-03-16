#********************************************************************************************************************************
# Declaración de las funciones necesarias para le uso de los scripts

# Función usada para configurar la red estatica
function ConfigurarIpEstatica {
    # Capturar IP
    while ($true) {
        $Ip = Read-Host "Ingrese la dirección IP"
        if (ValidarIp -Ip $Ip) {
            break
        }
    }

    # Capturar Gateway 
    while ($true) {
        $SegRed = ExtraerSegmento -Ip $Ip
        $PuertaEnlace = "$SegRed.1"
        $Opc = Read-Host "¿Desea cambiar la puerta de enlace? [y/n]"
        
        if ($Opc.ToLower() -eq 'y') {
            while ($true) {
                $PuertaEnlace = Read-Host "Ingrese el nuevo gateway"
                if (ValidarIp -Ip $PuertaEnlace) {
                    break
                }
            }
        }
        break
    }

    # Configurar IP en la interfaz de red
    $PrefijoRed = CalcularMascara -Ip $Ip
    if ($PrefijoRed -ne $null) {
        New-NetIPAddress -IPAddress $Ip -PrefixLength $PrefijoRed -DefaultGateway $PuertaEnlace -InterfaceIndex 6 -ErrorAction SilentlyContinue
        Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses "8.8.8.8" -ErrorAction SilentlyContinue
        Restart-NetAdapter -Name "Ethernet" -ErrorAction SilentlyContinue
    }
}

# Función para extraer el segmento de red de una IP
function ExtraerSegmento {
    param ([String] $Ip)
    $Seg = $Ip.Split(".")
    return "$($Seg[0]).$($Seg[1]).$($Seg[2])"
}

# Función para calcular la máscara de subred en formato de prefijo (CIDR)
function CalcularMascara {
    param ([String] $Ip)
    $Seg = $Ip.Split(".")
    $SegRed = $Seg[0] -as [int]  # Convertir a número
    switch ($SegRed) {
        {$_ -ge 0 -and $_ -le 127} { return 8 }   # Clase A
        {$_ -ge 128 -and $_ -le 191} { return 16 } # Clase B
        {$_ -ge 192 -and $_ -le 223} { return 24 } # Clase C
        default { return $null }  # IP no válida
    }
}

# Función para validar una dirección IP
function ValidarIp {
    param ([String] $Ip)
    $Patron = '^(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)$'
    return $Ip -match $Patron
}

# Función para validar un dominio
function ValidarDominio {
    param ([String] $Dominio)
    $Patron = '(^(([a-z]{2,})+\.)+([a-z]{2,})+)$'
    return $Dominio.ToLower() -match $Patron
}

# ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ====== ======
# HTTPS Typo
function MenuServidores {
    while ($true)
    {
        Write-Host " ========= ========= ========="
        Write-Host " SERVIDOES WEB DISPONIBLES"
        Write-Host " [0] Apache"
        Write-Host " [1] Nginx"
        Write-Host " [2] ISS"
        Write-Host "Selecciona un servidor:"
        $opc = Read-Host 
        if(($opc -eq 0) -or ($opc -eq 1) -or ($opc -eq 2) )
        {
            Return $opc
        }
        else
        {
            Write-Host "Opción no valida, vuelva a intentarlo..."    
        }
    }
}

function MenuDescarga {
    param (
        [INT] $opc, [array] $Servidores
    )
    $ServidorActual = $Servidores[$opc]
    $ServidorActual
    while ($true)
    {
        Write-Host "====== DESCARGAS DISPONIBLES ======"
        Write-Host "$($ServidorActual.NombreLTS) $($ServidorActual.VersionLTS)"
        Write-Host "$($ServidorActual.NombreDEV) $($ServidorActual.VersionDEV)"

        <#elseif($opc = 1)
        {
            Write-Host " [1] $($ServidorActual.NombreLTS) --Version $($ServidorActual.VersionLTS)"
            Write-Host " [2] $($ServidorActual.NombreDEV) --Version $($ServidorActual.VersionDEV)"
        }#>
        
        Write-Host "Seleccione una opción:" 
        $X = Read-Host 
        Write-Host "Seleccionado: $($ServidorActual.NombreLTS) --Version $($ServidorActual.VersionLTS)"

        # Solicitar el puerto y validar que no este en uso
        while ($true)
        {
            Write-Host "Elige un puerto para instalar:" 
            $Puerto = Read-Host 
            if(!(ProbarPuerto -Puerto $Puerto))
            {
                Break
            }
            else
            {
                Write-Host "El puerto ya esta en uso"
                Write-Host "Seleccione un puerto valido"
            }
            
        }

        if ($X -eq 1)
        {
            Instalacion -url $ServidorActual.EnlaceLTS -NomZip $ServidorActual.NombreLTS -opc $opc
            break
        }
        elseif ($X -eq 2)
        {
            if($($ServidorActual.NombreDEV -ne "N/A"))
            {
                Instalacion -url $ServidorActual.EnlaceDEV -NomZip $ServidorActual.NombreDEV -opc $opc
                break
            }
            else 
            {
                Write-Host "Este servidor no cuenta con versión de Desarollo"
                Write-Host "Selecciona una versión valida...."
            }

        }
        else 
        {
            Write-Host "Seleccione una opción valida"
            Read-Host "Selecciona una opción valida...."
        }
    }
}

function ActualizarDatos {
    param (
        [Array] $Array
    )

    $opc = 0
    foreach($Elemento in $Array)
    {
        # Meter la validación de que si tiene version DEV o nel
        <#
            Aqui
        #>
        if ($opc -eq 0)
        {
            # Actualizar datos Apache
            DescargarHTML -url $($Elemento.EnlaceLTS)
            $Link = EncontrarLink -NomArchivo "html.txt" -PatronRegex $($Elemento.PatronLTS)
            $Link = "$($Elemento.EnlaceLTS)$Link"
            $Elemento.EnlaceLTS = $Link

            $Version = ExtraerVersion -urlDescarga $($Elemento.EnlaceLTS) -Patron $($Elemento.PatronVersion)
            $Elemento.VersionLTS = $Version
        } 
        elseif ($opc -eq 1) 
        {
            # Actualizar dato Nginx
            DescargarHTML -url $($Elemento.EnlaceLTS)
            $Link = EncontrarLinkDEV -NomArchivo "html.txt" -PatronRegex $($Elemento.PatronLTS)
            $LinkSinExtension = $($Elemento.EnlaceLTS) 
            $LinkSinExtension = $LinkSinExtension -replace "\.html", ""
            $LinkSinExtension = $LinkSinExtension -replace "\/en", ""
            $Version = ExtraerVersion -urlDescarga $Link -Patron $($Elemento.PatronVersion)
            $Elemento.VersionLTS = $Version
            $Elemento.EnlaceLTS = "$LinkSinExtension/nginx-$Version.zip"

            #Version DEV
            $Link = ""
            $LinkSinExtension = ""
            $Version = ""

            $Link = EncontrarLink -NomArchivo "html.txt" -PatronRegex $($Elemento.PatronDEV)
            $LinkSinExtension = $($Elemento.EnlaceDEV)
            $LinkSinExtension = $LinkSinExtension -replace "\.html", ""
            $LinkSinExtension = $LinkSinExtension -replace "\/en", ""
            $Version = ExtraerVersion -urlDescarga $Link -Patron $($Elemento.PatronVersion)
            $Elemento.VersionDEV = $Version
            $Elemento.EnlaceDEV = "$LinkSinExtension/nginx-$Version.zip"

1
        }
        <#elseif ($opc -eq 2) 
        {
            DescargarHTML -url $($Elemento.EnlaceLTS)
            $Link = EncontrarLink -NomArchivo "html.txt" -PatronRegex $($Elemento.PatronLTS)
            $Link = "$($Elemento.EnlaceLTS)$Link.zip"
            $Elemento.EnlaceLTS = $Link

            $Version = ExtraerVersion -urlDescarga $($Elemento.EnlaceLTS) -Patron $($Elemento.PatronVersion)
            $Elemento.VersionLTS = $Version
        }#>
        
        $opc++
    }
}

function DescargarHTML {
    Param([String] $url)
    if (test-path "./html.txt")
    {
        rm html.txt
    }
    $Archivo = "html.txt"

    # Configurar opciones para Invoke-WebRequest
    $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    

    try {
        # Descargar el contenido de la página
        $response = Invoke-WebRequest -Uri $url -UserAgent $userAgent -Headers $headers -UseBasicParsing -ErrorAction Stop
        $response.Content > $Archivo
        Write-Output "HTML descargado correctamente en $Archivo."
    } catch {
        Write-Output "Error al descargar el HTML: $_"
    }
}


function EncontrarLink {
    param (
        [String] $NomArchivo,
        [String] $PatronRegex
    )

    # Nos aseguramos que la variable automatica este limpia
    $Matches = $null # Devuelve las cadenas que coincide con el patrón
    try {
        $Archivo = Get-Content ".\$NomArchivo" -ErrorAction Stop
        foreach ($Line in $Archivo) {
            if ($Line -match $PatronRegex) {
                return $Matches[0]
            }
        }
        # Si no retorna ningún match, no se encontraron coincidencias
        Write-Output "No se encontró ninguna coincidencia."
        return $null
    } catch {
        Write-Output "Error al leer el archivo: $_"
    }    
    
}

function ProbarPuerto {
    param (
        [String] $Puerto
    )
    $connection = Get-NetTCPConnection -LocalPort $Puerto -ErrorAction SilentlyContinue

    if ($connection) {
        Write-Output $true  
    } else {
        Write-Output $false 
    }
}
function EncontrarLinkDEV {
    param (
        [String] $NomArchivo,
        [String] $PatronRegex
    )
    # En este caso tenemos multiples versiones, así que vamos a buscar la 2da
    $coincidencias = @()
    # Nos aseguramos que la variable automatica este limpia
    $Matches = $null # Devuelve las cadenas que coincide con el patrón
    try {
        $Archivo = Get-Content ".\$NomArchivo" -Raw -ErrorAction Stop  # Leer el archivo como un solo bloque
        if ($Archivo -match $PatronRegex) {
            $coincidencias = [regex]::Matches($Archivo, $PatronRegex) | ForEach-Object { $_.Value }
        }

        # Verificar si hay al menos dos coincidencias y devolver la segunda
        if ($coincidencias.Count -ge 2) {
            return $coincidencias[1]
        } else {
            Write-Output "No se encontró una segunda coincidencia."
            return $null
        }
    } catch {
        Write-Output "Error al leer el archivo: $_"
    }
    
}


function Instalacion {
    param (
        [String] $url,
        [String] $NomZip,
        [int] $opc,
        [String] $Puerto
    )

    # La carpeta Servidor será para almacenar los .zip de los servidores
    if (!(Test-Path 'C:\Servidor')) {
        mkdir 'C:\Servidor'
    }

    # Proceso para la instalación
    write-Host "Url: $url"
    Write-Host "Creación de la ruta del zip"
    $Salida = "C:\Servidor\$NomZip.zip"

    # Iniciar la instalación
    if (!(Test-Path $Salida)) {
        $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

        try {
            Write-Host "Se realiza la petición"
            Invoke-WebRequest -Uri $url -UserAgent $userAgent -OutFile $Salida -ErrorAction Stop
            Write-Output "Descarga exitosa."
        } catch {
            Write-Output "Error: $_"
            return  # Salir de la función si hay un error en la descarga
        }
    }
    Expand-Archive -LiteralPath $Salida -DestinationPath "C:\" -Force
    # Configurar el firewall
    if (!(Get-NetFirewallRule -Name $NomZip -ErrorAction SilentlyContinue ))
    {
        New-NetFirewallRule -Name $NomZip -DisplayName $NomZip -Protocol TCP -LocalPort $Puerto -Action Allow -Direction Inbound
    }
    
    # Nos dirigimos a la carpeta que contiene el ejecutable
    switch ($opc) {
        # Instalar Apache
        0 {
            
            cd C:\Apache24\bin
            try {
                .\httpd.exe -k install
                Start-Service -Name Apache2.4
                (Get-Content "C:\Apache24\bin\httpd.conf") -replace "Listen \d+", "Listen 0.0.0.0:$Puerto" | Set-Content "C:\Apache24\bin\httpd.conf"
                Write-Host "Instalación completa"

                # Prueba local de que si funciona
                [System.Diagnostics.Process]::Start("msedge", "http://localhost/")
            } catch {
                Write-Host "Ocurrió un error en la instalación de Apache: $_"
            }
        }

        # Instalar Nginx
        1 {
            if (Test-Path "C:\nginx-1.27.4") 
            {
                # Cambiar a la carpeta seleccionada
                cd "C:\nginx-1.27.4"

                # Iniciar Nginx
                try {
                    (Get-Content "C:\nginx-1.27.4\conf\nginx.conf") -replace "listen\s+\d+;", "listen 0.0.0.0:$Puerto;" | Set-Content "C:\nginx-1.27.4\conf\nginx.conf"   
                    start nginx
                    Write-Host "Nginx iniciado correctamente."
                    # Prueba local de que si funciona
                    [System.Diagnostics.Process]::Start("msedge", "http://localhost/")
                    Start-Sleep -Seconds 10
                    return

                } catch {
                    Write-Host "Error al iniciar Nginx: $_"
                }
            }
            elseif (Test-Path "C:\nginx-1.26.3")
            {
                # Cambiar a la carpeta seleccionada
                cd "C:\nginx-1.26.3"

                # Iniciar Nginx
                try {
                    (Get-Content "C:\nginx-1.26.3\conf\nginx.conf") -replace "listen\s+\d+;", "listen 0.0.0.0:$Puerto;" | Set-Content "C:\nginx-1.26.3\conf\nginx.conf"   
                    start nginx
                    Write-Host "Nginx iniciado correctamente."

                    # Prueba local
                    [System.Diagnostics.Process]::Start("msedge", "http://localhost/")
                    Start-Sleep -Seconds 10
                    return

                } catch {
                    Write-Host "Error al iniciar Nginx: $_"
                }
            } 
        }
    }
}


function ExtraerVersion {
    param (
        [String] $urlDescarga, [String] $Patron
    )
    
    if($urlDescarga -match $Patron)
    {
        return $Matches[0]
    }
}

