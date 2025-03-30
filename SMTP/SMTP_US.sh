#!/bin/bash
# ========= ========= ========= ========= ========= ========= ========= ========= ========= =========
# Practica 8
# Descripción:
# Hacer el script para generar un servidor de correos que utilice SMTP y POP3, 
# como cliente se utlizara Mutt, SquirellMail u otra opción

# Importar funciones
# source ./F_SMTP_US.sh
source ../FUNC/F_SMTP_US.sh

opc=$(mostrarMenu)

echo "Opción seleccionada: $opc"