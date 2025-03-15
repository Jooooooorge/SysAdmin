#********************************************************************************************************************************
# Declaración de las funciones necesarias para le uso de los scripts

# Función usada para configurar la red estatica
function ConfigurarIpEstatica {
    # Capturar IP
    while ($true) {
        $Ip = Read-Host "Ingrese la dirección IP"
        if (ValidarIp -Ip $Ip) {
            Write-Host "Dirección IP capturada correctamente"
            break
        } else {
            Write-Host "Error: La dirección IP ingresada no es válida. Intente nuevamente."
        }
    }

    # Capturar Gateway 
    while ($true) {
        $SegRed = ExtraerSegmento -Ip $Ip
        $PuertaEnlace = "$SegRed.1"
        Write-Host 'Puerta de enlace predeterminada:' $PuertaEnlace
        $Opc = Read-Host "¿Desea cambiarla? [y/n]"
        
        if ($Opc.ToLower() -eq 'y') {
            while ($true) {
                $PuertaEnlace = Read-Host "Ingrese el nuevo gateway"
                if (ValidarIp -Ip $PuertaEnlace) {
                    Write-Host "Gateway capturado correctamente"
                    break
                } else {
                    Write-Host "Error: La dirección de gateway no es válida. Intente nuevamente."
                }
            }
        }
        break
    }
    # Configurar IP en la interfaz de red
    $PrefijoRed = CalcularMascara -Ip $Ip
    if ($PrefijoRed -ne $null) {
        New-NetIPAddress -IPAddress $Ip -PrefixLength $PrefijoRed -DefaultGateway $PuertaEnlace -InterfaceIndex 6
        Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses "8.8.8.8"
        Write-Host "Configuración de red aplicada correctamente"
        Restart-NetAdapter -InterfaceIndex 6


    } else {
        Write-Host "Error: No se pudo calcular la máscara de subred. Verifique la IP ingresada."
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
        $opc = Read-Host "Selecciona un servidor"
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
        
        $X = Read-Host "Seleccione una opción"
        Write-Host "Seleccionado: $($ServidorActual.NombreLTS) --Version $($ServidorActual.VersionLTS)"
        $Port = Read-Host "Elige un puerto para instalar"
        
        <#
            Meter validación para impedir que puedas pedir que se pida la versión DEV con apache
            Podría ser al momento de verificar que el nombre de la versión exista y después llamar
            a la instalación
        #>
        if ($X -eq 1)
        {
            Instalacion -url $ServidorActual.EnlaceLTS -NomZip $ServidorActual.NombreLTS -opc $opc
            break
        }
        elseif ($X -eq 2)
        {
            if($($ServidorActual.NombreDEV -ne $null))
            {
                Instalacion -url $ServidorActual.EnlaceDEV -NomZip $ServidorActual.NombreDEV -opc $opc
                break
            }
            else 
            {
                Write-Host "Este servidor no cuenta con versión de Desarollo"
                Write-Host "Selecciona una opción valida...."
            }

        }
        else 
        {
            Write-Host "Seleccione una opción valida"
            Read-Host "Presione una tecla para volver a intentarlo"
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
        [int] $opc
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

    
    # Nos dirigimos a la carpeta que contiene el ejecutable
    switch ($opc) {
        # Instalar Apache
        0 {
            
            cd C:\Apache24\bin
            try {
                .\httpd.exe -k install
                Start-Service -Name Apache2.4
                Write-Host "Instalación completa"
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
                    start nginx
                    Write-Host "Nginx iniciado correctamente."
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
                    start nginx
                    Write-Host "Nginx iniciado correctamente."
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

