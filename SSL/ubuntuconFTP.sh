#!/bin/bash
###############################################################################
# SCRIPT UNIFICADO: vsftpd (FTP/FTPS) + Instalación de Apache y Nginx
# 
# AMBOS SERVICIOS (APACHE/NGINX) pueden coexistir:
# - En la instalación de Apache se elige un puerto HTTP (ej 8080) y uno HTTPS (ej 8443).
# - En la instalación de Nginx se elige un puerto HTTP (ej 80) y uno HTTPS (ej 443).
# Así no entran en conflicto.
###############################################################################

#############################
# BLOQUE 0: VARIABLES GLOBALES
#############################

FTP_SERVER="192.168.0.60"   # Ajusta a tu IP real
FTP_USER="linux"
FTP_PASS="1234"

FTPS_ENABLED=false
FTP_PORT=21

get_protocol_prefix() {
    if $FTPS_ENABLED; then
        echo "ftps://"
    else
        echo "ftp://"
    fi
}

#############################
# BLOQUE 1: CONFIGURACIÓN VSFTPD (SIN CAMBIOS)
#############################

FTP_ROOT="/srv/ftp"
USERS_FOLDER="$FTP_ROOT/Usuarios"
GROUPS_FOLDER="$FTP_ROOT/Grupos"
GENERAL_FOLDER="$FTP_ROOT/General"
ANONYMOUS_FOLDER="$FTP_ROOT/Anonymous"
REPROBADOS_FOLDER="$GROUPS_FOLDER/Reprobados"
RECURSO_FOLDER="$GROUPS_FOLDER/Recursadores"
USERS_GROUPS=("Reprobados" "Recursadores")

install_vsftpd_local() {
    echo "Instalando vsftpd y dependencias..."
    sudo apt update && sudo apt install -y vsftpd acl ufw openssl
}

configure_ftps() {
    echo "Configurando FTPS en vsftpd (puerto 990)..."
    if [ ! -f /etc/ssl/private/vsftpd.pem ]; then
        echo "Generando certificado SSL auto-firmado para vsftpd..."
        sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
             -keyout /etc/ssl/private/vsftpd.pem \
             -out /etc/ssl/private/vsftpd.pem \
             -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=ftp.example.com"
    fi
    sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak_ftps
    sudo bash -c "cat > /etc/vsftpd.conf" <<EOF
listen=YES
listen_port=990
anonymous_enable=YES
allow_writeable_chroot=YES
allow_anon_ssl=YES
anon_root=$ANONYMOUS_FOLDER
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
user_sub_token=\$USER
local_root=$USERS_FOLDER/\$USER/home
chroot_local_user=YES

# Forzar modo binario
ascii_upload_enable=NO
ascii_download_enable=NO

ssl_enable=YES
require_ssl_reuse=NO
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
implicit_ssl=YES

pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
pasv_address=192.168.0.60
ftpd_banner=Bienvenido al servidor FTPS de Ubuntu.
EOF
    sudo systemctl restart vsftpd
    echo "FTPS configurado en puerto 990."
}

configure_ftp() {
    echo "Configurando FTP sin SSL en vsftpd (puerto 21)..."
    sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak_ftp
    sudo bash -c "cat > /etc/vsftpd.conf" <<EOF
listen=YES
listen_port=21
anonymous_enable=YES
anon_root=$ANONYMOUS_FOLDER
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
user_sub_token=\$USER
local_root=$USERS_FOLDER/\$USER/home
chroot_local_user=YES
allow_writeable_chroot=YES

# Forzar modo binario
ascii_upload_enable=NO
ascii_download_enable=NO

ssl_enable=NO
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
ftpd_banner=Bienvenido al servidor FTP de Ubuntu.
EOF
    sudo systemctl restart vsftpd
    echo "FTP sin SSL configurado en puerto 21."
}

