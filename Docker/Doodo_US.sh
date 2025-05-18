#!/bin/bash
# Script para preparar entorno Docker con menú de opciones
# Instala Docker, prepara archivos y permite ejecutar comandos a través de un menú

# Función para mostrar mensajes con colores
mostrar_mensaje() {
    local color=$1
    local mensaje=$2
    
    case $color in
        "rojo") echo -e "\e[31m$mensaje\e[0m" ;;
        "verde") echo -e "\e[32m$mensaje\e[0m" ;;
        "amarillo") echo -e "\e[33m$mensaje\e[0m" ;;
        "azul") echo -e "\e[34m$mensaje\e[0m" ;;
        "magenta") echo -e "\e[35m$mensaje\e[0m" ;;
        "cian") echo -e "\e[36m$mensaje\e[0m" ;;
        *) echo "$mensaje" ;;
    esac
}

# Función para verificar la instalación de Docker
verificar_instalar_docker() {
    echo "====== VERIFICANDO INSTALACIÓN DE DOCKER ======"

    if command -v docker &> /dev/null; then
        mostrar_mensaje verde "Docker ya está instalado. Versión:"
        docker --version
        # Si docker está instalado, establecemos el comando para usar
        DOCKER_CMD="docker"
    else
        mostrar_mensaje amarillo "Docker no está instalado. Procediendo a instalar..."
        
        # Actualizar repositorios
        sudo apt update
        
        # Instalar dependencias necesarias
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        
        # Añadir clave GPG oficial de Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Añadir el repositorio de Docker a las fuentes de APT
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Actualizar la base de datos de paquetes
        sudo apt update
        
        # Instalar Docker
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        
        # Verificar que Docker esté instalado correctamente
        if command -v docker &> /dev/null; then
            mostrar_mensaje verde "Docker se ha instalado correctamente. Versión:"
            docker --version
            # Establecemos el comando para usar
            DOCKER_CMD="docker"
        else
            mostrar_mensaje rojo "Error: No se pudo instalar Docker. Verifica la instalación manualmente."
            exit 1
        fi
        
        # Iniciar y habilitar el servicio Docker
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Añadir usuario al grupo docker para evitar usar sudo
        sudo usermod -aG docker $USER
        mostrar_mensaje amarillo "NOTA: Es posible que necesites cerrar sesión y volver a iniciarla para usar Docker sin sudo."
        mostrar_mensaje amarillo "Si prefieres continuar ahora, puedes usar 'sudo docker' en los comandos siguientes."
        
        # Si el usuario no puede usar docker sin sudo todavía, usamos sudo docker
        if ! docker ps &>/dev/null; then
            DOCKER_CMD="sudo docker"
        fi
    fi
}

# Función para preparar entorno Apache
preparar_apache() {
    mostrar_mensaje azul "====== PREPARANDO ENTORNO PARA APACHE ======"

    # Verificar si ya existe la imagen de Apache
    if $DOCKER_CMD images --format "{{.Repository}}:{{.Tag}}" | grep -q "^httpd:latest$"; then
        mostrar_mensaje verde "La imagen de Apache (httpd:latest) ya está descargada."
    else
        mostrar_mensaje amarillo "Descargando imagen de Apache..."
        $DOCKER_CMD pull httpd:latest
        
        if [ $? -eq 0 ]; then
            mostrar_mensaje verde "Imagen de Apache descargada correctamente."
        else
            mostrar_mensaje rojo "Error al descargar la imagen de Apache."
            return 1
        fi
    fi

    # Crear directorio para el contenido personalizado si no existe
    if [ ! -d ~/mi-sitio-web ]; then
        mkdir -p ~/mi-sitio-web
        mostrar_mensaje verde "Directorio ~/mi-sitio-web creado."
    else
        mostrar_mensaje verde "El directorio ~/mi-sitio-web ya existe."
    fi

    # Crear un archivo index.html personalizado
    cat > ~/mi-sitio-web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Mi Sitio Personalizado</title>
</head>
<body>
        <h1>It Works!</h1>
</body>
</html>
EOF

    mostrar_mensaje verde "Archivo index.html creado en ~/mi-sitio-web/"
    mostrar_mensaje cian "Para ejecutar un contenedor Apache con tu página personalizada, usa este comando:"
    mostrar_mensaje cian "$DOCKER_CMD run -d --name mi-apache-personalizado -p 8080:80 -v ~/mi-sitio-web:/usr/local/apache2/htdocs/ httpd:latest"

    # Preparar archivos para imagen personalizada
    mostrar_mensaje azul "Preparando archivos para imagen personalizada..."

    # Crear directorio para el Dockerfile si no existe
    if [ ! -d ~/apache-personalizado ]; then
        mkdir -p ~/apache-personalizado
        mostrar_mensaje verde "Directorio ~/apache-personalizado creado."
    else
        mostrar_mensaje verde "El directorio ~/apache-personalizado ya existe."
    fi

    cd ~/apache-personalizado

    # Crear el archivo index.html que estará en la imagen
    cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Mi Imagen Personalizada</title>
</head>
<body>
        <h1>Sitio de jorge!!!</h1>
</body>
</html>
EOF

    # Crear el Dockerfile
    cat > Dockerfile << 'EOF'
# Usar la imagen base de Apache
FROM httpd:latest

# Copiar nuestro archivo index.html al directorio htdocs del contenedor
COPY index.html /usr/local/apache2/htdocs/

# Exponer el puerto 80
EXPOSE 80

# Comando por defecto
CMD ["httpd-foreground"]
EOF

    mostrar_mensaje verde "Archivos index.html y Dockerfile creados en ~/apache-personalizado/"

    # Mostrar comandos para construir la imagen y ejecutar el contenedor
    mostrar_mensaje cian "Para construir tu imagen personalizada, ejecuta:"
    mostrar_mensaje cian "cd ~/apache-personalizado && $DOCKER_CMD build -t mi-apache-imagen:v1 ."

    mostrar_mensaje cian "Para ejecutar un contenedor con tu imagen personalizada, usa:"
    mostrar_mensaje cian "$DOCKER_CMD run -d --name mi-apache-desde-imagen -p 8080:80 mi-apache-imagen:v1"
}

