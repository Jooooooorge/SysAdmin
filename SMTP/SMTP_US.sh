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
configurar_squirrelmail() 
{
   # Instalar dependencias necesarias
    sudo apt update
    sudo apt upgrade -y
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    sudo apt install apache2
    sudo apt install php7.4 libapache2-mod-php7.4 php-mysql -y
    # Descargar la última versión estable de SquirrelMail
    wget https://sourceforge.net/projects/squirrelmail/files/latest/download/squirrelmail-webmail-1.4.22.tar.gz
    # Extraer el archivo tar
    sudo tar -xzf squirrelmail-webmail-1.4.22.tar.gz > /dev/null 2>&1
    # Mover y configurar permisos de la carpeta
    sudo mv squirrelmail-webmail-1.4.22 /var/www/html/squirrelmail
    sudo chown -R www-data:www-data /var/www/html/squirrelmail
    sudo chmod 755 -R /var/www/html/squirrelmail
    sudo mkdir /var/local/squirrelmail/data
    sudo chown -R www-data:www-data /var/local/squirrelmail
    # Configurar squirrelmail
    cd /var/www/html/squirrelmail/config
    sudo cp config_default.php config.php
    sudo ./conf.pl
    # Configurar Apache
    cat > /etc/apache2/sites-available/squirrelmail.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@example.com
    DocumentRoot /var/www/html/squirrelmail
    Alias /squirrelmail "/var/www/html/squirrelmail"

    <Directory "/var/www/html/squirrelmail">
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
    # Activar el sitio y el módulo de reescritura en Apache
    a2ensite squirrelmail
    a2enmod rewrite
    systemctl restart apache2
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