create_directories() {
    echo "Creando directorios base del FTP..."
    sudo mkdir -p "$USERS_FOLDER" "$GROUPS_FOLDER" "$GENERAL_FOLDER" "$ANONYMOUS_FOLDER"
    sudo mkdir -p "$REPROBADOS_FOLDER" "$RECURSO_FOLDER"
    sudo chmod 777 "$GENERAL_FOLDER"
    sudo chmod 770 "$REPROBADOS_FOLDER" "$RECURSO_FOLDER"
    sudo mkdir -p "$ANONYMOUS_FOLDER/General"
    sudo mount --bind "$GENERAL_FOLDER" "$ANONYMOUS_FOLDER/General"
    if ! grep -q "$ANONYMOUS_FOLDER/General" /etc/fstab; then
         echo "$GENERAL_FOLDER $ANONYMOUS_FOLDER/General none bind 0 0" | sudo tee -a /etc/fstab
    fi
}

create_groups() {
    echo "Creando grupos FTP..."
    for GROUP in "${USERS_GROUPS[@]}"; do
        if ! getent group "$GROUP" >/dev/null; then
            sudo groupadd "$GROUP"
        fi
    done
}

configure_firewall_ftp() {
    echo "Configurando reglas de firewall para FTP/FTPS..."
    sudo ufw allow 20/tcp
    sudo ufw allow 21/tcp
    sudo ufw allow 40000:50000/tcp
    sudo ufw allow 990/tcp
    sudo ufw enable
}

restart_vsftpd() {
    echo "Reiniciando vsftpd..."
    sudo systemctl restart vsftpd
}

ensure_ftp_user_linux() {
    if id "linux" &>/dev/null; then
        echo "El usuario 'linux' ya existe."
    else
        echo "Creando el usuario 'linux' para FTP..."
        sudo useradd -m -d "$USERS_FOLDER/linux" -s /bin/bash linux
        echo "linux:1234" | sudo chpasswd
        sudo mkdir -p "$USERS_FOLDER/linux/home"
        sudo chown -R linux:linux "$USERS_FOLDER/linux"
        sudo chmod 750 "$USERS_FOLDER/linux"
        echo "Usuario 'linux' creado con contraseña 1234."
    fi
    sudo sed -i "/^linux$/d" /etc/ftpusers 2>/dev/null
    sudo sed -i "/^linux$/d" /etc/vsftpd.user_list 2>/dev/null
}

add_user_ftp() {
    while true; do
        read -p "Ingrese el nombre de usuario (o 'salir'): " USERNAME
        [[ "$USERNAME" == "salir" ]] && break
        read -p "Ingrese el grupo (1: Reprobados, 2: Recursadores): " GROUP_OPTION
        case "$GROUP_OPTION" in
            1) GROUP="Reprobados" ;;
            2) GROUP="Recursadores" ;;
            *) echo "Opción inválida. Intente de nuevo."; continue ;;
        esac
        read -s -p "Contraseña para $USERNAME: " PASSWORD
        echo
        read -s -p "Confirme la contraseña: " PASSWORD_CONFIRM
        echo
        [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]] && echo "No coinciden." && continue

        USER_DIR="$USERS_FOLDER/$USERNAME"
        HOME_DIR="$USER_DIR/home"
        GROUP_DIR="$GROUPS_FOLDER/$GROUP"
        USER_PERSONAL_DIR="$HOME_DIR/Carpeta_Personal"

        sudo useradd -m -d "$USER_DIR" -g "$GROUP" -s /bin/bash "$USERNAME"
        echo "$USERNAME:$PASSWORD" | sudo chpasswd
        echo "Usuario $USERNAME creado."
        sudo usermod -aG "$GROUP" "$USERNAME"
        sudo mkdir -p "$USER_DIR" "$HOME_DIR" "$USER_PERSONAL_DIR"
        sudo chown "$USERNAME:$GROUP" "$USER_DIR"
        sudo chmod 750 "$USER_DIR"
        sudo chown "$USERNAME:$GROUP" "$HOME_DIR"
        sudo chmod 750 "$HOME_DIR"
        sudo chown "$USERNAME:$GROUP" "$USER_PERSONAL_DIR"
        sudo chmod 700 "$USER_PERSONAL_DIR"
        sudo mkdir -p "$GROUP_DIR"
        sudo chown root:"$GROUP" "$GROUP_DIR"
        sudo chmod 770 "$GROUP_DIR"
        sudo setfacl -m u:$USERNAME:rwx "$GROUP_DIR"
        sudo mkdir -p "$HOME_DIR/$GROUP" "$HOME_DIR/General"
        sudo mount --bind "$GROUP_DIR" "$HOME_DIR/$GROUP"
        sudo mount --bind "$GENERAL_FOLDER" "$HOME_DIR/General"
        if ! grep -q "$HOME_DIR/$GROUP" /etc/fstab; then
            echo "$GROUP_DIR $HOME_DIR/$GROUP none bind 0 0" | sudo tee -a /etc/fstab
        fi
        if ! grep -q "$HOME_DIR/General" /etc/fstab; then
            echo "$GENERAL_FOLDER $HOME_DIR/General none bind 0 0" | sudo tee -a /etc/fstab
        fi
        echo "Usuario $USERNAME agregado al grupo $GROUP."
    done
}

