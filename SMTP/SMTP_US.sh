#!/bin/bash

# Variables iniciales
DOMAIN="midominio.com"
HOSTNAME="mail.$DOMAIN"

# Función para instalar los paquetes necesarios
instalar_paquetes() {
    echo "==> Actualizando paquetes..."
    sudo apt update -y && sudo apt upgrade -y

    echo "==> Instalando Postfix, Dovecot, Apache y dependencias..."
    sudo apt install -y postfix dovecot-core dovecot-pop3d dovecot-imapd apache2 unzip wget

    echo "==> Instalando PHP y módulos necesarios..."
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt install php7.4 libapache2-mod-php7.4 php-mysql -y
}

# Función para configurar el dominio de correo
# configuración del Postfix
configurar_dominio() {
    read -p "Introduce el dominio que deseas configurar: " DOMAIN
    HOSTNAME="mail.$DOMAIN"

    sudo postconf -e "myhostname = $HOSTNAME"
    sudo postconf -e "mydomain = $DOMAIN"
    sudo postconf -e "myorigin = \$mydomain"
    sudo postconf -e "inet_interfaces = all"
    sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
    sudo postconf -e "mynetworks = 127.0.0.0/8"
    sudo postconf -e "home_mailbox = Maildir/"
    sudo postconf -e "smtpd_banner = \$myhostname ESMTP"
    sudo postconf -e "smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem"
    sudo postconf -e "smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key"
    sudo postconf -e "smtpd_use_tls=yes"

    
    sudo systemctl restart postfix
    sudo systemctl enable postfix

    echo "Dominio predeterminado $DOMAIN configurado"
}

# Función para configurar usuarios y buzón
configurar_usuario_buzon() {
    read -p "Introduce el nombre del usuario de correo: " NUEVO_USUARIO
    
    while true; do
        stty -echo
        read -p "Introduce la contraseña para $NUEVO_USUARIO: " NUEVA_CONTRASENA
        stty echo
        echo
        if [ ${#NUEVA_CONTRASENA} -ge 8 ]; then
            break
        else
            echo "La contraseña debe tener al menos 8 caracteres. Intenta nuevamente."
        fi
    done

    CORREO="$NUEVO_USUARIO@$DOMAIN"
    sudo adduser --gecos "" --disabled-password $NUEVO_USUARIO
    echo "$NUEVO_USUARIO:$NUEVA_CONTRASENA" | sudo chpasswd
    sudo mkdir -p /home/$NUEVO_USUARIO/Maildir
    sudo chown -R $NUEVO_USUARIO:$NUEVO_USUARIO /home/$NUEVO_USUARIO/Maildir
    sudo find /home/$NUEVO_USUARIO/Maildir -type d -exec chmod 755 {} \;
    sudo find /home/$NUEVO_USUARIO/Maildir -type f -exec chmod 644 {} \;
    
    echo "Cuenta de correo $CORREO creada correctamente."
    sudo systemctl restart dovecot
    sudo systemctl enable dovecot
}

# Función para configurar SquirrelMail
configurar_squirrelmail() {
    echo "Iniciando la configuración de SquirrelMail..."
    echo "Se instalarán PHP, Apache y dependencias necesarias."

    # Instalar repositorio de PHP y paquetes requeridos
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    sudo apt install php7.4 libapache2-mod-php7.4 php-mysql -y

    # Solicitar el dominio que se usará en la configuración de SquirrelMail
    while true; do
        read -p "Ingrese el dominio para SquirrelMail (sin espacios): " dominio
        if [[ -z "$dominio" || "$dominio" =~ \  ]]; then
            echo "El dominio no puede estar vacío ni contener espacios."
        else
            break
        fi
    done

    # Establecer rutas para los directorios de datos y archivos adjuntos
    data_directory="/var/www/html/squirrelmail/data/"
    attach_directory="/var/www/html/squirrelmail/attach/"

    # Ruta de instalación de SquirrelMail
    install_dir="/var/www/html/squirrelmail"

    # Descargar y extraer SquirrelMail
    cd /var/www/html/
    wget -O squirrelmail.zip "https://sourceforge.net/projects/squirrelmail/files/stable/1.4.22/squirrelmail-webmail-1.4.22.zip/download" -q
    if [ $? -ne 0 ]; then
        echo "Error al descargar SquirrelMail."
        return 1
    fi
    unzip -q squirrelmail.zip
    sudo mv squirrelmail-webmail-1.4.22 squirrelmail
    rm squirrelmail.zip

    # Ajustar permisos y propiedad para Apache
    sudo chown -R www-data:www-data "$install_dir/"
    sudo chmod -R 755 "$install_dir/"

    # Modificar configuración de SquirrelMail (archivo config_default.php)
    config_file="$install_dir/config/config_default.php"
    if [ ! -f "$config_file" ]; then
        echo "No se encontró $config_file. Verifique la instalación de SquirrelMail."
        return 1
    fi

    sudo sed -i "s/^\$domain.*/\$domain = '$dominio';/" "$config_file"
    sudo sed -i "s|^\$data_dir.*| \$data_dir = '$data_directory';|" "$config_file"
    sudo sed -i "s|^\$attachment_dir.*| \$attachment_dir = '$attach_directory';|" "$config_file"
    sudo sed -i "s/^\$allow_server_sort.*/\$allow_server_sort = true;/" "$config_file"

    # Ejecutar el script de configuración interactivo de SquirrelMail de forma automatizada
    echo -e "s\n\nq" | perl "$install_dir/config/conf.pl"

    # Reiniciar Apache para aplicar cambios
    sudo systemctl reload apache2
    sudo systemctl restart apache2

    echo "SquirrelMail ha sido configurado exitosamente. Acceda mediante http://$dominio o la IP del servidor."
}

# Menú de opciones
menu() {
    while true; do
        echo " ===== Menú ====="
        echo " [1] Agregar usuario " 
        echo " [2] Salir"
        read -p "Elige una opción: " opc
        
        case $opc in
            1) configurar_usuario_buzon ;;
            2) exit ;;
            *) echo "Opción no válida. Intenta nuevamente." ;;
        esac
    done
}

main ()
{
    instalar_paquetes
    configurar_dominio
    configurar_squirrelmail
    menu
}

# main
main

# Dependencias
# SERVIDOR CORREO
#   -Postfix (SMTP)
#   -Devocot (POP3)
#   -SquirrelMail (Cliente del correo)
#   -ThunderBird
#   -Apache (Para que funcione el Squirrel)


