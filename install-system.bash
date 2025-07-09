#!/bin/bash

# Copyright © 2015-2018 Dmytro Katyukha <dmytro.katyukha@gmail.com>

#######################################################################
# This Source Code Form is subject to the terms of the Mozilla Public #
# License, v. 2.0. If a copy of the MPL was not distributed with this #
# file, You can obtain one at http://mozilla.org/MPL/2.0/.            #
#######################################################################

# Definir colores
NC='\e[0m';
REDC='\e[31m';
GREENC='\e[32m';
YELLOWC='\e[33m';
BLUEC='\e[34m';
LBLUEC='\e[94m';

# Script simple para instalar odoo-helper-script a nivel del sistema
if [[ $UID != 0 ]]; then
    echo -e "${REDC}ERROR${NC}: Por favor ejecuta este script con ${YELLOWC}sudo${NC}:"
    echo -e "$ ${BLUEC}sudo $0 $* ${NC}"
    exit 1
fi

# Obtener rama de odoo-helper. Por defecto es master
ODOO_HELPER_BRANCH=${1:-master}

set -e;  # Fallar en cada error

# Instalar git si no está instalado aún
if ! command -v git >/dev/null 2>&1; then
    apt-get install -yqq --no-install-recommends git wget;
fi

# definir variables
ODOO_HELPER_SYS_CONF="/etc/odoo-helper.conf";

# Probar si hay configuración de odoo-helper en el directorio home, lo que significa
# que odoo-helper-scripts puede estar ya instalado
if [ -f "$ODOO_HELPER_SYS_CONF" ]; then
    source $ODOO_HELPER_SYS_CONF;
fi

# Configurar rutas
INSTALL_PATH=${ODOO_HELPER_INSTALL_PATH:-/opt/odoo-helper-scripts};
ODOO_HELPER_LIB=${ODOO_HELPER_LIB:-$INSTALL_PATH/lib};
ODOO_HELPER_BIN=${ODOO_HELPER_BIN:-$INSTALL_PATH/bin};

# clonar repositorio
if [ ! -d $INSTALL_PATH ]; then
    git clone --recurse-submodules -q https://github.com/huntergps/odoo-helper-scripts $INSTALL_PATH;
    (cd $INSTALL_PATH && git checkout -q $ODOO_HELPER_BRANCH && git submodule init && git submodule update);
    # TODO: puede ser una buena idea hacer pull de cambios desde el repositorio si ya existe?
    # TODO: implementar aquí algún tipo de mecanismo de actualización?
fi

# instalar configuración de usuario de odoo-helper
if [ ! -f "$ODOO_HELPER_SYS_CONF" ]; then
    echo "ODOO_HELPER_ROOT=$INSTALL_PATH;"   >> $ODOO_HELPER_SYS_CONF;
    echo "ODOO_HELPER_BIN=$ODOO_HELPER_BIN;" >> $ODOO_HELPER_SYS_CONF;
    echo "ODOO_HELPER_LIB=$ODOO_HELPER_LIB;" >> $ODOO_HELPER_SYS_CONF;
fi

# agregar odoo-helper-bin al path
for oh_cmd in $ODOO_HELPER_BIN/*; do
    if ! command -v $(basename $oh_cmd) >/dev/null 2>&1; then
        ln -s $oh_cmd /usr/local/bin/;
    fi
done

echo -e "${YELLOWC}odoo-helper-scripts${GREENC} parece estar instalado exitosamente a nivel del sistema!${NC}";
echo -e "La ruta de instalación es ${YELLOWC}${INSTALL_PATH}${NC}";
echo;
echo -e "${YELLOWC}NOTA${NC}: No olvides instalar las dependencias del sistema de odoo-helper.";
echo -e "Para hacer esto en sistemas tipo debian ejecuta el siguiente comando (${YELLOWC}acceso sudo requerido${NC}):";
echo -e "    $ ${BLUEC}odoo-helper install pre-requirements${NC}";
echo;
echo -e "${YELLOWC}NOTA2${NC}: No olvides instalar y configurar postgresql.";
echo -e "Para hacer esto en sistemas tipo debian ejecuta el siguiente comando (${YELLOWC}acceso sudo requerido${NC}):";
echo -e "    $ ${BLUEC}odoo-helper install postgres${NC}";
echo -e "O usa el comando de abajo para crear usuario postgres para Odoo también:";
echo -e "    $ ${BLUEC}odoo-helper install postgres odoo odoo${NC}";
echo;
echo -e "Para actualizar odoo-helper-scripts, solo ejecuta el siguiente comando:";
echo -e "    $ ${BLUEC}odoo-helper system update${NC}";