grant_luis_access_herman() {
    echo "Otorgando acceso a la carpeta 'herman' para 'luis'..."
    HERMAN_DIR="$USERS_FOLDER/linux/home/herman"
    if [ ! -d "$HERMAN_DIR" ]; then
        echo "Creando carpeta $HERMAN_DIR..."
        sudo mkdir -p "$HERMAN_DIR"
    fi
    if ! getent group herman >/dev/null; then
        echo "Creando grupo 'herman'..."
        sudo groupadd herman
    fi
    echo "Agregando 'luis' y 'linux' al grupo 'herman'..."
    sudo usermod -aG herman luis
    sudo usermod -aG herman linux
    sudo chmod 755 /srv/ftp
    sudo chmod 755 /srv/ftp/Usuarios
    sudo chmod 755 /srv/ftp/Usuarios/linux
    sudo chmod 755 /srv/ftp/Usuarios/linux/home
    sudo chown -R linux:herman "$HERMAN_DIR"
    sudo chmod -R 770 "$HERMAN_DIR"
    echo "Acceso otorgado. 'luis' debe re-loguearse."
}

fix_permissions_for_ftps() {
    echo "Ajustando permisos en carpetas 'http' y 'herman' para FTPS..."
    sudo chmod 755 /srv/ftp
    sudo chmod 755 /srv/ftp/Usuarios
    sudo chmod 755 /srv/ftp/Usuarios/linux
    sudo chmod 755 /srv/ftp/Usuarios/linux/home

    local http_folder="$USERS_FOLDER/linux/home/http"
    sudo chown -R linux:linux "$http_folder"
    sudo chmod -R 755 "$http_folder"

    local herman_folder="$USERS_FOLDER/linux/home/herman"
    sudo chown -R linux:linux "$herman_folder"
    sudo chmod -R 755 "$herman_folder"
    echo "Permisos ajustados para FTPS."
}

main_ubuntuconFTP() {
    echo "==== Configuración FTP LOCAL (vsftpd) ===="
    install_vsftpd_local
    create_directories
    create_groups
    ensure_ftp_user_linux
    configure_firewall_ftp

    read -p "¿Desea habilitar FTPS (puerto 990)? (s/n): " SSL_CHOICE
    if [ "$SSL_CHOICE" == "s" ]; then
        FTPS_ENABLED=true
        FTP_PORT=990
        configure_ftps
        fix_permissions_for_ftps
    else
        FTPS_ENABLED=false
        FTP_PORT=21
        configure_ftp
    fi

    restart_vsftpd
    add_user_ftp
    echo "Configuración FTP local completada."
    read -p "Presione Enter para continuar..."    

    read -p "¿Desea dar acceso a 'luis' en la carpeta 'herman'? (s/n): " GRANT_CHOICE
    if [ "$GRANT_CHOICE" == "s" ]; then
        grant_luis_access_herman
    else
        echo "No se modificaron permisos para 'luis' en 'herman'."
    fi

    read -p "Presione Enter para continuar..."
}

#############################
# BLOQUE 2: INSTALACIÓN DE SERVICIOS WEB
#############################

