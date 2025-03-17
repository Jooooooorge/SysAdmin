#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH

# Importar funciones
source ./US.sh

# Asegurarnos de que el sistema esta actualizado
sudo apt update -qq
sudo apt install -y net-tools -qq
sudo apt install openssh-server -y -qq

# Configurar la ip estatica
StaticIpConfig


# Habilitamos ssh
sudo systemctl enable ssh

# Habilitando el puerto 22 para el uso del SSH
sudo ufw allow ssh

# Inciamos el servidor
sudo systemctl start ssh 

