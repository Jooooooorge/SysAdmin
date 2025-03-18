# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 6 
# Descripción:
# Dar la opción al usuario para elegir entre 3 servidores diferentes: Ejemplo
#
#    [1] Apache
#    [2] Tomcat
#    [3] IIS
#> 
#
#    Al seleccionar x opción se debera mostrar la ultima versión de la versión LTS y la versión de 
#    desarollo de cada uno
#    Apache
#    LTS 2.4.777
#    DEV 2.4.69
#>
source ./US.sh

#!/bin/bash

# Variables
declare -A Servidores
Servidores[0]="Apache"
Servidores[1]="Nginx"
Servidores[2]="IIS"

# Función para mostrar el menú de servidores
function MenuServidores {
    while true; do
        echo "========= ========= ========="
        echo "SERVIDORES WEB DISPONIBLES"
        echo "[0] Apache"
        echo "[1] Nginx"
        echo "[2] IIS"
        echo "Selecciona un servidor:"
        read -r opc
        if [[ $opc -ge 0 && $opc -le 2 ]]; then
            return $opc
        else
            echo "Opción no válida, vuelva a intentarlo..."
        fi
    done
}

# Función para mostrar el menú de descarga
function MenuDescarga {
    local opc=$1
    local ServidorActual=${Servidores[$opc]}

    while true; do
        echo "====== DESCARGAS DISPONIBLES ======"
        echo "1. $ServidorActual (LTS)"
        echo "2. $ServidorActual (DEV)"
        echo "Seleccione una opción:"
        read -r X

        # Solicitar el puerto y validar que no esté en uso
        while true; do
            echo "Elige un puerto para instalar:"
            read -r Puerto
            if ! ProbarPuerto $Puerto; then
                break
            else
                echo "ERROR: Seleccione un puerto válido"
            fi
        done

        if [[ $X -eq 1 ]]; then
            echo "Seleccionado: $ServidorActual (LTS)"
            Instalacion $opc $Puerto
            break
        elif [[ $X -eq 2 ]]; then
            echo "Seleccionado: $ServidorActual (DEV)"
            Instalacion $opc $Puerto
            break
        else
            echo "Seleccione una opción válida"
        fi
    done
}

# Función para probar si un puerto está en uso
function ProbarPuerto {
    local Puerto=$1
    if netstat -tuln | grep -q ":$Puerto "; then
        return 1  # Puerto en uso
    else
        return 0  # Puerto disponible
    fi
}

# Función para instalar el servidor seleccionado
function Instalacion {
    local opc=$1
    local Puerto=$2

    case $opc in
        0)  # Instalar Apache
            echo "Instalando Apache..."
            sudo apt-get update
            sudo apt-get install -y apache2
            sudo sed -i "s/Listen 80/Listen $Puerto/" /etc/apache2/ports.conf
            sudo systemctl restart apache2
            echo "Apache instalado y configurado en el puerto $Puerto."
            ;;
        1)  # Instalar Nginx
            echo "Instalando Nginx..."
            sudo apt-get update
            sudo apt-get install -y nginx
            sudo sed -i "s/listen 80/listen $Puerto/" /etc/nginx/sites-available/default
            sudo systemctl restart nginx
            echo "Nginx instalado y configurado en el puerto $Puerto."
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac
}

# Función principal
function main {
    while true; do
        MenuServidores
        opc=$?
        MenuDescarga $opc
    done
}

# Ejecutar la función principal
main