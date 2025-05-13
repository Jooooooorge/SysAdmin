# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 10
# Descripción:
<#
    1) Configurar el grupo 1 con horario de acceso de 8am a 3pm
    2) Configurar el grupo 2 con horario de acceso de 3pm a 2am
    3) Realizar la configuración necesaria para que los usuarios del grupo uno puedan almacenar en el servidor (no carpeta compartida) archivos por hasta 5 megas.
    4) Realizar la configuración necesaria para que los usuarios del grupo dos puedan almacenar en el servidor (no carpeta compartida) archivos por hasta 10 megas.
    5) Realizar la configuración para que el grupo 1 sólo pueda abrir el bloc de notas
    6) Realizar la configuración para que el grupo 2 sólo tenga bloqueado el bloc de notas
    7) Realizar configuración establecer política de contraseñas seguras, después de crear el usuario pedir cambio de contraseña en el siguiente login.
    8) Habilitar la auditoría de eventos para monitorear accesos y cambios dentro de active directory
    9) Implementar Autenticación Multifactor, con google authenticator para establecer más seguridad en el acceso de los usuarios
#>
Import-Module .\WS.psm1 -Force

InstalarADDS_Pro






