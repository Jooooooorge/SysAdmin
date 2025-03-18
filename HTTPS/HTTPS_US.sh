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

echo "Instalando dependencias...."
sudo apt update -qq > /dev/null 2>&1
sudo apt install -qq curl wget grep sed  > /dev/null 2>&1
sudo apt install -qq -y build-essential libapr1-dev libaprutil1-dev libpcre3-dev  > /dev/null 2>&1

# Mostrar el menú
echo "========= ========= ========="
echo " SELECCIONA UN SERVIDOR WEB"
echo " [0] Apache"
echo " [1] Nginx"
echo " [2] Caddy"

# Solicitar la opción al usuario
while true; do
    printf "Selecciona un servidor: "
    read opc

    # Validar la entrada
    if [[ "$opc" =~ ^[0-9]+$ ]] && [ "$opc" -lt 3 ] && [ "$opc" -ge 0 ]; then
        break  # Salir del bucle si la entrada es válida
    else
        echo "Opción no válida. Inténtalo de nuevo."
    fi
done

# Mostrar la opción seleccionada
echo "Opción seleccionada: $opc"

# Continuar con la lógica según la opción seleccionada
case "$opc" in
    0)
        # Comprobar si la herramienta bzip esta isntalada
        if ! command -v bzip2 &> /dev/null; then
            echo "bzip2 no está instalado. Instalando bzip2..."
            sudo apt install -qq -y bzip2 > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "Error al instalar bzip2."
                exit 1
            fi
        fi

        # Paso 1: Descargar el HTML de Apache
        echo "Descargando información de Apache..."
        curl -s https://httpd.apache.org/download.cgi -o apache.html

        if [ $? -eq 0 ]; then
            echo "HTML de Apache descargado correctamente."
        else
            echo "Error al descargar el HTML de Apache."
            exit 1
        fi

        # Paso 2: Extraer el enlace de descarga usando tu regex
        echo "Extrayendo enlace de descarga de Apache..."
        apache_link=$(grep -oP '(https:\/\/dlcdn\.apache\.org\/httpd\/httpd-\d{1}\.\d{1}\.\d{1,}\.tar\.bz2)' apache.html | head -n 1)

        # Paso 3: Descargar el archivo comprimido
        echo "Descargando Apache..."
        wget -O apache.tar.bz2 "$apache_link" > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo "Apache descargado correctamente."
        else
            echo "Error al descargar Apache."
            exit 1
        fi

        # Paso 4: Descomprimir el archivo
        echo "Descomprimiendo Apache..."
        tar -xjf apache.tar.bz2 > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo "Apache descomprimido correctamente."
        else
            echo "Error al descomprimir Apache."
            exit 1
        fi
        # Habilitar Firewall
        sudo ufw allow 'Apache'

        # Paso 5: Instalar Apache
        echo "Instalando Apacheee"
        apache_dir=$(tar -tf apache.tar.bz2 | head -n 1 | cut -f1 -d"/") > /dev/null 2>&1
        cd "$apache_dir" || { echo "Error al cambiar al directorio de Apache."; exit 1; }
        echo "./configure..."
        ./configure > /dev/null 2>&1
        make > /dev/null 2>&1
        sudo make install > /dev/null 2>&1

        # Paso 6: Solicitar el puerto al usuario
        while true; do
            read -p "Ingresa el número de puerto para Apache: " port

            # Validar que el puerto sea un número y esté en el rango correcto
            if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
                break
            else
                echo "Puerto no válido. Debe ser un número entre 1 y 65535."
            fi
        done

        echo "Configurando Apache para escuchar en el puerto $port..."

        # Paso 7: Modificar la configuración de Apache
        apache_conf="/usr/local/apache2/conf/httpd.conf"

        if [ -f "$apache_conf" ]; then
            # Cambiar el puerto en la configuración
            sudo sed -i "s/^Listen [0-9]\+/Listen $port/" "$apache_conf"

            if [ $? -eq 0 ]; then
                echo "Puerto configurado correctamente en $apache_conf."
            else
                echo "Error al modificar el archivo de configuración."
                exit 1
            fi
        else
            echo "No se encontró el archivo de configuración de Apache en $apache_conf."
            exit 1
        fi

        # Paso 8: Reiniciar Apache
        echo "Reiniciando Apache..."
        sudo /usr/local/apache2/bin/apachectl restart

        if [ $? -eq 0 ]; then
            echo "Apache reiniciado correctamente y escuchando en el puerto $port."
        else
            echo "Error al reiniciar Apache."
            exit 1
        fi
        rm apache.html
        ;;
    1)
        echo "Descargando información de Nginx..."
        curl -s https://nginx.org/en/download.html -o nginx.html

        echo "Extrayendo enlace de descarga de Nginx..."
        nginx_match=$(grep -oP '(\/download\/nginx-\d{1}\.\d{1,}\.\d{1,}\.tar\.gz")' nginx.html | head -n 1)
        nginx_link="https://nginx.org$nginx_match"

        # Descargar el .zip
        echo "Descargando Nginx.zip..."
        echo "Enlace de descarga: $nginx_link"

        # Obtener el nombre del archivo
        nginx_file=$(basename "$nginx_link")
        echo "Nombre del archivo"

        echo "Descargando Nginx..."
        wget -O "$nginx_file" "$nginx_link"

        if [ $? -eq 0 ]; then
            echo "Nginx descargado correctamente."
        else
            echo "Error al descargar Nginx."
            exit 1
        fi


        echo "Descomprimiendo Nginx..."
        tar -xzf "$nginx_file"

        if [ $? -eq 0 ]; then
            echo "Nginx descomprimido correctamente."
        else
            echo "Error al descomprimir Nginx."
            exit 1
        fi

        # Obtener el nombre del directorio descomprimido
        nginx_dir=$(basename "$nginx_file" .tar.gz)

        echo "Directorio descomprimido: $nginx_dir"

        echo "Configurando Nginx..."
        cd "$nginx_dir" || { echo "Error al cambiar al directorio de Nginx."; exit 1; }
        ./configure > /dev/null 2>&1

        make > /dev/null 2>&1

        sudo make install > /dev/null 2>&1

        # Configuración del puerto
        while true; do
            read -p "Ingresa el número de puerto para Nginx (1-65535): " port

            # Validar que el puerto sea un número y esté en el rango correcto
            if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
                break
            else
                echo "Puerto no válido. Debe ser un número entre 1 y 65535."
            fi
        done

        nginx_conf="/usr/local/nginx/conf/nginx.conf"

        if [ -f "$nginx_conf" ]; then
            # Cambiar el puerto en la configuración
            sudo sed -i "s/^\(listen\s*\)[0-9]\+/\1$port/" "$nginx_conf"

            if [ $? -eq 0 ]; then
                echo "Puerto configurado correctamente en $nginx_conf."
            else
                echo "Error al modificar el archivo de configuración."
                exit 1
            fi
        else
            echo "No se encontró el archivo de configuración de Nginx en $nginx_conf."
            exit 1
        fi

        # Reiniciar Nginx
        sudo /usr/local/nginx/sbin/nginx -s reload

        # Limpiar archivos temporales
        rm nginx.html
        ;;
    2)
        echo "Descargando información de Caddy..."
        curl -s https://caddyserver.com/download -o caddy.html

        ;;
    *)
        echo "Error: Opción no válida."
        ;;
esac