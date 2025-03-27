#********************************************************************************************************************************
# Declaración de las funciones necesarias para el uso de los scripts

# Función usada para configurar la red estática
# Entrada: 
# Salida: Arreglo con los datos necesarios para la configuración
StaticIpConfig() {
    # Capturar IP
    while true; do
    read -p "Ingrese la dirección IP: " IpAddress
    if ValidateIpAddress "$IpAddress"; then
        echo "Dirección IP capturada correctamente"
        break
    else
        echo "Error: La dirección IP ingresada no es válida. Intente nuevamente."
    fi
    done

    # Capturar Gateway 
    while true; do
        NetSegment=$(ExtractNetSegment "$IpAddress")
        GateWay="$NetSegment.1"
        echo "Puerta de enlace predeterminada: $GateWay"
        read -p "¿Desea cambiarla? [y/n]: " opt
        if [[ "$opt" == "y" || "$opt" == "Y" ]]; then
            while true; do
                read -p "Ingrese el nuevo gateway: " GateWay
                if ValidateIpAddress "$GateWay"; then
                    echo "Gateway capturado correctamente"
                    break
                else
                    echo "Error: La dirección de gateway no es válida. Intente nuevamente."
                fi
            done
        fi
        break
    done

    echo "Máscara de subred configurada automáticamente..."
    echo "Servidor DNS asignado automáticamente..."
    sudo chmod 600 /etc/netplan/00-installer-config.yaml.
    # Configurar IP en la interfaz de red
    NetPrefix=$(CalculateNetMask "$IpAddress")
    if [[ -n "$NetPrefix" ]]; then
        echo "network:
            version: 2
            renderer: networkd
            ethernets:
                enp0s3:
                    dhcp4: no
                    addresses:
                        - $IpAddress/$NetPrefix
                    gateway4: $GateWay
                    nameservers:
                        addresses:
                            - 8.8.8.8
                            - 8.8.4.4" | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
        # Aplicar cambios
        sudo netplan apply

        echo "Configuración de red aplicada correctamente."
    else
        echo "Error: No se pudo calcular la máscara de subred. Verifique la IP ingresada."
    fi
}

# Función para extraer el segmento de red de una IP
ExtractNetSegment() {
    local IP="$1"
    IFS='.' read -r -a Seg <<< "$IP"
    echo "${Seg[0]}.${Seg[1]}.${Seg[2]}"
}

# Función para calcular la máscara de subred en formato de prefijo (CIDR)
CalculateNetMask() {
    local IP="$1"
    IFS='.' read -r -a Seg <<< "$IP"
    local NetSegment=${Seg[0]}

    if (( NetSegment >= 0 && NetSegment <= 127 )); then
        echo 8  # Clase A
    elif (( NetSegment >= 128 && NetSegment <= 191 )); then
        echo 16  # Clase B
    elif (( NetSegment >= 192 && NetSegment <= 223 )); then
        echo 24  # Clase C
    else
        echo ""  # IP no válida
    fi
}

# Función para validar una dirección IP
ValidateIpAddress() {
    local IpAddress="$1"
    local Pattern='^(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)$'
    [[ "$IpAddress" =~ $Pattern ]]
}

# Función para validar un dominio
ValidateDomain() {
    local Domain="$1"
    local Pattern='^(([a-z]{2,})+\.)+([a-z]{2,})+$'
    [[ "$Domain" =~ $Pattern ]]
}

#!/bin/bash
url_apache="https://httpd.apache.org/download.cgi"
url_nginx="https://nginx.org/en/download.html"
url_litespeed="https://openlitespeed.org/downloads/"
url_apache_descargas="https://downloads.apache.org/httpd/"
url_litespeed_descargas="https://openlitespeed.org/packages/"
url_nginx_descargas="https://nginx.org/download/"

menu_http(){
    echo "= MENU HTTP ="
    echo "1. Apache"
    echo "2. OpenLiteSpeed"
    echo "3. Nginx"
    echo "4. Salir"
}

menu_http2(){
    local service="$1"
    local stable="$2"
    local mainline="$3"
    echo "$service"
    
    if [ "$service" = "Apache" ]; then
        echo "1. Versión estable $stable"
        echo "2. Regresar"
    elif [ "$service" = "Nginx" ] || [ "$service" = "OpenLiteSpeed" ]; then
        echo "1. Versión estable $stable"
        echo "2. Versión de desarrollo $mainline"
        echo "3. Regresar"
    else 
        echo "Opción no válida"
        exit 1
    fi
}