create_service_folders() {
    echo "Verificando carpetas de servicios en el home de 'linux'..."
    local http_folder="$USERS_FOLDER/linux/home/http"
    local herman_folder="$USERS_FOLDER/linux/home/herman"
    if [ ! -d "$http_folder" ]; then
         echo "Creando carpeta $http_folder..."
         sudo mkdir -p "$http_folder"
         sudo chown linux:linux "$http_folder"
         sudo chmod 755 "$http_folder"
    fi
    if [ ! -d "$herman_folder" ]; then
         echo "Creando carpeta $herman_folder..."
         sudo mkdir -p "$herman_folder"
         sudo chown linux:linux "$herman_folder"
         sudo chmod 755 "$herman_folder"
    fi
}

ensure_service_subfolders() {
    local folder="$1"
    for svc in Apache Nginx; do
        local path="$USERS_FOLDER/linux/home/$folder/$svc"
        if [ ! -d "$path" ]; then
            echo "Creando subcarpeta $path..."
            sudo mkdir -p "$path"
        fi
        sudo chown -R linux:linux "$path"
        sudo chmod -R 755 "$path"
    done
}

FOLDER_CHOICE=""

select_folder() {
    echo "¿En qué carpeta desea instalar/descargar versiones? (http/herman)"
    select folder_opt in "http" "herman" "Cancelar"; do
        case "$folder_opt" in
            "http")   FOLDER_CHOICE="http"; break ;;
            "herman") FOLDER_CHOICE="herman"; break ;;
            "Cancelar") echo "Cancelado."; return 1 ;;
            *) echo "Opción inválida." ;;
        esac
    done
    ensure_service_subfolders "$FOLDER_CHOICE"
    return 0
}

puertos_restringidos=(1 5 7 9 11 13 17 18 19 20 21 22 23 25 29 37 39 42 43 49 50 53 67 68 69 70 79 88 95 101 109 110 115 118 119 123 137 138 139 143 161 162 177 179 194 201 202 204 206 209 220 389 443 445 465 514 515 520 546 547 563 587 591 631 636 853 990 993 995 1194 1337 1701 1723 1813 2049 2082 2083 3074 3306 3389 4489 6667 6881 6969 25565)

puerto_en_uso_global() {
    if command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -q ":$1 "
    elif command -v lsof >/dev/null 2>&1; then
        lsof -i :$1 > /dev/null 2>&1
    else
        netstat -tulnp | grep -q ":$1 "
    fi
}

habilitar_puerto_firewall_global() {
    local port="$1"
    echo "Habilitando puerto $port en el firewall..."
    sudo ufw allow "$port"
}

########################################################################
# DESCARGA FTP/FTPS
########################################################################
wget_ftp_or_ftps() {
    local ftp_uri="$1"
    local out_file="$2"
    if $FTPS_ENABLED; then
        echo "Descargando con FTPS (puerto 990) desde: $ftp_uri"
        wget --ftps-implicit --no-check-certificate \
             --user="$FTP_USER" --password="$FTP_PASS" \
             -O "$out_file" "$ftp_uri"
    else
        echo "Descargando con FTP (puerto 21) desde: $ftp_uri"
        wget --user="$FTP_USER" --password="$FTP_PASS" \
             -O "$out_file" "$ftp_uri"
    fi
}

detect_type_generic() {
    local extract_dir="$1"
    if [ -x "$extract_dir/bin/apachectl" ] || [ -x "$extract_dir/sbin/nginx" ]; then
        echo "binary"
    elif [ -f "$extract_dir/configure" ]; then
        echo "source"
    else
        echo "unknown"
    fi
}

extract_file() {
    local file="$1"
    local dest_dir="$2"
    sudo mkdir -p "$dest_dir"
    if [[ "$file" =~ \.zip$ ]]; then
        echo "Extrayendo archivo .zip..."
        sudo apt-get install -y unzip
        sudo unzip -o "$file" -d "$dest_dir"
    else
        echo "Extrayendo archivo .tar(.gz)..."
        sudo tar -xzf "$file" -C "$dest_dir" --strip-components=1
    fi
}

