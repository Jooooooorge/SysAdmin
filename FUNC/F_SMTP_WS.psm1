function mostrarMenu {
    write-host "[1] Crear Usuario"
    Write-host "Selecciona una opción:"
    $opc = read-host
    return $opc
}

function configSMTP {
    param (
        
    )
    # Verifircar que la caracteristica SMTP esta instalada.
    $smtp = get-WindowsFeature -name web-server
    if(-not $smtp.Installed){
        write-host "Dependencias no esta instaladas, instalandose..." -ForegroundColor red
        Write-Host "Instalando IIS" -ForegroundColor Red
        Install-WindowsFeature -name web-server
        write-Host "Instalando MGMT" -ForegroundColor Red
        Install-WindowsFeature -name web-Mgmt-console
    }
    else{
        write-host "Dependencias ya instaladas" -ForegroundColor Green
        sleep 2
    }

    # Configurar Serivodr
    
}