#!/bin/bash

function mostrarMenu()
{
    echo " ===== USUARIOS SERVIDOR CORREO ====="
    echo " [1] Agregar usuario"
    echo " [2] Eliminar usuario"
    echo " Selecciona una opción:"
    read -p " Selecciona una opción:" opc

    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -eq 1 ]; then
        echo "$opc"
    else
        echo "Opción invalida, seleccione de nuevo:"
    fi

}

