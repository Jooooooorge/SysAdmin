#********************************************************************************************************************************
# Declaración de las funciones necesarias para le uso de los scripts

# Función usada para configurar la red estatica
# Entrada: 
# Salida: Arreglo con las datos necesarios para la configuración
function StaticIpConfig
{
    # Capturar IP
    while ($true){
        $IpAddress = Read-Host "Ingrese la dirección IP"
        if(ValidateIpAddress -IpAddress $IpAddres)
        {
            Write-Host 'Dirección IP capturado correcatemente'
            break
        } 
        else 
        {
            Write-Output "Error: La dirección IP no es válida. Intente nuevamente."
        }
    }
    # Capturar Gateway 
    while ($true){
        $GateWay = ExtractNetSegment -IpAddress $IpAddress+".1"
        Write-Output = "Puerta de enlace pedreterminada("+$GateWay+")"
        $opt = Read-Host "Desea cambiarla? [y] [n]:"
        while($opt.ToLower() -eq 'y')
        {
            $GateWay = Read-Host "Ingrese el nuevo gateway:"
            if (ValidateIpAddress -IpAddress $GateWay)
            {
                Write-Host 'Gateway capturado correcatemente'
                break
            }else 
            {
                Write-Host "Error: La dirección de gateway no es válida. Intente nuevamente."
            }
        }    
    }
    Write-Host "Mascara de Subred configurada automaticamente...´n
    Servidor DNS asignado automaticamente..."
    New-NetIPAddress -IPAddress $IpAddress -PrefixLength CalculateNetMask -IPAddress $IpAddress -DefaultGateway $GateWay
    Set-DnsClientDohServerAddress -InterfaceIndex 4 -ServerAddress ("8.8.8.8") 
    Write-Host "Configuración de red configurada correctamente"
    Get-NetIpAddress -IPAddress $IpAddress
}

function ExtractNetSegment
{
    param 
    (
        [String] $IpAddress
    )
    $Seg = $IP.Split(".")
    return $seg[0]+"."+$seg[1]+"."+$seg[2]
}

function CalculateNetMask
{
    param 
    (
        [String] $IpAddress
    )
    $Seg = $IP.Split(".")
    $NetSegment = $seg[0].ToInt16()
    switch($NetSegment)
    {
        0..127 {$NetPrefix = 8}
        128..191 {$NetPrefix = 16}
        192..255 {$NetPrefix = 24}
    }
    Return $NetPrefix

}
function ValidateIpAddress
{
    param(
        [String] $IpAddress
    )
    # Patrón para validar que la cadena cumple con una ip
    $Pattern = '((25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?))$'  
    return $IpAddress -match $Pattern
    
}

function ValidateDomain
{
    param (
        [String] $Domain
    )
    $Pattern = '(^(([a-z]{2,})+\.)+([a-z]{2,})+)$'

    return $Domain.ToLower() -match $Pattern
}




