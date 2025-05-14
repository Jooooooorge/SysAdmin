# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 9
# Descripción:
# Instalación y configuración básica de Active Directory
# Se van a crear dos UO (Cuates | No cuates) y 
# un usuario en cada una
# Un dominio con dos equipos (Linux | Windows)
Import-Module .\WS.psm1 -Force

function main {
    InstalarADDS -Dominio "diadelnino" -NetBiosName "DANONINO"
    ConfigADDS -Name1 "Grupo1" -Name2 "Grupo2"
    AddUserStatic -Dominio "diadenino" -Nombre "Jorge" -Contraseña "Jorge123$" -Grupo "Grupo1"
    AddUserStatic -Dominio "diadenino" -Nombre "Sebas" -Contraseña "Sebas123$" -Grupo "Grupo2"
}