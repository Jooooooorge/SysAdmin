# Test for ValidateIpAddress
Import-Module .\WS.ps1 -Force

$Array = @(1,2,3,4,5)

$Array
function sumar1 {
    param (
        [Array] $Array
    )

    for($i = 0; $i -le 4; $i++)
    {
        $Array[$i]++
    }
    $Array
    $a = Read-Host "E"
}
sumar1 -Array $Array
$Array