# Función para preparar y configurar PostgreSQL
configurar_postgresql() {
    mostrar_mensaje azul "====== PREPARANDO ENTORNO PARA POSTGRESQL ======"
    
    # Verificar si ya existe la red Docker
    if $DOCKER_CMD network ls --format "{{.Name}}" | grep -q "^mi-red-postgres$"; then
        mostrar_mensaje verde "La red 'mi-red-postgres' ya existe."
    else
        # Crear una red de Docker para la comunicación entre contenedores
        mostrar_mensaje amarillo "Creando red Docker 'mi-red-postgres'..."
        $DOCKER_CMD network create mi-red-postgres
        
        if [ $? -eq 0 ]; then
            mostrar_mensaje verde "Red 'mi-red-postgres' creada exitosamente."
        else
            mostrar_mensaje rojo "Error al crear la red 'mi-red-postgres'."
            return 1
        fi
    fi

    # Mostrar un submenú para PostgreSQL
    while true; do
        echo
        mostrar_mensaje magenta "========== MENÚ POSTGRESQL =========="
        mostrar_mensaje magenta "1. Crear contenedor postgres1"
        mostrar_mensaje magenta "2. Crear contenedor postgres2"
        mostrar_mensaje magenta "3. Probar conexión de postgres1 a postgres2"
        mostrar_mensaje magenta "4. Probar conexión de postgres2 a postgres1"
        mostrar_mensaje magenta "5. Crear tabla de prueba en postgres1"
        mostrar_mensaje magenta "6. Consultar tabla desde postgres2"
        mostrar_mensaje magenta "7. Volver al menú principal"
        echo
        read -p "Seleccione una opción (1-7): " opcion_pg
        
        case $opcion_pg in
            1)
                mostrar_mensaje amarillo "Creando contenedor postgres1..."
                $DOCKER_CMD run -d \
                    --name postgres1 \
                    --network mi-red-postgres \
                    -e POSTGRES_PASSWORD=password123 \
                    -e POSTGRES_USER=usuario \
                    -e POSTGRES_DB=basedatos \
                    postgres:latest
                if [ $? -eq 0 ]; then
                    mostrar_mensaje verde "Contenedor postgres1 creado exitosamente."
                else
                    mostrar_mensaje rojo "Error al crear el contenedor postgres1."
                fi
                ;;
            2)
                mostrar_mensaje amarillo "Creando contenedor postgres2..."
                $DOCKER_CMD run -d \
                    --name postgres2 \
                    --network mi-red-postgres \
                    -e POSTGRES_PASSWORD=password123 \
                    -e POSTGRES_USER=usuario \
                    -e POSTGRES_DB=basedatos \
                    postgres:latest
                if [ $? -eq 0 ]; then
                    mostrar_mensaje verde "Contenedor postgres2 creado exitosamente."
                else
                    mostrar_mensaje rojo "Error al crear el contenedor postgres2."
                fi
                ;;
            3)
                mostrar_mensaje amarillo "Probando conexión de postgres1 a postgres2..."
                $DOCKER_CMD exec -it postgres1 bash -c "apt-get update && apt-get install -y postgresql-client && PGPASSWORD=password123 psql -h postgres2 -U usuario -d basedatos -c 'SELECT version();'"
                if [ $? -eq 0 ]; then
                    mostrar_mensaje verde "Conexión exitosa de postgres1 a postgres2."
                else
                    mostrar_mensaje rojo "Error en la conexión de postgres1 a postgres2."
                fi
                ;;
            4)
                mostrar_mensaje amarillo "Probando conexión de postgres2 a postgres1..."
                $DOCKER_CMD exec -it postgres2 bash -c "apt-get update && apt-get install -y postgresql-client && PGPASSWORD=password123 psql -h postgres1 -U usuario -d basedatos -c 'SELECT version();'"
                if [ $? -eq 0 ]; then
                    mostrar_mensaje verde "Conexión exitosa de postgres2 a postgres1."
                else
                    mostrar_mensaje rojo "Error en la conexión de postgres2 a postgres1."
                fi
                ;;
            5)
                mostrar_mensaje amarillo "Creando tabla de prueba en postgres1..."
                $DOCKER_CMD exec -it postgres1 bash -c "PGPASSWORD=password123 psql -U usuario -d basedatos -c 'CREATE TABLE IF NOT EXISTS prueba (id SERIAL PRIMARY KEY, mensaje VARCHAR(100));'"
                $DOCKER_CMD exec -it postgres1 bash -c "PGPASSWORD=password123 psql -U usuario -d basedatos -c \"INSERT INTO prueba (mensaje) VALUES ('Hola desde postgres1');\""
                if [ $? -eq 0 ]; then
                    mostrar_mensaje verde "Tabla creada y datos insertados exitosamente en postgres1."
                else
                    mostrar_mensaje rojo "Error al crear la tabla o insertar datos en postgres1."
                fi
                ;;
            6)
                mostrar_mensaje amarillo "Consultando tabla desde postgres2..."
                $DOCKER_CMD exec -it postgres2 bash -c "PGPASSWORD=password123 psql -h postgres1 -U usuario -d basedatos -c 'SELECT * FROM prueba;'"
                if [ $? -eq 0 ]; then
                    mostrar_mensaje verde "Consulta exitosa desde postgres2."
                else
                    mostrar_mensaje rojo "Error al consultar desde postgres2."
                fi
                ;;
            7)
                mostrar_mensaje verde "Volviendo al menú principal..."
                return 0
                ;;
            *)
                mostrar_mensaje rojo "Opción inválida. Por favor, seleccione una opción válida (1-7)."
                ;;
        esac
    done
}

