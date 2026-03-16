#!/bin/bash

# Comprobar root
if [ "$EUID" -ne 0 ]; then 
  echo "Error: Ejecuta con sudo (sudo ./rpi_aarch64_chroot-mgr.sh)"
  exit 1
fi

# Carpeta base para tus entornos
BASE_PATH="/mnt/data/arm64_rpi5"
mkdir -p "$BASE_PATH"

show_menu() {
    echo ""
    echo "--- GESTOR CHROOT RPI5 (AARCH64) ---"
    echo "1) Instalar y Configurar nuevo entorno (Buster, Bookworm, Trixie...)"
    echo "2) Montar y Entrar al entorno"
    echo "3) Desmontar entorno"
    echo "4) Salir"
    read -p "Selecciona una opción: " OPT
}

check_mounted() {
    mountpoint -q "$1/proc"
}

manage_mounts() {
    local TARGET=$1
    local ACTION=$2

    if [ "$ACTION" == "mount" ]; then
        if check_mounted "$TARGET"; then
            echo "[!] El entorno ya está montado."
        else
            echo "[*] Montando sistemas de archivos en $TARGET..."
            for dir in /dev /dev/pts /proc /sys /run; do
                mkdir -p "$TARGET$dir"
                mount --bind "$dir" "$TARGET$dir"
            done
            cp /etc/resolv.conf "$TARGET/etc/resolv.conf"
        fi
    else
        echo "[*] Desmontando $TARGET..."
        umount -R "$TARGET" 2>/dev/null || echo "[!] Ya estaba desmontado o hay procesos en uso."
    fi
}

while true; do
    show_menu
    case $OPT in
        1)
            read -p "Introduce la versión deseada (ej: buster, bookworm, trixie): " RELEASE
            RELEASE=${RELEASE:-bookworm}
            TARGET_DIR="$BASE_PATH/chroot_$RELEASE"

            if [ -d "$TARGET_DIR" ] && [ "$(ls -A $TARGET_DIR)" ]; then
                echo "[!] El directorio ya existe y no está vacío. Abortando instalación."
                continue
            fi

            echo "[*] Instalando herramientas y claves de Debian..."
            apt update && apt install -y qemu-user-static binfmt-support debootstrap debian-archive-keyring

            echo "[*] Iniciando descarga de $RELEASE (arch=arm64)..."
            # Se añade --keyring para evitar errores de validación de descarga
            if ! debootstrap --arch=arm64 --foreign --keyring=/usr/share/keyrings/debian-archive-keyring.gpg "$RELEASE" "$TARGET_DIR" http://deb.debian.org/debian; then
                echo "[X] Error crítico: No se pudo descargar la release. Revisa tu conexión o el nombre de la versión."
                rm -rf "$TARGET_DIR"
                continue
            fi

            cp /usr/bin/qemu-aarch64-static "$TARGET_DIR/usr/bin/"
            manage_mounts "$TARGET_DIR" "mount"

            echo "[*] Ejecutando segunda etapa (configuración interna)..."
            chroot "$TARGET_DIR" /usr/bin/qemu-aarch64-static /bin/bash -c "/debootstrap/debootstrap --second-stage"
            
            echo "[*] Instalando herramientas de compilación..."
            chroot "$TARGET_DIR" /usr/bin/qemu-aarch64-static /bin/bash -c "apt update && apt install -y build-essential git cmake"
            
            echo "--- Instalación de $RELEASE finalizada con éxito ---"
            ;;
            
        2)
            echo "Entornos disponibles en $BASE_PATH:"
            ls "$BASE_PATH"
            read -p "Carpeta del entorno a usar: " FOLDER
            TARGET_DIR="$BASE_PATH/$FOLDER"
            
            if [ -d "$TARGET_DIR" ] && [ -f "$TARGET_DIR/usr/bin/qemu-aarch64-static" ]; then
                manage_mounts "$TARGET_DIR" "mount"
                echo "[*] Entrando... (Escribe 'exit' para salir)"
                chroot "$TARGET_DIR" /usr/bin/qemu-aarch64-static /bin/bash
            else
                echo "[!] El entorno no parece válido o no existe."
            fi
            ;;
            
        3)
            echo "Entornos en $BASE_PATH:"
            ls "$BASE_PATH"
            read -p "Carpeta a desmontar: " FOLDER
            manage_mounts "$BASE_PATH/$FOLDER" "umount"
            ;;
            
        4) exit 0 ;;
        *) echo "Opción no válida." ;;
    esac
done