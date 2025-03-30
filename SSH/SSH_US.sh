#!/bin/bash
#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH

# Importar funciones
source ../FUNC/US.sh

# Asegurarnos de que el sistema esta actualizado
sudo apt update -qq 
sudo apt install -qq -y net-tools
sudo apt install -qq openssh-server -y 

# Configurar la ip estatica
StaticIpConfig

# Cambiar puerto de SSH a 2222
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# Habilitar el puerto 2222 en el firewall
sudo ufw allow 2222/tcp

# Habilitar ssh
sudo systemctl enable ssh

# Iniciar el servidor SSH
sudo systemctl start ssh 

# Reiniciar el servicio SSH para aplicar cambios
sudo systemctl restart ssh

echo "El servidor SSH está ahora configurado para usar el puerto 2222."
