#!/bin/bash
set -e


# Nombres de contenedores e imágenes
APACHE_CONTAINER="apache-temp"
CUSTOM_IMAGE="my-apache-custom"
CUSTOM_CONTAINER="mi-apache"
NETWORK_NAME="pg-network"
PG1_CONTAINER="pg1"
PG2_CONTAINER="pg2"
PG1_USER="user1"
PG1_DB="db1"
PG1_PASS="pass1"
PG2_USER="user2"
PG2_DB="db2"
PG2_PASS="pass2"
HOST_PORT_APACHE=8080
HOST_PORT_CUSTOM=8090

# Detecta IP en WSL para acceder desde Windows (WSL2)
detect_wsl_ip() {
  if grep -qiE "microsoft|wsl" /proc/version >/dev/null 2>&1; then
    ip addr show eth0 | awk '/inet /{sub(/\/.*$/, "", $2); print $2; exit}'
  fi
}

install_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "*** Instalando Docker..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable docker
    echo "✔ Docker instalado."
  else
    echo "✔ Docker ya está instalado."
  fi
}

modify_index() {
  echo "*** Personalizar index.html"
  read -p "¿Usar plantilla básica? [s/N]: " resp
  if [[ "$resp" =~ ^[Nn]$ ]]; then
    read -p "Ruta de tu index.html: " ruta
    [[ -f "$ruta" ]] || { echo "¡Archivo no encontrado!"; return 1; }
    CIFILE="$ruta"
  else
    CIFILE=$(mktemp)
    cat > "$CIFILE" <<'EOF'
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Personalizado</title></head>
<body>
  <h1>Sitio de Joooooorge</h1>
</body>
</html>
EOF
  fi
  docker cp "$CIFILE" $APACHE_CONTAINER:/usr/local/apache2/htdocs/index.html
  docker exec $APACHE_CONTAINER chmod 644 /usr/local/apache2/htdocs/index.html
  rm -f "$CIFILE"
  echo "✔ index.html desplegado."
}

build_image() {
  echo "*** Creando imagen: $CUSTOM_IMAGE"
  docker ps -a --format '{{.Names}}' | grep -q "^${APACHE_CONTAINER}$" || { echo "Inicia Apache primero (opción 2)."; return 1; }
  docker commit $APACHE_CONTAINER $CUSTOM_IMAGE:latest
  echo "✔ Imagen $CUSTOM_IMAGE:latest lista."
}

setup_postgres() {
  echo "*** Configurando PostgreSQL en red $NETWORK_NAME..."
  docker network create $NETWORK_NAME >/dev/null 2>&1 || true
  for c in $PG1_CONTAINER $PG2_CONTAINER; do docker rm -f $c >/dev/null 2>&1 || true; done
  docker run -d --name $PG1_CONTAINER --network $NETWORK_NAME -e POSTGRES_USER=$PG1_USER -e POSTGRES_PASSWORD=$PG1_PASS -e POSTGRES_DB=$PG1_DB postgres:latest
  docker run -d --name $PG2_CONTAINER --network $NETWORK_NAME -e POSTGRES_USER=$PG2_USER -e POSTGRES_PASSWORD=$PG2_PASS -e POSTGRES_DB=$PG2_DB postgres:latest
  echo "✔ pg1(db1) y pg2(db2) corriendo."
}
seed_data() {
  echo "*** Creando tablas y datos de ejemplo..."
  docker exec -e PGPASSWORD=$PG1_PASS $PG1_CONTAINER psql -U $PG1_USER -d $PG1_DB -c "
  CREATE TABLE IF NOT EXISTS persona(id SERIAL PRIMARY KEY, nombre TEXT, apellido TEXT);" -c "
  INSERT INTO persona(nombre, apellido) VALUES ('Jorge', Aguilar);"
  docker exec -e PGPASSWORD=$PG2_PASS $PG2_CONTAINER psql -U $PG2_USER -d $PG2_DB -c "CREATE TABLE IF NOT EXISTS producto(id SERIAL PRIMARY KEY, descripcion TEXT);" -c "INSERT INTO producto(descripcion) SELECT 'Muestra' WHERE NOT EXISTS (SELECT 1 FROM producto);"
  echo "✔ Tablas y datos creados."
}

authlogin_pg1() {
  echo "*** psql en pg1/db1"
  docker exec -e PGPASSWORD=$PG1_PASS -it $PG1_CONTAINER psql -U $PG1_USER -d $PG1_DB
}

authlogin_pg2() {
  echo "*** psql en pg2/db2"
  docker exec -e PGPASSWORD=$PG2_PASS -it $PG2_CONTAINER psql -U $PG2_USER -d $PG2_DB
}

setup() {
    install_docker
    setup_postgres
    seed_data
}

newImage() {
    modify_index
    build_image
}

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----  ----- ----- ----- ----- ----- ----- ----- -----
setup 

while true; do
    cat <<EOF
Menu
1) Iniciar Apache Default
2) Modificar index.html
3) Ejecutar Apache custom
4) Iniciar psql en cont 1
5) Iniciar psql en cont 2
EOF
 read -p "Seleccione una opción: " opc
    case $opc in
        1) start_apache ;;
        2) newImage ;;
        3) run_custom ;;
        4) authlogin_pg1 ;;
        5) authlogin_pg2 ;;
        *) echo "Opción invalida" ;;

    esac
done
