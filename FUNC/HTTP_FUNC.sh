# Función utilizada para imprimir el menu

functiom(){
    Echo " ========= ========= ========="
    Echo " SERVIDOES WEB DISPONIBLES"
    Echo " [0] Apache"
    Echo " [1] Ejemplo"
    Echo " [2] Ejemplo"
    Echo " Selecciona un servidor"
    read opc

    if [$opc -eq 0 -o $opc -eq 1 -o $opc -eq 2 ]; then
        echo "Elegiste $opc"
        return $opc
    else
        echo "Elegiste una opción no valida"
    fi
}
