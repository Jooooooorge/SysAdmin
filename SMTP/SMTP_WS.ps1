# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 8
# Descripción:
# Hacer el script para generar un servidor de correos que utilice SMTP y POP3, 
# como cliente se utlizara Mutt, SquirellMail u otra opción

# Importar las funciones necesarias
Import-Module .\F_SMTP_WS.psm1 -Force

# Llamar a la función para crear el servidor de correo
configSMTP
