#!/bin/bash
# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 8
# Descripción:
# Hacer el script para generar un servidor de correos que utilice SMTP y POP3, 
# como cliente se utlizara Mutt, SquirellMail u otra opción

# Importar funciones
# source ./F_SMTP_US.sh
source ../FUNC/F_SMTP_US.sh

while true; do
    echo " ===== USUARIOS SERVIDOR CORREO ====="
    echo " [1] Agregar usuario"
    read -p "Presione 1" opc

    if [[ "$opc" =~ ^[0-9]+$ ]] && [ "$port" -eq 1 ]; then
        echo " LLAMADA A LA FUNCIÖN PARA CREAR USUARIO"
        break
    else
        echo "opción invalida, escoje de nuevo"
    fi
done