###############################################################################
# FUNCIÓN: INSTALAR APACHE (sin conflictos)
###############################################################################
install_apache() {
    select_folder || return 1
    echo "=== Instalar Apache ==="
    sudo apt-get update
    sudo apt-get install -y build-essential wget

    local protocol
    if $FTPS_ENABLED; then
        protocol="ftps://"
    else
        protocol="ftp://"
    fi
    local ftp_list_uri="${protocol}${FTP_SERVER}:${FTP_PORT}/${FOLDER_CHOICE}/Apache/"

    local listado
    if $FTPS_ENABLED; then
        listado=$(curl --silent --ftp-ssl --ssl-reqd --insecure \
                       --user "$FTP_USER:$FTP_PASS" --list-only "$ftp_list_uri")
    else
        listado=$(curl --silent --user "$FTP_USER:$FTP_PASS" --list-only "$ftp_list_uri")
    fi
    listado=$(echo "$listado" | grep -E "\.tar(\.gz)?$|\.zip$")
    if [ -z "$listado" ]; then
        echo "No se encontraron archivos en $ftp_list_uri"
        return 1
    fi

    IFS=$'\n' read -rd '' -a versiones_apache <<<"$listado"
    echo "Seleccione la versión de Apache a instalar:"
    select version in "${versiones_apache[@]}"; do
        if [[ -n "$version" ]]; then
            break
        else
            echo "Selección inválida."
        fi
    done

    # ### Puerto para HTTP ###
    local port
    while true; do
        read -p "Puerto para Apache (HTTP) (ej. 8080): " port
        if [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 )); then
            if [[ " ${puertos_restringidos[*]} " =~ " $port " ]]; then
                echo "El puerto $port está restringido."
            elif puerto_en_uso_global "$port"; then
                echo "El puerto $port ya está en uso."
            else
                break
            fi
        else
            echo "Puerto inválido."
        fi
    done

    # Descarga
    local ftp_file_uri="${protocol}${FTP_SERVER}:${FTP_PORT}/${FOLDER_CHOICE}/Apache/$version"
    echo "Descargando Apache versión $version desde $ftp_file_uri ..."
    local archivo_descargado="/tmp/$version"
    wget_ftp_or_ftps "$ftp_file_uri" "$archivo_descargado"
    if [[ $? -ne 0 ]]; then
        echo "Error al descargar Apache $version"
        return 1
    fi

    local temp_extract="/tmp/apache_extract"
    sudo rm -rf "$temp_extract"
    sudo mkdir -p "$temp_extract"
    extract_file "$archivo_descargado" "$temp_extract"

    local apache_type
    apache_type=$(detect_type_generic "$temp_extract")

    local apache_install_dir="/opt/apache"
    sudo rm -rf "$apache_install_dir"
    sudo mkdir -p "$apache_install_dir"

    if [[ "$apache_type" == "binary" ]]; then
        echo "Detectado paquete binario de Apache..."
        sudo cp -r "$temp_extract/"* "$apache_install_dir/"
    elif [[ "$apache_type" == "source" ]]; then
        echo "Detectado paquete de código fuente de Apache. Compilando..."
        cd "$temp_extract" || return 1
        sudo apt-get install -y gcc make libapr1-dev libaprutil1-dev libpcre3-dev libssl-dev
        ./configure --prefix="$apache_install_dir" --enable-ssl --enable-so
        make
        sudo make install
    else
        echo "Error: Estructura desconocida (no bin/apachectl ni configure)."
        return 1
    fi

    # Index
    sudo mkdir -p "$apache_install_dir/htdocs"
    echo "<html><body><h1>Apache funciona correctamente.</h1></body></html>" \
        | sudo tee "$apache_install_dir/htdocs/index.html" >/dev/null

    if [ ! -x "$apache_install_dir/bin/apachectl" ]; then
        echo "Error: No se encontró $apache_install_dir/bin/apachectl."
        return 1
    fi
    if [ ! -d "$apache_install_dir/conf" ]; then
        sudo mkdir -p "$apache_install_dir/conf"
    fi

    # Conf HTTP
    if [ ! -f "$apache_install_dir/conf/httpd.conf" ]; then
        sudo bash -c "cat > $apache_install_dir/conf/httpd.conf" <<EOF
ServerName localhost
Listen $port
DocumentRoot "$apache_install_dir/htdocs"

<Directory "$apache_install_dir/htdocs">
    Require all granted
    Options FollowSymLinks
    AllowOverride None
