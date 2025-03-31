# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 8
# Descripción:
# Hacer el script para generar un servidor de correos que utilice SMTP y POP3, 
# como cliente se utlizara Mutt, SquirellMail u otra opción

# Importar las funciones necesarias
Import-Module .\F_SMTP_WS.psm1 -Force

# Variables 
$MailEnablePath = "C:\Program Files (x86)\Mail Enable\BIN"
$PostOffice = "midominio.local"
$Domain = "midominio.local"

# Configurar mi DNS
# *****************
configDNS

# Llamar a la función para crear el servidor de correo
installSMTP 
configSMTP -MailEnablePath $MailEnablePath -PostOffice $PostOffice -Domain $Domain

while ($true)
{
    $opc = mostrarMenu
    if ($opc -eq 1)
    {
        while ($true)
        {
            write-Host "Ingresa un nombre de usuario:"
            $User = read-host
            if (checkUser -User $User)
            {
                break;
            }
        }

        while ($true)
        {
            write-Host "Ingresa una contraseña:"
            $Password = read-host
            if (checkPassword -User $Password)
            {
                break;
            }
        }
        
        addUser -MailEnablePath $MailEnablePath -PostOffice $PostOffice -User $User -Password $Password
    }
    elseif ($opc -eq 2)
    {
        return 1 
    }
    else
    {
        Write-Host "Opción invalida" -ForegroundColor Red
    }
}
