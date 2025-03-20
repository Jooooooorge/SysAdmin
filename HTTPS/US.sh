#!/bin/bash

# Importar funciones desde el archivo de funciones
source ./HTTP_US.sh

clear

echo "Seleccione el servicio que desea gestionar:"
echo "[1] Apache"
echo "[2] Tomcat"
echo "[3] Nginx"
read -p "Seleccione una opción: " service_option
validate_option $service_option 1 3

case $service_option in
    1) service_name="apache2" ;;
    2) service_name="tomcat10" ;;
    3) service_name="nginx" ;;
esac

clear
echo "¿Qué acción desea realizar?"
echo "1.- Instalar servicio"
echo "2.- Desinstalar servicio"
read -p "Ingrese el número de la opción: " action_option
validate_option $action_option 1 2

if [ "$action_option" -eq 1 ]; then
    echo "Seleccione la versión a instalar:"
    echo "1.- Versión estable"
    echo "2.- Versión en desarrollo (beta)"
    read -p "Ingrese el número de la opción: " version_option
    validate_option $version_option 1 2

    if [ "$version_option" -eq 1 ]; then
        version_type="estable"
    else
        version_type="beta"
    fi

    determine_versions $service_name
    selected_version=$([ "$version_type" == "estable" ] && echo "$stable_version" || echo "$beta_version")

    read -p "Ingrese el puerto para configurar el servicio: " port
    validate_port $port

    install_service $service_name $selected_version $port
    echo "$service_name ha sido instalado y configurado correctamente en el puerto $port."

elif [ "$action_option" -eq 2 ]; then
    uninstall_service $service_name
    echo "$service_name ha sido desinstalado correctamente."
fi

