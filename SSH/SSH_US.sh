#********************************************************************************************************************************
# ACTIVIDAD 4
# Script para automatizar la creación de un servidor SSH

# Importar funciones
source US.sh

# Asegurarnos de que el sistema esta actualizado
sudo apt update
sudo apt install -y net-tools
sudo apt install openssh-server -y

 # Capturar IP
while true; do
    read -p "Ingrese la dirección IP: " IpAddress
    if ValidateIpAddress "$IpAddress"; then
        echo "Dirección IP capturada correctamente"
        break
    else
        echo "Error: La dirección IP ingresada no es válida. Intente nuevamente."
    fi
done
# Configuración de la red estatica 
echo "network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: false
      addresses:
        - $IpAddress/24
      gateway4: 192.168.0.1" | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
# Aplicar cambios de red
sudo netplan apply  

# Habilitamos ssh
sudo systemctl enable ssh

# Habilitando el puerto 22 para el uso del SSH
sudo ufw allow ssh

# Inciamos el servidor
sudo systemctl start ssh

