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

    Write-Host "Mascara de Subred configurada automáticamente..."
    Write-Host "Servidor DNS asignado automáticamente..."

    # Configurar IP en la interfaz de red
    $PrefijoRed = CalcularMascara -Ip $Ip
    if ($PrefijoRed -ne $null) {
        New-NetIPAddress -IPAddress $Ip -PrefixLength $PrefijoRed -DefaultGateway $PuertaEnlace -InterfaceIndex 6
        Set-DnsClientServerAddress -InterfaceIndex 6 -ServerAddresses "8.8.8.8"
        Get-NetIPAddress -IPAddress $Ip
        Write-Host "Configuración de red aplicada correctamente"

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
        Write-Host " [1] Ejemplo"
        Write-Host " [2] Ejemplo"
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


function Instalacion{
    param (
        [String] $url,
        [String] $NomZip
    )
    # La carpeta servidor sera para almacenar los .zip de los servidores
    if(!(test-path 'C:\Servidor'))
    {
        mkdir 'C:\Servidor'
    }

    $Salida = "C:\Servidor\$NomZip.zip"
    
    # Iniciar la instalación
    If(!(Test-Path $Salida))
    {
        $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    
        try {
            Invoke-WebRequest -Uri $($Servidores.EnlaceLTS) -UserAgent $userAgent -OutFile $Salida -ErrorAction Stop
            Write-Output "Descarga exitosa."
        } catch {
            Write-Output "Error: $_"
        }
    }
    # Descomprimimos 
    Expand-Archive -LiteralPath $Salida -DestinationPath C:\ -Force


    # Nos dirigimos a la carpeta que contiene el ejecutable
    cd C:\Apache24\bin
    try 
    {
        .\httpd.exe

        Write-Host "Instalación completa"
        Write-Host "http://localhost/"
    }
    catch 
    {
        Write-Host "Ocurrió un error en la instalación"
    }
    

}


function MenuDescarga {
    param (
        [INT] $opc, [array] $Servidores
    )
    $ServidorActual = $Servidores[0]
    $ServidorActual
    while ($true)
    {
        Write-Host "====== DESCARGAS DISPONIBLES ======"
        Write-Host " [1] $($ServidorActual.NombreLTS)"
        Write-Host " [2] $($ServidorActual.NombreDEV)"
        $X = Read-Host "Seleccione una opción"
        if ($X -eq 1)
        {
            DescargarHTML -url $($ArchivoActual.EnlaceLTS)
            Write-Host "Debug MSJ PRE Enlace actual $($ServidorActual.EnlaceLTS)"

            # Encontramos el url de descarga
            $urlDescarga = EncontrarLink -NomArchivo "html.txt" -PatronRegex $($ServidorActual.PatronLTS) 
            $urlFinal = "$($ServidorActual.EnlaceLTS)$urlDescarga"
            
            # Editamos el "record" para que en el enlace almacene el link de descarga directamente
            $ServidorActual.EnlaceLTS = "$urlFinal"
            
            Write-Host "Debug MSJ POST Enlace actual $($ServidorActual.EnlaceLTS)"
            #Descargar -Url $($ServidorActual.EnlaceLTS) -Salida "c:\$($ServidorActual.NombreLTS)"

        }
        elseif ($X -eq 2)
        {

        }
        else 
        {
            Write-Host "Seleccione una opción valida"
            Read-Host "Presione una tecla para volver a intentarlo"    
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

function ActualizarDatos {
    param (
        [Array] $Array
    )

    foreach($Elemento in $Array)
    {
        # Meter la validación de que si tiene version DEV o nel
        <#
            Aqui
        #>
        DescargarHTML -url $($Elemento.EnlaceLTS)
        $Link = EncontrarLink -NomArchivo "html.txt" -PatronRegex $($Elemento.PatronLTS)
        $Link = "$($Elemento.EnlaceLTS)$Link"
        $Elemento.EnlaceLTS = $Link

        $Version = ExtraerVersion -urlDescarga $($Elemento.EnlaceLTS) -Patron $($Elemento.PatronVersion)
        $Elemento.VersionLTS = $Version

        # Depuración shit
    }
}