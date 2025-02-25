#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH

# Asegurarnos de que el sistema esta actualizado
sudo apt update
sudo apt install openssh-server -y


# Configuración de la red estatica 
echo "network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - 192.168.0.130/24" | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
# Aplicar cambios de red
sudo netplan apply  

# Habilitamos ssh
sudo systemctl enable ssh

# Habilitando el puerto 22 para el uso del SSH
sudo ufw allow ssh

# Inciamos el servidor
sudo systemctl start ssh

