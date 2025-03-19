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
sudo apt install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev > /dev/null 2>&1
sudo apt install -y libapr1-dev libaprutil1-dev > /dev/null 2>&1
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
        apache_link=$(grep -oP '(https:\/\/dlcdn\.apache\.org\/httpd\/httpd-\d{1}\.\d{1}\.\d{1,}\.tar\.gz)' apache.html | head -n 1)
        version_link=$(echo "$apache_link" | grep -oP '\d{1}\.\d{1,}\.\d{1,}' | head -n 1)
        
        # Paso 3: Descargar el archivo comprimido
        echo "Descargando Apache... link $apache_link -- $version_link"
        wget -O apache.tar.gz "$apache_link" > /dev/null 2>&1

        # Paso 4: Descomprimir el archivo
        echo "Descomprimiendo Apache..."
        tar -xzvf apache.tar.gz > /dev/null 2>&1

        # Paso 5: Instalar Apache
        echo "Instalando Apache... "
        cd "httpd-2.4.63" || { echo "Error al cambiar al directorio de Apache."; exit 1; }

        # Compilando código
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

        # Paso 7: Modificar la configuración de Apache
        sudo sed -i "s/Listen 80/Listen $port/" /usr/local/apache2/conf/httpd.conf 
        echo "ServerName localhost" | sudo tee -a /usr/local/apache2/conf/httpd.conf 

        # Paso 8: Reiniciar Apache
        echo "Reiniciando Apache..."
        sudo /usr/local/apache2/bin/apachectl restart

        #Reiniciar Apache
        sudo /usr/local/apache2/bin/apachectl start 
        sudo ufw allow $port/tcp
        
        ;;
    1)
        echo "Descargando información de Nginx..."
        curl -s https://nginx.org/en/download.html -o nginx.html

        echo "Extrayendo enlace de descarga de Nginx..."
        nginx_match=$(grep -oP '(\/download\/nginx-\d{1}\.\d{1,}\.\d{1,}\.tar\.gz)' nginx.html | head -n 1)
        nginx_link="https://nginx.org$nginx_match"
        version_link=$(echo "$nginx_link" | grep -oP '\d{1}\.\d{1,}\.\d{1,}' | head -n 1)

        echo "version -- $version_link"
        wget -q "$nginx_link"
        tar -xzvf nginx-1.27.4.tar.gz > /dev/null 2>&1
        cd nginx-1.27.4

        #Configurar Nginx para la instalación
        ./configure --prefix=/usr/local/nginx --with-http_ssl_module > /dev/null 2>&1

        make > /dev/null 2>&1

        sudo make install > /dev/null 2>&1

        # Configuración del puerto
        while true; do
            read -p "Ingresa el número de puerto para Nginx: " port

            # Validar que el puerto sea un número y esté en el rango correcto
            if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
                break
            else
                echo "Puerto no válido. Debe ser un número entre 1 y 65535."
            fi
        done

        sudo sed -i "s/listen[[:space:]]*80/listen $port/" /usr/local/nginx/conf/nginx.conf
        sudo grep "listen" /usr/local/nginx/conf/nginx.conf

        #Iniciar Nginx
        sudo /usr/local/nginx/sbin/nginx 
        sudo ufw allow $port/tcp
        ;;
    2)
        # Descargar Caddy
        CADDY_VERSION="2.7.6"  # Reemplaza con la última versión si es necesario
        wget "https://github.com/caddyserver/caddy/releases/download/v$CADDY_VERSION/caddy_${CADDY_VERSION}_linux_amd64.tar.gz"

        # Descomprimir el archivo
        tar -xzf caddy_${CADDY_VERSION}_linux_amd64.tar.gz

        # Mover el binario a /usr/local/bin
        sudo mv caddy /usr/local/bin/

        # Crear directorios de configuración y contenido
        sudo mkdir -p /etc/caddy
        sudo mkdir -p /var/www/html

        # Crear un archivo Caddyfile básico
        echo ":80 {
            root * /var/www/html
            file_server
        }" | sudo tee /etc/caddy/Caddyfile > /dev/null

        # Solicitar el puerto al usuario
        while true; do
            read -p "Ingresa el número de puerto para Caddy (1-65535): " port

            # Validar que el puerto sea un número y esté en el rango correcto
            if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
                break
            else
                echo "Puerto no válido. Debe ser un número entre 1 y 65535."
            fi
        done

        # Modificar el Caddyfile para usar el puerto especificado
        sudo sed -i "s/:80/:$port/" /etc/caddy/Caddyfile

        # Iniciar Caddy
        sudo caddy run --config /etc/caddy/Caddyfile &

        ;;
    *)
        echo "Error: Opción no válida."
        ;;
esac