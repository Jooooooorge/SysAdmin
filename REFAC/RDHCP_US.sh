#********************************************************************************************************************************
# Script para automatizar la creación de un servidor DHCP personalizable


# Actualizar e instalar paquetes necesarios
sudo apt update
sudo apt install -y net-tools
sudo apt install isc-dhcp-server -y

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
        - $IpAddress/24" | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
# Aplicar cambios de red
sudo netplan apply 

# Realizar los siguientes cambios en los arhivos de configuración
# del server DHCP /etc/dhcp/dhcp.conf

echo "default-lease-time 43200;
max-lease-time 86400;
subnet 192.168.0.0 netmask 255.255.255.0 {
  range 192.168.0.51 192.168.0.60;
  option routers 192.168.0.1;
}" | sudo tee /etc/dhcp/dhcpd.conf > /dev/null


echo "INTERFACESv4 = enp0s3" | sudo tee /etc/default/isc-dhcp-server > /dev/null

# Reniciar y habilitar el servicio
sudo systemctl enable isc-dhcp-server

sudo systemctl start isc-dhcp-server

