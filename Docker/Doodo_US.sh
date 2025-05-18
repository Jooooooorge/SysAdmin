#!/bin/bash
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
sudo docker --version

# Iniciar y habilitar el servicio Docker
sudo systemctl start docker
sudo systemctl enable docker

# Añadir tu usuario al grupo docker para evitar usar sudo
sudo usermod -aG docker $USER

# Buscar imágenes de Apache en Docker Hub
docker search httpd

# Descargar la imagen oficial de Apache
docker pull httpd:latest

# Ejecutar un contenedor de Apache en el puerto 8080
docker run -d --name mi-apache -p 8080:80 httpd:latest

# Verificar que el contenedor esté en ejecución
docker ps

# Crear un directorio para el contenido personalizado
mkdir -p ~/mi-sitio-web

# Crear un archivo index.html personalizado
cat > ~/mi-sitio-web/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Mi Sitio Personalizado</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .container {
            background-color: #f9f9f9;
            border-radius: 5px;
            padding: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Sitio Web Personalizado con Docker</h1>
        <p>Esta es una página personalizada para el contenedor Apache.</p>
        <p>Creado como parte del ejercicio de Docker.</p>
    </div>
</body>
</html>
EOF

# Detener y eliminar el contenedor anterior
docker stop mi-apache
docker rm mi-apache

# Crear un nuevo contenedor montando el directorio con el contenido personalizado
docker run -d --name mi-apache-personalizado -p 8080:80 -v ~/mi-sitio-web:/usr/local/apache2/htdocs/ httpd:latest

# Verificar que el contenedor esté funcionando
docker ps

# Crear un directorio para el Dockerfile
mkdir -p ~/apache-personalizado
cd ~/apache-personalizado

# Crear el archivo index.html que estará en la imagen
cat > index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Mi Imagen Personalizada</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #1e3a8a;
            border-bottom: 2px solid #3b82f6;
            padding-bottom: 10px;
        }
        .container {
            background-color: #ffffff;
            border-radius: 8px;
            padding: 25px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        footer {
            margin-top: 20px;
            text-align: center;
            font-size: 0.8em;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Apache en Contenedor Docker Personalizado</h1>
        <p>Esta página viene pre-instalada en la imagen personalizada de Docker.</p>
        <p>La imagen fue construida utilizando un Dockerfile personalizado.</p>
    </div>
    <footer>
        Creado para prácticas con Docker
    </footer>
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

# Construir la imagen personalizada
docker build -t mi-apache-imagen:v1 .

# Detener y eliminar el contenedor anterior
docker stop mi-apache-personalizado
docker rm mi-apache-personalizado

# Ejecutar un contenedor usando la nueva imagen personalizada
docker run -d --name mi-apache-desde-imagen -p 8080:80 mi-apache-imagen:v1

# Verificar que está funcionando
docker ps

# Crear una red de Docker para la comunicación entre contenedores
docker network create mi-red-postgres

# Ejecutar el primer contenedor PostgreSQL
docker run -d \
    --name postgres1 \
    --network mi-red-postgres \
    -e POSTGRES_PASSWORD=password123 \
    -e POSTGRES_USER=usuario \
    -e POSTGRES_DB=basedatos \
    postgres:latest

# Ejecutar el segundo contenedor PostgreSQL 
docker run -d \
    --name postgres2 \
    --network mi-red-postgres \
    -e POSTGRES_PASSWORD=password123 \
    -e POSTGRES_USER=usuario \
    -e POSTGRES_DB=basedatos \
    postgres:latest

# Esperar unos segundos para que los contenedores se inicien completamente
sleep 10

# Probar la conexión desde postgres1 a postgres2
docker exec -it postgres1 bash -c "apt-get update && apt-get install -y postgresql-client && PGPASSWORD=password123 psql -h postgres2 -U usuario -d basedatos -c 'SELECT version();'"

# Probar la conexión desde postgres2 a postgres1
docker exec -it postgres2 bash -c "apt-get update && apt-get install -y postgresql-client && PGPASSWORD=password123 psql -h postgres1 -U usuario -d basedatos -c 'SELECT version();'"

# Crear una tabla de prueba en postgres1
docker exec -it postgres1 bash -c "PGPASSWORD=password123 psql -U usuario -d basedatos -c 'CREATE TABLE prueba (id SERIAL PRIMARY KEY, mensaje VARCHAR(100));'"
docker exec -it postgres1 bash -c "PGPASSWORD=password123 psql -U usuario -d basedatos -c \"INSERT INTO prueba (mensaje) VALUES ('Hola desde postgres1');\""

# Verificar que se puede acceder a la tabla desde postgres2
docker exec -it postgres2 bash -c "PGPASSWORD=password123 psql -h postgres1 -U usuario -d basedatos -c 'SELECT * FROM prueba;'"