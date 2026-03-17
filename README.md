# Rpi5_aarch64_CHROOT
Transforma tu pc x86_64 con debian/ubuntu o linux mint para hacer compilacion cruzada en este caso para aarch64, con esto puedes compilar programas y paquetes para la rpi5 desde tu pc. "Se recomienda usar pc de trasteo"


Dejo por aqui las dependencias que suelo instalar cuando entro al entorno chroot x primera vez para poder compilar apps para raspberry pi5 con arquitectura arm64 "aarch64"

apt -y install build-essential git wget libdrm-dev python3-full python3-pip python3-setuptools python3-wheel ninja-build libopenal-dev premake4 autoconf libevdev-dev ffmpeg libsnappy-dev libboost-tools-dev magics++ libboost-thread-dev libboost-all-dev pkg-config zlib1g-dev libpng-dev libsdl2-dev clang cmake cmake-data libarchive13 libcurl4 libfreetype6-dev libuv1 mercurial mercurial-common

ln -s /usr/include/libdrm/ /usr/include/drm
