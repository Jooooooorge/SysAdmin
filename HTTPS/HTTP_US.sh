P    fi
}

# Función para validar opciones del menú
function validate_option() {
    local option=$1
    local min=$2
    local max=$3

    if ! [[ "$option" =~ ^[0-9]+$ ]] || [ "$option" -lt "$min" ] || [ "$option" -gt "$max" ]; then
        echo "Opción no válida. Ingrese un número entre $min y $max."
        exit 1
    fi
}

# Función para instalar y configurar el servicio seleccionado
function install_service() {
    local service_name=$1
    local version=$2
    local port=$3

    validate_port $port

    sudo apt update
    sudo apt install -y $service_name=$version

    if [[ $? -ne 0 ]]; then
        echo "Error al instalar $service_name. Verifique el nombre del paquete y la versión."
        exit 1
    fi

    # Configuración del puerto según el servicio
    if [[ "$service_name" == "apache2"* ]]; then
        sudo sed -i "s/^Listen [0-9]\+/Listen $port/" /etc/apache2/ports.conf
        sudo sed -i "s/<VirtualHost \*:80>/<VirtualHost *:$port>/g" /etc/apache2/sites-available/000-default.conf
        sudo systemctl restart apache2

    elif [[ "$service_name" == "nginx"* ]]; then
        config_file="/etc/nginx/sites-available/default"

        if grep -q "listen [0-9]\+;" "$config_file"; then
            sudo sed -i "s/listen [0-9]\+/listen $port/" "$config_file"
        else
            sudo sed -i "/server_name _;/a \    listen $port;" "$config_file"
        fi

        sudo systemctl restart nginx

    elif [[ "$service_name" == "tomcat"* ]]; then
        sudo sed -i "s/port=\"[0-9]\+\"/port=\"$port\"/g" /etc/tomcat*/server.xml
        sudo systemctl restart tomcat*
    fi
}

# Función para desinstalar un servicio
function uninstall_service() {
    local service_name=$1

    sudo apt remove --purge -y $service_name

    if [[ $? -ne 0 ]]; then
        echo "Error al desinstalar $service_name."
        exit 1
    else
        echo "$service_name se ha desinstalado correctamente."
    fi
}
