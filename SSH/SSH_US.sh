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


# Habilitamos ssh
sudo systemctl enable ssh

# Habilitando el puerto 22 para el uso del SSH
sudo ufw allow ssh

# Inciamos el servidor
sudo systemctl start ssh 

