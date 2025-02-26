#********************************************************************************************************************************
# Declaración de las funciones necesarias para le uso de los scripts

# Función usada para configurar la red estatica
# Entrada: 
# Salida: Arreglo con las datos necesarios para la configuración
function StaticIpConfig
{
    # Capturar IP
    while (True){
        $IpAddress = Read-Host "Ingrese la dirección IP"
        if(ValidateIpAddress($IpAddress))
        {
            Write-Host 'Dirección IP capturado correcatemente'
            break
        } 
        else 
        {
            Write-Output "Ha ocurrido un error, vuelve a introducir la dirección IP"
        }
    }
    # Capturar Gateway 
    while (True){
        $GateWay = ExtractNetSegment($IpAddress)+"."+"1"
        Write-Output = "Puerta de enlace pedreterminada("+$GateWay+")"
        $opt = Read-Host "Desea cambiarla? [y] [n]:"
        while($opt.ToLower()=='y')
        {
            $GateWay = Read-Host "Ingrese el nuevo gateway:"
            if (ValidateIpAddress($GateWay))
            {
                Write-Host 'Gateway capturado correcatemente'
                break
            }
        }    
    }
    Write-Host "Mascara de Subred configurada automaticamente...´n
    Servidor DNS asignado automaticamente..."
    New-NetIPAddress -IPAddress $IpAddress -PrefixLength CalculateNetMask($IpAddress) -DefaultGateway $GateWay
    Set-DnsClientDohServerAddress -InterfaceIndex 4 -ServerAddress ("8.8.8.8") 
    Write-Host "Configuración de red configurada correctamente"
    Get-NetIpAddress -IPAddress $IpAddress
}

function ExtractNetSegment
{
    param 
    (
        [String] $IP
    )
    $Seg = $IP.Split(".")
    return $NetSegment = $seg[0]+"."+$seg[1]+"."+$seg[2]
}

function CalculateNetMask
{
    param 
    (
        [String] $IP
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
    $Pattern = '(^(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?))$'  
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