</Directory>
EOF
    else
        sudo sed -i "s/Listen .*/Listen $port/" "$apache_install_dir/conf/httpd.conf"
    fi

    # Arrancamos HTTP
    echo "Iniciando Apache (HTTP) en puerto $port..."
    sudo "$apache_install_dir/bin/apachectl" start >/dev/null 2>&1
    sleep 3

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port")
    if [ "$http_code" == "200" ]; then
        echo "Apache se ejecuta correctamente en el puerto $port."
    else
        echo "Error: Apache no se inició en HTTP."
        if [ -f "$apache_install_dir/logs/error_log" ]; then
            cat "$apache_install_dir/logs/error_log"
        fi
        return 1
    fi

    habilitar_puerto_firewall_global "$port"

    # ### Opción HTTPS ###
    read -p "¿Desea habilitar HTTPS en Apache? (s/n): " apache_ssl
    if [[ "$apache_ssl" =~ ^[Ss]$ ]]; then
        local ssl_port
        while true; do
            read -p "Puerto para HTTPS (ej. 8443): " ssl_port
            if [[ "$ssl_port" =~ ^[0-9]+$ ]] && (( ssl_port >= 1 && ssl_port <= 65535 )); then
                if [[ " ${puertos_restringidos[*]} " =~ " $ssl_port " ]]; then
                    echo "El puerto $ssl_port está restringido."
                elif puerto_en_uso_global "$ssl_port"; then
                    echo "El puerto $ssl_port ya está en uso."
                else
                    break
                fi
            else
                echo "Puerto inválido."
            fi
        done

        # Generar certificado
        if [ ! -f "$apache_install_dir/conf/server.crt" ] || [ ! -f "$apache_install_dir/conf/server.key" ]; then
            sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                 -keyout "$apache_install_dir/conf/server.key" \
                 -out "$apache_install_dir/conf/server.crt" \
                 -subj "/C=US/ST=SomeState/L=SomeCity/O=Example/OU=IT/CN=localhost"
        fi

        # Insertar directivas SSL (LoadModule + VirtualHost)
        sudo bash -c "cat >> $apache_install_dir/conf/httpd.conf" <<EOF

LoadModule ssl_module modules/mod_ssl.so
Listen $ssl_port
<VirtualHost _default_:$ssl_port>
    DocumentRoot "$apache_install_dir/htdocs"
    SSLEngine on
    SSLCertificateFile "$apache_install_dir/conf/server.crt"
    SSLCertificateKeyFile "$apache_install_dir/conf/server.key"

    <Directory "$apache_install_dir/htdocs">
        Require all granted
    </Directory>
</VirtualHost>
EOF

        echo "Reiniciando Apache con HTTPS..."
        sudo "$apache_install_dir/bin/apachectl" stop >/dev/null 2>&1
        sleep 2
        sudo "$apache_install_dir/bin/apachectl" start >/dev/null 2>&1
        sleep 3

        local https_code
        https_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://localhost:$ssl_port")
        if [ "$https_code" == "200" ]; then
            echo "Apache HTTPS corriendo en $ssl_port."
        else
            echo "Error: No se pudo establecer conexión HTTPS en $ssl_port."
            if [ -f "$apache_install_dir/logs/error_log" ]; then
                cat "$apache_install_dir/logs/error_log"
            fi
        fi
        habilitar_puerto_firewall_global "$ssl_port"
    else
        echo "No se habilitó HTTPS en Apache."
    fi

    echo "Instalación de Apache finalizada (puertos: $port / $ssl_port)."
}

