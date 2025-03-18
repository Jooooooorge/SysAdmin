#********************************************************************************************************************************
# Declaración de las funciones necesarias para el uso de los scripts

# Función usada para configurar la red estática
# Entrada: 
# Salida: Arreglo con los datos necesarios para la configuración
StaticIpConfig() {
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

    # Capturar Gateway 
    while true; do
        NetSegment=$(ExtractNetSegment "$IpAddress")
        GateWay="$NetSegment.1"
        echo "Puerta de enlace predeterminada: $GateWay"
        read -p "¿Desea cambiarla? [y/n]: " opt
        if [[ "$opt" == "y" || "$opt" == "Y" ]]; then
            while true; do
                read -p "Ingrese el nuevo gateway: " GateWay
                if ValidateIpAddress "$GateWay"; then
                    echo "Gateway capturado correctamente"
                    break
                else
                    echo "Error: La dirección de gateway no es válida. Intente nuevamente."
                fi
            done
        fi
        break
    done

    echo "Máscara de subred configurada automáticamente..."
    echo "Servidor DNS asignado automáticamente..."
    sudo chmod 600 /etc/netplan/00-installer-config.yaml.
    # Configurar IP en la interfaz de red
    NetPrefix=$(CalculateNetMask "$IpAddress")
    if [[ -n "$NetPrefix" ]]; then
        echo "network:
            version: 2
            renderer: networkd
            ethernets:
                enp0s3:
                    dhcp4: no
                    addresses:
                        - $IpAddress/$NetPrefix
                    gateway4: $GateWay
                    nameservers:
                        addresses:
                            - 8.8.8.8
                            - 8.8.4.4" | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
        # Aplicar cambios
        sudo netplan apply

        echo "Configuración de red aplicada correctamente."
    else
        echo "Error: No se pudo calcular la máscara de subred. Verifique la IP ingresada."
    fi
}

# Función para extraer el segmento de red de una IP
ExtractNetSegment() {
    local IP="$1"
    IFS='.' read -r -a Seg <<< "$IP"
    echo "${Seg[0]}.${Seg[1]}.${Seg[2]}"
}

# Función para calcular la máscara de subred en formato de prefijo (CIDR)
CalculateNetMask() {
    local IP="$1"
    IFS='.' read -r -a Seg <<< "$IP"
    local NetSegment=${Seg[0]}

    if (( NetSegment >= 0 && NetSegment <= 127 )); then
        echo 8  # Clase A
    elif (( NetSegment >= 128 && NetSegment <= 191 )); then
        echo 16  # Clase B
    elif (( NetSegment >= 192 && NetSegment <= 223 )); then
        echo 24  # Clase C
    else
        echo ""  # IP no válida
    fi
}

# Función para validar una dirección IP
ValidateIpAddress() {
    local IpAddress="$1"
    local Pattern='^(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|1?[0-9][0-9]?)$'
    [[ "$IpAddress" =~ $Pattern ]]
}

# Función para validar un dominio
ValidateDomain() {
    local Domain="$1"
    local Pattern='^(([a-z]{2,})+\.)+([a-z]{2,})+$'
    [[ "$Domain" =~ $Pattern ]]
}

# ====== ====== ====== ====== ====== ======

function MostrarVersiones {
    echo "========= ========= ========="
    echo " SELECCIONA UN SERVIDOR WEB"
    echo " [0] Apache"
    echo " [1] Nginx"
    echo " [2] Caddy"
    read -p "Selecciona un servidor: " opc

    case $opc in
        0)
            server="apache2"
            echo "===== APACHE ======"
            apt list -a apache2 2>/dev/null | awk -F' ' '{if (NR>1) print $2}'
            ;;
        1)
            server="nginx"
            echo "===== NGINX ======"
            apt list -a nginx 2>/dev/null | awk -F' ' '{if (NR>1) print $2}'
            ;;
        2)
            server="caddy"
            echo "===== CADDY ======"
            curl -s https://api.github.com/repos/caddyserver/caddy/releases | grep '"tag_name":' | awk -F'"' '{print $4}' | head -5
            ;;
        *)
            echo "Opción no válida."
            return 1
            ;;
    esac

    read -p "Selecciona una versión específica: " version
    echo "$server:$version"
}

function InstalarServidor {
    seleccion=$(MostrarVersiones)
    if [[ -z "$seleccion" ]]; then
        echo "Error: No se seleccionó un servidor válido."
        return 1
    fi

    IFS=":" read -r servidor version <<< "$seleccion"

    echo "Instalando $servidor versión $version..."

    case $servidor in
        apache2)
            sudo apt update
            sudo apt install -y apache2="$version"
            ;;
        nginx)
            sudo apt update
            sudo apt install -y nginx="$version"
            ;;
        caddy)
            sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
            curl -1sLf "https://dl.cloudsmith.io/public/caddy/stable/gpg.key" | sudo tee /etc/apt/trusted.gpg.d/caddy.asc
            curl -1sLf "https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt" | sudo tee /etc/apt/sources.list.d/caddy-stable.list
            sudo apt update
            sudo apt install -y caddy
            ;;
        *)
            echo "Error: Servidor no reconocido."
            return 1
            ;;
    esac

    echo "$servidor versión $version instalado correctamente."
}

