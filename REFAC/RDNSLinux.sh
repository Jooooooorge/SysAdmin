#!/bin/bash
#************************************************************************************************
# SCRIPT para la creación de un servidor DNS en Ubuntu Server

# Actualizar e instalar paquetes necesarios
sudo apt update
sudo apt install -y net-tools bind9 bind9utils dnsutils

# Solicitar al usuario el dominio e IP
read -p "Ingresa el nombre del dominio (Ejemplo: misitio.com): " dominio
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
      gateway4: 192.168.1.254
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4" | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null

# Aplicar cambios de red
sudo netplan apply

# Crear la carpeta donde se guardarán las zonas
sudo mkdir -p /etc/bind/zones

# Preparar la IP invertida para la zona inversa
IFS='.' read -r seg1 seg2 seg3 seg4 <<< "$ip"
ipInvertida="${seg3}.${seg2}.${seg1}"

# Configurar named.conf.options
echo "options {
    directory \"/var/cache/bind\";
    forwarders {
        8.8.8.8;
    };
    dnssec-validation auto;
    listen-on-v6 { any; };
};" | sudo tee /etc/bind/named.conf.options > /dev/null

# Configurar named.conf.local
echo "zone \"$dominio\" IN {
    type master;
    file \"/etc/bind/zones/$dominio\";
};

zone \"$ipInvertida.in-addr.arpa\" IN {
    type master;
    file \"/etc/bind/zones/$dominio.rev\";
};" | sudo tee /etc/bind/named.conf.local > /dev/null

# Configurar la zona primaria
echo "\$TTL    604800
@       IN      SOA     $dominio. root.$dominio. (
                        1         ; Serial
                    604800         ; Refresh
                    86400         ; Retry
                    2419200        ; Expire
                    604800 )       ; Negative Cache TTL

@       IN      NS      ns.$dominio.
@       IN      A       $ip
ns      IN      A       $ip
www     IN      A       $ip" | sudo tee /etc/bind/zones/$dominio > /dev/null

# Configurar la zona inversa
echo "\$TTL    604800
@       IN      SOA     $dominio. root.$dominio. (
                        2         ; Serial
                    604800         ; Refresh
                    86400         ; Retry
                    2419200        ; Expire
                    604800 )       ; Negative Cache TTL

@       IN      NS      ns.$dominio.
$seg4     IN      PTR     $dominio." | sudo tee /etc/bind/zones/$dominio.rev > /dev/null

# Reiniciar el servicio BIND9
sudo systemctl restart bind9

# Permitir tráfico DNS
sudo ufw allow 53
sudo ufw reload
