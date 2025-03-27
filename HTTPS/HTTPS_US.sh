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

#!/bin/bash
source "./US.sh"

if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root" 
    exit 1
fi
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev \
    libssl-dev libnghttp2-dev libbrotli-dev libxml2-dev libcurl4-openssl-dev \
    libjansson-dev libgeoip-dev liblmdb-dev libyajl-dev libgd-dev libtool \
    autoconf automake libexpat1-dev pkg-config libssl-dev libxml2-dev \
    libapr1-dev libaprutil1-dev liblua5.3-dev > /dev/null 2>&1

sudo apt install net-tools -y > /dev/null 2>&1

# Descargar e instalar APR y APR-util (necesarios para Apache)
cd /tmp
wget https://dlcdn.apache.org//apr/apr-1.7.4.tar.gz
tar -xzvf apr-1.7.4.tar.gz
cd apr-1.7.4
./configure --prefix=/usr/local/apr
make
sudo make install
cd ..

wget https://dlcdn.apache.org//apr/apr-util-1.6.3.tar.gz
tar -xzvf apr-util-1.6.3.tar.gz
cd apr-util-1.6.3
./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
make
sudo make install
cd ..
while true; do
    menu_http
    read -p "Seleccione el servicio HTTP que queria instalar y configurar: " op
            
    if [ "$op" -eq 1 ]; then
        versions=$(obtener_version "Apache")
        stable=$(echo "$versions" | head -1)
        menu_http2 "Apache" "$stable" " "
        echo "Elija una version: "
        op2=$(solicitar_ver "Apache") 
        if [ "$op2" -eq 1 ]; then
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            conf_apache "$port" "$stable"
        elif [ "$op2" -eq 2 ]; then
            continue
        fi
    elif [ "$op" -eq 3 ]; then
        versions=$(obtener_version "Nginx")
        stable=$(echo "$versions" | tail -n 2 | head -1)
        mainline=$(echo "$versions" | tail -1)
        menu_http2 "Nginx" "$stable" "$mainline"
        echo "Elija una version: "
        op2=$(solicitar_ver "Nginx")
        if [ "$op2" -eq 1 ]; then  
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            conf_nginx "$port" "$stable"
        elif [ "$op2" -eq 2 ]; then
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            conf_nginx "$port" "$mainline"
        elif [ "$op2" -eq 3 ]; then
            continue
        fi
    elif [ "$op" -eq 2 ]; then
        versions=$(obtener_version "OpenLiteSpeed")
        stable=$(echo "$versions" | tail -n 2 | head -1)
        mainline=$(echo "$versions" | tail -1)
        menu_http2 "OpenLiteSpeed" "$stable" "$mainline"
        echo "Elija una version: "
        op2=$(solicitar_ver "OpenLiteSpeed")
        if [ "$op2" -eq 1 ]; then
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            conf_litespeed "$port" "$stable"
        elif [ "$op2" -eq 2 ]; then 
            port=$(solicitar_puerto)
            if [[ -z "$port" ]]; then
                continue
            fi
            conf_litespeed "$port" "$mainline"
        elif [ "$op2" -eq 3 ]; then
            continue
        fi
    elif [ "$op" -eq 4 ]; then
        echo "Saliendo..."
        exit 0
    else
        echo "Opción no válida"
    fi
done