###############################################################################
# FUNCIÓN: INSTALAR NGINX (sin conflictos)
###############################################################################
install_nginx() {
    select_folder || return 1
    echo "=== Instalar Nginx ==="
    sudo apt-get update
    sudo apt-get install -y build-essential wget

    local protocol
    if $FTPS_ENABLED; then
        protocol="ftps://"
    else
        protocol="ftp://"
    fi
    local ftp_list_uri="${protocol}${FTP_SERVER}:${FTP_PORT}/${FOLDER_CHOICE}/Nginx/"

    local listado
    if $FTPS_ENABLED; then
        listado=$(curl --silent --ftp-ssl --ssl-reqd --insecure \
                       --user "$FTP_USER:$FTP_PASS" --list-only "$ftp_list_uri")
    else
        listado=$(curl --silent --user "$FTP_USER:$FTP_PASS" --list-only "$ftp_list_uri")
    fi
    listado=$(echo "$listado" | grep -E "\.tar(\.gz)?$|\.zip$")
    if [ -z "$listado" ]; then
        echo "No se encontraron archivos en $ftp_list_uri"
        return 1
    fi

    IFS=$'\n' read -rd '' -a versiones_nginx <<<"$listado"
    echo "Seleccione la versión de Nginx a instalar:"
    select version_nginx in "${versiones_nginx[@]}"; do
        if [[ -n "$version_nginx" ]]; then
            break
        else
            echo "Selección inválida."
        fi
    done

    local port
    while true; do
        read -p "Puerto para Nginx (HTTP) (ej. 80): " port
        if [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 )); then
            if [[ " ${puertos_restringidos[*]} " =~ " $port " ]]; then
                echo "El puerto $port está restringido."
            elif puerto_en_uso_global "$port"; then
                echo "El puerto $port ya está en uso."
            else
                break
            fi
        else
            echo "Puerto inválido."
        fi
    done

    local ftp_file_uri="${protocol}${FTP_SERVER}:${FTP_PORT}/${FOLDER_CHOICE}/Nginx/$version_nginx"
    echo "Descargando Nginx versión $version_nginx desde $ftp_file_uri ..."
    local archivo_nginx="/tmp/$version_nginx"
    wget_ftp_or_ftps "$ftp_file_uri" "$archivo_nginx"
    if [[ $? -ne 0 ]]; then
        echo "Error al descargar Nginx $version_nginx"
        return 1
    fi

    local temp_extract="/tmp/nginx_extract"
    sudo rm -rf "$temp_extract"
    sudo mkdir -p "$temp_extract"
    extract_file "$archivo_nginx" "$temp_extract"

    local nginx_type
    nginx_type=$(detect_type_generic "$temp_extract")

    local nginx_install_dir="/opt/nginx"
    sudo rm -rf "$nginx_install_dir"
    sudo mkdir -p "$nginx_install_dir"

    if [[ "$nginx_type" == "binary" ]]; then
        echo "Detectado paquete binario de Nginx..."
        sudo cp -r "$temp_extract/"* "$nginx_install_dir/"
    elif [[ "$nginx_type" == "source" ]]; then
        echo "Detectado paquete de código fuente de Nginx. Compilando..."
        cd "$temp_extract" || return 1
        sudo apt-get install -y gcc make libpcre3-dev zlib1g-dev libssl-dev
        ./configure --prefix="$nginx_install_dir" \
                    --conf-path="$nginx_install_dir/conf/nginx.conf" \
                    --with-http_ssl_module
        make
        sudo make install
    else
        echo "Error: Estructura desconocida (no sbin/nginx ni configure)."
        return 1
    fi

    # Index de prueba
    sudo mkdir -p "$nginx_install_dir/html"
    echo "<html><body><h1>Nginx funciona correctamente.</h1></body></html>" \
        | sudo tee "$nginx_install_dir/html/index.html" >/dev/null

    # config con un server en HTTP
    sudo bash -c "cat > $nginx_install_dir/conf/nginx.conf" <<EOF
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    server {
        listen $port;
        server_name localhost;
        root $nginx_install_dir/html;

        location / {
            index index.html;
        }
    }
}
EOF

    echo "Iniciando Nginx (HTTP, puerto $port)..."
    sudo "$nginx_install_dir/sbin/nginx" >/dev/null 2>&1
    sleep 3

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port")
    if [ "$http_code" == "200" ]; then
        echo "Nginx se ejecuta correctamente en el puerto $port."
    else
        echo "Error: Nginx no se inició correctamente."
        if [ -f "$nginx_install_dir/logs/error.log" ]; then
            cat "$nginx_install_dir/logs/error.log"
        fi
        return 1
    fi

    habilitar_puerto_firewall_global "$port"

    # ### Opción HTTPS
    read -p "¿Desea habilitar HTTPS en Nginx? (s/n): " nginx_ssl
    if [[ "$nginx_ssl" =~ ^[Ss]$ ]]; then
        local ssl_port
        while true; do
            read -p "Puerto para HTTPS (ej. 443): " ssl_port
            if [[ "$ssl_port" =~ ^[0-9]+$ ]] && (( ssl_port >= 1 && ssl_port <= 65535 )); then
                if [[ " ${puertos_restringidos[*]} " =~ " $ssl_port " ]]; then
                    echo "El puerto $ssl_port está restringido."
                elif puerto_en_uso_global "$ssl_port"; then
                    echo "El puerto $ssl_port ya está en uso."
                else
                    break
                fi
            else
                echo "Puerto inválido."
            fi
        done

        # Cert SSL
        if [ ! -f "$nginx_install_dir/conf/server.crt" ] || [ ! -f "$nginx_install_dir/conf/server.key" ]; then
            echo "Generando certificado SSL para Nginx..."
            sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                 -keyout "$nginx_install_dir/conf/server.key" \
                 -out "$nginx_install_dir/conf/server.crt" \
                 -subj "/C=US/ST=State/L=City/O=Example/OU=IT/CN=localhost"
        fi

        # Para insertar el 2do server https dentro de http { ... }, sin sed multilinea:
        sudo sed -i '$d' "$nginx_install_dir/conf/nginx.conf"  # quitamos la última '}'
        sudo bash -c "cat >> $nginx_install_dir/conf/nginx.conf" <<EOF
    server {
        listen $ssl_port ssl;
        server_name localhost;
        root $nginx_install_dir/html;

        ssl_certificate     $nginx_install_dir/conf/server.crt;
        ssl_certificate_key $nginx_install_dir/conf/server.key;

        location / {
            index index.html;
        }
    }
}
EOF

        echo "Reiniciando Nginx con HTTPS en puerto $ssl_port..."
        sudo "$nginx_install_dir/sbin/nginx" -s stop >/dev/null 2>&1
        sleep 2
        sudo "$nginx_install_dir/sbin/nginx" >/dev/null 2>&1
        sleep 3

        local https_code
        https_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://localhost:$ssl_port")
        if [ "$https_code" == "200" ]; then
            echo "Nginx HTTPS se ejecuta correctamente en $ssl_port."
        else
            echo "Error: No se pudo establecer conexión HTTPS en $ssl_port."
            if [ -f "$nginx_install_dir/logs/error.log" ]; then
                cat "$nginx_install_dir/logs/error.log"
            fi
        fi
        habilitar_puerto_firewall_global "$ssl_port"
    else
        echo "No se habilitó HTTPS en Nginx."
    fi

    echo "Instalación de Nginx finalizada (puertos: $port / $ssl_port)."
}

