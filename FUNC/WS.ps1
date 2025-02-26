#********************************************************************************************************************************
# Declaración de las funciones necesarias para le uso de los scripts

# Función usada para configurar la red estatica
# Entrada: 
# Salida: Arreglo con las datos necesarios para la configuración
function StaticIpConfig {
    # Capturar IP
    while ($true) {
        $IpAddress = Read-Host "Ingrese la dirección IP"
        if (ValidateIpAddress -IpAddress $IpAddress) {
            Write-Host "Dirección IP capturada correctamente"
            break
        } else {
            Write-Host "Error: La dirección IP ingresada no es válida. Intente nuevamente."
        }
    }

    # Capturar Gateway 
    while ($true) {
        $NetSegment = ExtractNetSegment -IP $IpAddress
        $GateWay = "$NetSegment.1"
        Write-Host 'Puerta de enlace predeterminada:' $GateWay
        $opt = Read-Host "¿Desea cambiarla? [y/n]"
        
        if ($opt.ToLower() -eq 'y') {
            while ($true) {
                $GateWay = Read-Host "Ingrese el nuevo gateway"
                if (ValidateIpAddress -IpAddress $GateWay) {
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
    $NetPrefix = CalculateNetMask -IP $IpAddress
    if ($NetPrefix -ne $null) {
        New-NetIPAddress -IPAddress $IpAddress -PrefixLength $NetPrefix -DefaultGateway $GateWay -InterfaceIndex 6
        Set-DnsClientServerAddress -InterfaceIndex 4 -ServerAddresses "8.8.8.8"
        Write-Host "Configuración de red aplicada correctamente"
        Get-NetIPAddress -IPAddress $IpAddress
    } else {
        Write-Host "Error: No se pudo calcular la máscara de subred. Verifique la IP ingresada."
    }
}

# Función para extraer el segmento de red de una IP
function ExtractNetSegment {
    param ([String] $IP)
    $Seg = $IP.Split(".")
    return "$($Seg[0]).$($Seg[1]).$($Seg[2])"
}

# Función para calcular la máscara de subred en formato de prefijo (CIDR)
function CalculateNetMask {
    param ([String] $IP)
    $Seg = $IP.Split(".")
    $NetSegment = $Seg[0] -as [int]  # Convertir a número

    switch ($NetSegment) {
        {$_ -ge 0 -and $_ -le 127} { return 8 }   # Clase A
        {$_ -ge 128 -and $_ -le 191} { return 16 } # Clase B
        {$_ -ge 192 -and $_ -le 223} { return 24 } # Clase C
        default { return $null }  # IP no válida
    }
}

# Función para validar una dirección IP
function ValidateIpAddress {
    param ([String] $IpAddress)
    $Pattern = '^(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)$'
    return $IpAddress -match $Pattern
}

# Función para validar un dominio
function ValidateDomain {
    param ([String] $Domain)
    $Pattern = '(^(([a-z]{2,})+\.)+([a-z]{2,})+)$'
    return $Domain.ToLower() -match $Pattern
}