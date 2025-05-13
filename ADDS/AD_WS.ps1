# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 9
# Descripción:
# Instalación y configuración básica de Active Directory
# Se van a crear dos UO (Cuates | No cuates) y 
# un usuario en cada una
# Un dominio con dos equipos (Linux | Windows)
Import-Module .\WS.psm1 -Force

InstalarADDS
nuevoUsuarioAD -Dominio $Dominio