#############################
# MENÚ DE INSTALACIÓN WEB
#############################
Mostrar_Menu_Instalacion() {
    while true; do
        echo ""
        echo "=========================================="
        echo " MENÚ DE INSTALACIÓN DE SERVICIOS WEB (vía FTP/FTPS)"
        echo "=========================================="
        echo "1) Instalar Apache"
        echo "2) Instalar Nginx"
        echo "3) Salir"
        read -p "Seleccione una opción (1-3): " opcion
        case "$opcion" in
            1) install_apache ;;
            2) install_nginx ;;
            3) break ;;
            *) echo "Opción inválida." ;;
        esac
        read -p "Presione Enter para volver al menú..." dummy
    done
}

#############################
# MENÚ PRINCIPAL
#############################
shown_main_menu() {
    create_service_folders
    while true; do
        clear
        echo "=========================================="
        echo " MENÚ PRINCIPAL UNIFICADO"
        echo "=========================================="
        echo "1) Configurar FTP local (vsftpd)"
        echo "2) Menú de instalación de servicios web (vía FTP/FTPS)"
        echo "3) Salir"
        read -p "Seleccione una opción (1-3): " main_opt
        case "$main_opt" in
            1) main_ubuntuconFTP ;;
            2) Mostrar_Menu_Instalacion ;;
            3) exit 0 ;;
            *) echo "Opción inválida. Intente de nuevo." ;;
        esac
        read -p "Presione Enter para continuar..." dummy
    done
}

# EJECUCIÓN
shown_main_menu
