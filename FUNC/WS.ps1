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
s
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


# Función para imprimir menu FTP
<# function ImprimirMenu {
    write-host"==========================="
    write-host"=======SERVICIO FTP======="
    Write-Host"[1] Iniciar Sesión"
    Write-Host"[2] Agregar Usuario"
    Write-host"[3] Editar Usuario"
    Write-Host"[4] Salir"
    $opc = Read-Host "Selecciona una opción:"

    switch ($opc)
    {
        1{ }
        2{ }
        3{ }
        4{ Return 0 }
        
        default{}
    }
} #>