# Función para mostrar información del sistema
mostrar_info_sistema() {
    mostrar_mensaje azul "====== INFORMACIÓN DEL SISTEMA ======"
    
    echo "Sistema operativo:"
    cat /etc/os-release | grep "PRETTY_NAME" | cut -d "=" -f 2 | tr -d '"'
    
    echo -e "\nKernel:"
    uname -r
    
    echo -e "\nMemoria RAM:"
    free -h | grep Mem
    
    echo -e "\nEspacio en disco:"
    df -h / | tail -n 1
    
    echo -e "\nContenedores Docker en ejecución:"
    $DOCKER_CMD ps
    
    echo -e "\nImágenes Docker disponibles:"
    $DOCKER_CMD images
    
    echo -e "\nRedes Docker:"
    $DOCKER_CMD network ls
}

# Inicializar la variable DOCKER_CMD
DOCKER_CMD="docker"

# Verificar/Instalar Docker primero
verificar_instalar_docker

# Menú principal
while true; do
    echo
    mostrar_mensaje magenta "========== MENÚ PRINCIPAL =========="
    mostrar_mensaje magenta "1. Preparar entorno Apache"
    mostrar_mensaje magenta "2. Configurar PostgreSQL"
    mostrar_mensaje magenta "3. Mostrar información del sistema"
    mostrar_mensaje magenta "4. Salir"
    echo
    read -p "Seleccione una opción (1-4): " opcion
    
    case $opcion in
        1)
            preparar_apache
            ;;
        2)
            configurar_postgresql
            ;;
        3)
            mostrar_info_sistema
            ;;
        4)
            mostrar_mensaje verde "¡Gracias por usar el script de preparación Docker!"
            exit 0
            ;;
        *)
            mostrar_mensaje rojo "Opción inválida. Por favor, seleccione una opción válida (1-4)."
            ;;
    esac
done