obtener_version(){
    local service="$1"
    case "$service" in
        Apache)
            versions=$(curl -s "$url_apache" |  grep -oP '(?<=Apache HTTP Server )\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        Nginx)
            versions=$(curl -s "$url_nginx" |  grep -oP '(?<=nginx-)\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        OpenLiteSpeed)
            versions=$(curl -s "$url_litespeed" | grep -oP 'openlitespeed-\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        *)
            echo "Servicio no soportado"
            exit 1
            ;;
    esac

    echo "$versions"
}

solicitar_puerto() {
    local port
    local puertos_reservados=(21 22 23 25 53 110 143 161 162 389 443 465 993 995 1 7 9 11 13 15 17 19 137 138 139 1433 1434 1521 2049 3128 3306 3389 5432 6000 6379 6660 6661 6662 6663 6664 6665 6666 6667 6668 6669 27017 8000 8080 8888)
    
    while true; do
        read -p "Introduce un puerto: " port

        [[ -z "$port" ]] && return

        # Verificar si el input es un número y está en el rango permitido
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo "El puerto debe estar entre 1 y 65535" >&2  

        # Verificar si el puerto está en la lista de reservados
        elif [[ " ${puertos_reservados[*]} " =~ " $port " ]]; then
            echo "Puerto $port está reservado" >&2

        # Verificar si el puerto ya está en uso con ss
        elif ss -tuln | grep -q ":$port "; then
            echo "Puerto $port lo estan usando" >&2

        else 
            echo "$port"
            return
        fi
    done
}

solicitar_ver() {
    local service="$1"
    local ver
    while true; do
        read ver
        if [ "$service" = "Apache" ] && [[ "$ver" =~ ^[1-2]$ ]]; then
            echo "$ver"  # Solo devuelve la opción válida
            return
        elif [ "$service" = "Nginx" ] && [[ "$ver" =~ ^[1-3]$ ]]; then
            echo "$ver"  # Solo devuelve la opción válida
            return
        elif [ "$service" = "OpenLiteSpeed" ] && [[ "$ver" =~ ^[1-3]$ ]]; then
            echo "$ver"  # Solo devuelve la opción válida
            return
        else
            echo "No es valido" >&2  
        fi
    done
}

conf_litespeed(){
    local port="$1"
    local version="$2"
    echo "Descargando OpenLiteSpeed $version"

    cd /tmp
    # Variable URL para descargar la version
    #url="https://openlitespeed.org/packages/"$version".tgz"
    url="${url_litespeed_descargas}$version.tgz"

    wget -O litespeed.tgz "$url"
    #Extraer archivos
    tar -xzf litespeed.tgz > /dev/null 2>&1
    #Cambiar de directorio e instalar
    cd openlitespeed

    #Instalar openlitespeed
    sudo bash install.sh > /dev/null 2>&1

    # Modificar el puerto de escucha
    config="/usr/local/lsws/conf/httpd_config.conf"

    sudo grep -rl "8088" "/usr/local/lsws/conf" | while read file; do
        sudo sed -i "s/8088/$port/g" "$file"
    done

    echo "ServerName localhost" | sudo tee -a "$config"
    
    sudo systemctl start lshttpd
    sudo systemctl enable lshttpd

    sudo ufw allow $port/tcp
    
    # Reniciar el servicio
    sudo /usr/local/lsws/bin/lswsctrl restart
}

conf_apache(){
    local port="$1"
    local version="$2"
    echo "Descargando Apache $version"

    #Descargar e instalar la versión seleccionada
    # *** cd /tmp
    url="${url_apache_descargas}httpd-$version.tar.gz"
    wget "$url"
    tar -xzvf httpd-$version.tar.gz > /dev/null 2>&1
    cd httpd-$version

    #Configurar Apache para la instalación
    ./configure --prefix=/usr/local/apache2 --enable-so --enable-mods-shared=all --enable-ssl > /dev/null 2>&1
    #Compilar e instalar Apache
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1

    #Configurar el puerto
    sudo sed -i "s/Listen 80/Listen $port/" /usr/local/apache2/conf/httpd.conf 

    #Asegurarse de que la directiva 'ServerName' esté configurada
    echo "ServerName localhost" | sudo tee -a /usr/local/apache2/conf/httpd.conf 
            
    #Reiniciar Apache
    sudo /usr/local/apache2/bin/apachectl start 
    sudo ufw allow $port/tcp
}

conf_nginx(){
    local port="$1"
    local version="$2"
    echo "Descargando Nginx $version"

    #Descargar e instalar la versión seleccionada
    cd /tmp
    url="${url_nginx_descargas}nginx-$version.tar.gz"
    wget -q "$url"
    #wget https://nginx.org/download/nginx-$version.tar.gz
    tar -xzvf nginx-$version.tar.gz > /dev/null 2>&1
    cd nginx-$version

    #Configurar Nginx para la instalación
    ./configure --prefix=/usr/local/nginx --with-http_ssl_module > /dev/null 2>&1

    #Compilar e instalar Nginx
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1
    sudo sed -i "s/listen[[:space:]]*80/listen $port/" /usr/local/nginx/conf/nginx.conf
    sudo grep "listen" /usr/local/nginx/conf/nginx.conf

    #Iniciar Nginx
    sudo /usr/local/nginx/sbin/nginx 
    sudo ufw allow $port/tcp

}

