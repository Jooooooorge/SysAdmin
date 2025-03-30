#!/bin/bash
###############################################################################
# MENÚ PRINCIPAL que invoca:
#  1) sslUbuntu.sh -> Función principal supuesta: Mostrar_Menu_Instalacion
#  2) ubuntuconFTP.SH -> Función principal supuesta: shown_main_menu
###############################################################################

while true; do
    clear
    echo "=========================================="
    echo "       MENÚ PRINCIPAL - Mis Scripts"
    echo "=========================================="
    echo "1) Ejecutar sslUbuntu.sh (Mostrar_Menu_Instalacion)"
    echo "2) Ejecutar ubuntuconFTP.SH (shown_main_menu)"
    echo "3) Salir"
    echo "=========================================="
    read -p "Seleccione una opción (1-3): " opcion

    case "$opcion" in
        1)
            echo "Cargando (source) sslUbuntu.sh..."
            source sslUbuntu.sh  # Ajusta la ruta si no está en la misma carpeta
            # Comprueba si la función 'Mostrar_Menu_Instalacion' existe
            if declare -f Mostrar_Menu_Instalacion > /dev/null; then
                # Llamamos a la función principal
                Mostrar_Menu_Instalacion
            else
                echo "Error: La función 'Mostrar_Menu_Instalacion' no se encontró en sslUbuntu.sh."
                echo "Revisa el nombre de la función."
            fi
            ;;
        2)
            echo "Cargando (source) ubuntuconFTP.SH..."
            source ubuntuconFTP.SH  # Ajusta la ruta o nombre si difiere
            # Comprueba si la función 'shown_main_menu' existe
            if declare -f shown_main_menu > /dev/null; then
                shown_main_menu
            else
                echo "Error: La función 'shown_main_menu' no se encontró en ubuntuconFTP.SH."
                echo "Revisa el nombre de la función."
            fi
            ;;
        3)
            echo "Saliendo del menú principal."
            exit 0
            ;;
        *)
            echo "Opción inválida. Por favor, seleccione 1, 2 o 3."
            ;;
    esac

    read -p "Presione Enter para volver al menú..."
done
