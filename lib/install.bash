# Copyright © 2015-2018 Dmytro Katyukha <dmytro.katyukha@gmail.com>

#######################################################################
# This Source Code Form is subject to the terms of the Mozilla Public #
# License, v. 2.0. If a copy of the MPL was not distributed with this #
# file, You can obtain one at http://mozilla.org/MPL/2.0/.            #
#######################################################################

if [ -z "$ODOO_HELPER_LIB" ]; then
    echo "Odoo-helper-scripts seems not been installed correctly.";
    echo "Reinstall it (see Readme on https://github.com/huntergps/odoo-helper-scripts/)";
    exit 1;
fi

if [ -z "$ODOO_HELPER_COMMON_IMPORTED" ]; then
    source "$ODOO_HELPER_LIB/common.bash";
fi

# ----------------------------------------------------------------------------------------
ohelper_require "config";
ohelper_require "postgres";
ohelper_require "odoo";


set -e; # fail on errors

DEFAULT_ODOO_REPO="https://github.com/odoo/odoo.git";
MINIMUM_SUPPORTED_VERSION=17.0

# Validar versión de Odoo - Solo 17+ permitido
function validate_odoo_version {
    local version=$1;
    
    if [ -z "$version" ]; then
        echoe -e "${REDC}ERROR${NC}: Versión de Odoo no especificada";
        return 1;
    fi
    
    # Extraer versión numérica
    local numeric_version;
    if [[ "$version" == saas-* ]]; then
        # Para versiones SaaS como saas-18.1, saas-18.2, saas-18.3
        numeric_version="${version#saas-}";
    else
        # Para versiones estándar como 17.0, 18.0
        numeric_version="$version";
    fi
    
    # Convertir a formato comparable (17.0 -> 1700, 18.3 -> 1830)
    local major;
    local minor;
    if [[ "$numeric_version" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        major="${BASH_REMATCH[1]}";
        minor="${BASH_REMATCH[2]}";
    elif [[ "$numeric_version" =~ ^([0-9]+)$ ]]; then
        major="$numeric_version";
        minor="0";
    else
        echoe -e "${REDC}ERROR${NC}: Formato de versión inválido: $version";
        echoe -e "${YELLOWC}Versiones soportadas: 17.0, 18.0, saas-18.1, saas-18.2, saas-18.3, etc.${NC}";
        return 1;
    fi
    
    local version_number=$((major * 100 + minor));
    local min_version_number=1700; # 17.0
    
    if [ "$version_number" -lt "$min_version_number" ]; then
        echoe -e "${REDC}ERROR${NC}: Versión de Odoo ${YELLOWC}$version${NC} no soportada.";
        echoe -e "${YELLOWC}Odoo-helper-scripts solo soporta Odoo 17.0 o superior.${NC}";
        echoe -e "${BLUEC}Razones:${NC}";
        echoe -e "  • Python 3.8+ requerido";
        echoe -e "  • Arquitectura moderna de Odoo";
        echoe -e "  • Dependencias actualizadas";
        echoe -e "  • Mejor compatibilidad y rendimiento";
        echoe -e "${YELLOWC}Versiones soportadas: 17.0, 18.0, saas-18.1, saas-18.2, saas-18.3${NC}";
        return 1;
    fi
    
    return 0;
}

# Set-up defaul values for environment variables
function install_preconfigure_env {
    ODOO_REPO=${ODOO_REPO:-$DEFAULT_ODOO_REPO};
    ODOO_VERSION=${ODOO_VERSION:-saas-18.3};
    ODOO_BRANCH=${ODOO_BRANCH:-$ODOO_VERSION};
    DOWNLOAD_ARCHIVE=${ODOO_DOWNLOAD_ARCHIVE:-${DOWNLOAD_ARCHIVE:-on}};
    CLONE_SINGLE_BRANCH=${CLONE_SINGLE_BRANCH:-on};
    DB_USER=${DB_USER:-${ODOO_DBUSER:-odoo}};
    DB_PASSWORD=${DB_PASSWORD:-${ODOO_DBPASSWORD:-odoo}};
    DB_HOST=${DB_HOST:-${ODOO_DBHOST:-localhost}};
    DB_PORT=${DB_PORT:-${ODOO_DBPORT:-5432}};
    
    # Validar versión de Odoo al configurar entorno
    if ! validate_odoo_version "$ODOO_VERSION"; then
        echoe -e "${REDC}ABORTANDO INSTALACIÓN${NC}: Versión de Odoo no soportada";
        return 1;
    fi
}

# create directory tree for project
function install_create_project_dir_tree {
    # create dirs is imported from common module
    create_dirs "$PROJECT_ROOT_DIR" \
        "$ADDONS_DIR" \
        "$CONF_DIR" \
        "$LOG_DIR" \
        "$LIBS_DIR" \
        "$DOWNLOADS_DIR" \
        "$BACKUP_DIR" \
        "$REPOSITORIES_DIR" \
        "$BIN_DIR" \
        "$DATA_DIR";
}

# install_clone_odoo [path [branch [repo]]]
function install_clone_odoo {
    # Verificar si el directorio ya existe
    if [ -d "$ODOO_PATH" ]; then
        echoe -e "${YELLOWC}El directorio ${BLUEC}${ODOO_PATH}${YELLOWC} ya existe.${NC}";
        echoe -e "${BLUEC}Verificando si es un repositorio Git válido...${NC}";
        
        # Verificar si es un repositorio Git válido
        if [ -d "$ODOO_PATH/.git" ]; then
            echoe -e "${GREENC}✓${NC} Repositorio Git encontrado. Saltando descarga...";
            echoe -e "${BLUEC}Para forzar una nueva descarga, elimina el directorio: ${YELLOWC}rm -rf $ODOO_PATH${NC}";
            return 0;
        else
            echoe -e "${YELLOWC}El directorio existe pero no es un repositorio Git válido.${NC}";
            echoe -e "${BLUEC}Eliminando directorio existente...${NC}";
            rm -rf "$ODOO_PATH";
        fi
    fi

    local git_opt=( );

    if [ -n "$ODOO_BRANCH" ]; then
        git_opt+=( --branch "$ODOO_BRANCH" );
    fi

    if [ "$CLONE_SINGLE_BRANCH" == "on" ]; then
        git_opt+=( --single-branch );
    fi

    echoe -e "${BLUEC}Clonando repositorio Odoo desde ${YELLOWC}${ODOO_REPO:-$DEFAULT_ODOO_REPO}${NC}";
    echoe -e "${BLUEC}Rama: ${YELLOWC}${ODOO_BRANCH:-master}${NC}";
    echoe -e "${BLUEC}Directorio destino: ${YELLOWC}${ODOO_PATH}${NC}";
    
    # Mostrar progreso con git clone
    if ! git clone --progress "${git_opt[@]}" \
        "${ODOO_REPO:-$DEFAULT_ODOO_REPO}" \
        "$ODOO_PATH" 2>&1 | while read -r line; do
        if [[ "$line" == *"Receiving objects"* ]] || [[ "$line" == *"Resolving deltas"* ]]; then
            echoe -e "${BLUEC}${line}${NC}";
        fi
    done; then
        echoe -e "${REDC}ERROR${NC}: Fallo al clonar el repositorio Odoo";
        return 1;
    fi
    
    echoe -e "${GREENC}✓${NC} Repositorio Odoo clonado exitosamente";
}

# install_download_odoo
function install_download_odoo {
    # Verificar si el directorio ya existe
    if [ -d "$ODOO_PATH" ]; then
        echoe -e "${YELLOWC}El directorio ${BLUEC}${ODOO_PATH}${YELLOWC} ya existe.${NC}";
        echoe -e "${GREENC}✓${NC} Saltando descarga...";
        echoe -e "${BLUEC}Para forzar una nueva descarga, elimina el directorio: ${YELLOWC}rm -rf $ODOO_PATH${NC}";
        return 0;
    fi

    local clone_odoo_repo=${ODOO_REPO:-$DEFAULT_ODOO_REPO};

    local odoo_archive=/tmp/odoo.$ODOO_BRANCH.tar.gz
    if [ -f "$odoo_archive" ]; then
        rm "$odoo_archive";
    fi

    if [[ "$ODOO_REPO" == "https://github.com"* ]]; then
        local repo=${clone_odoo_repo%.git};
        local repo_base;
        repo_base=$(basename "$repo");
        
        echoe -e "${BLUEC}Descargando Odoo desde ${YELLOWC}${repo}/archive/${ODOO_BRANCH}.tar.gz${NC}";
        echoe -e "${BLUEC}Archivo temporal: ${YELLOWC}${odoo_archive}${NC}";
        
        # Descargar con barra de progreso
        if ! wget --progress=bar:force:noscroll -T 30 -O "$odoo_archive" "$repo/archive/$ODOO_BRANCH.tar.gz" 2>&1 | while read -r line; do
            if [[ "$line" == *"%"* ]]; then
                echoe -e "${BLUEC}${line}${NC}";
            fi
        done; then
            echoe -e "${REDC}ERROR${NC}: No se pudo descargar Odoo desde ${YELLOWC}${repo}/archive/${ODOO_BRANCH}.tar.gz${NC}.";
            echoe -e "Elimina la descarga rota (si existe) ${YELLOWC}${odoo_archive}${NC}.";
            echoe -e "e intenta ejecutar el comando de abajo: ";
            echoe -e "    ${BLUEC}wget --debug -T 30 -O \"$odoo_archive\" \"$repo/archive/$ODOO_BRANCH.tar.gz\"${NC}";
            echoe -e "y analiza su salida";
            return 2;
        fi
        
        echoe -e "${GREENC}✓${NC} Descarga completada";
        echoe -e "${BLUEC}Extrayendo archivo...${NC}";
        
        if ! tar -zxf "$odoo_archive"; then
            echoe -e "${REDC}ERROR${NC}: No se pudo extraer el archivo descargado ${YELLOWC}${odoo_archive}${NC}.";
            return 3;
        fi
        
        echoe -e "${GREENC}✓${NC} Archivo extraído";
        echoe -e "${BLUEC}Moviendo a directorio destino...${NC}";
        
        mv "${repo_base}-${ODOO_BRANCH}" "$ODOO_PATH";
        rm "$odoo_archive";
        
        echoe -e "${GREENC}✓${NC} Odoo instalado en ${YELLOWC}${ODOO_PATH}${NC}";
    else
        echoe -e "${REDC}ERROR${NC}: No se puede descargar Odoo. La opción de descarga solo es compatible con repositorios de GitHub!";
        return 1;
    fi
}


# fetch odoo source code clone|download
function install_fetch_odoo {
    local usage="
    Fetch Odoo source code from repository.

    Usage:

        $SCRIPT_NAME install fetch-odoo <action> [options] - fetch odoo source
        $SCRIPT_NAME install fetch-odoo --help            - show this help message

    <action> could be:
        clone     - clone Odoo as git repository (recommended)
        download  - download Odoo from archive

    Options:
        --force   - force re-download even if directory exists
    ";

    local odoo_action;
    local force_download;
    
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            clone|download)
                odoo_action="$1";
            ;;
            --force)
                force_download=1;
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo -e "${REDC}ERROR${NC}: Unknown option $key";
                return 1;
            ;;
        esac
        shift
    done

    if [ -z "$odoo_action" ]; then
        echo -e "${REDC}ERROR${NC}: Please specify action (clone or download)!";
        echo "";
        echo "$usage";
        return 1;
    fi

    # Si se fuerza la descarga, eliminar el directorio existente
    if [ -n "$force_download" ] && [ -d "$ODOO_PATH" ]; then
        echoe -e "${YELLOWC}Forzando re-descarga. Eliminando directorio existente...${NC}";
        rm -rf "$ODOO_PATH";
    fi

    if [ "$odoo_action" == 'clone' ]; then
        install_clone_odoo;
    elif [ "$odoo_action" == 'download' ]; then
        install_download_odoo;
    else
        echoe -e "${REDC}ERROR${NC}: *install_fetch_odoo* - unknown action '$odoo_action'!";
        return 1;
    fi
}

# get download link for wkhtmltopdf install
#
# install_wkhtmltopdf_get_dw_link <os_release_name> [wkhtmltopdf version]
function install_wkhtmltopdf_get_dw_link {
    local os_release_name=$1;
    local version=${2:-0.12.5};
    local system_arch;
    system_arch=$(dpkg --print-architecture);

    echo "https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/$version/wkhtmltox_${version}-1.${os_release_name}_${system_arch}.deb"
}


# Download wkhtmltopdf to specified path
#
# install_wkhtmltopdf_download <path>
function install_wkhtmltopdf_download {
    local wkhtmltox_path=$1;
    local release;
    local download_link;
    release=$(lsb_release -sc);
    download_link=$(install_wkhtmltopdf_get_dw_link "$release");

    if ! wget -q -T 15 "$download_link" -O "$wkhtmltox_path"; then
        local old_release=$release;

        if [ "$(lsb_release -si)" == "Ubuntu" ]; then
            # fallback to trusty release for ubuntu systems
            release=bionic;
        elif [ "$(lsb_release -si)" == "Debian" ]; then
            release=stretch;
        else
            echoe -e "${REDC}ERROR:${NC} Cannot install ${BLUEC}wkhtmltopdf${NC}! Not supported OS";
            return 2;
        fi

        echoe -e "${YELLOWC}WARNING${NC}: Cannot find wkhtmltopdf for ${BLUEC}${old_release}${NC}. trying to install fallback for ${BLUEC}${release}${NC}.";
        download_link=$(install_wkhtmltopdf_get_dw_link "$release");
        if ! wget -q -T 15 "$download_link" -O "$wkhtmltox_path"; then
            echoe -e "${REDC}ERROR:${NC} Cannot install ${BLUEC}wkhtmltopdf${NC}! cannot download package $download_link";
            return 1;
        fi
    fi
}

# install_wkhtmltopdf
function install_wkhtmltopdf {
    local usage="
    Install wkhtmltopdf. It is required to print PDF reports.


    Usage:

        $SCRIPT_NAME install wkhtmltopdf [options]

    Options:

        --update   - install even if it is already installed
        --help     - show this help message
    ";

    local force_install;
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            --update)
                force_install=1;
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo -e "${REDC}ERROR${NC}: Unknown command $key";
                return 1;
            ;;
        esac
        shift
    done
    if ! check_command wkhtmltopdf > /dev/null || [ -n "$force_install" ]; then
        echoe -e "${BLUEC}Instalando ${YELLOWC}wkhtmltopdf${BLUEC}...${NC}";
        
        # URL actualizada para Ubuntu 22.04 (jammy)
        local WKHTMLTOX_URL="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb";
        local wkhtmltox_path=${DOWNLOADS_DIR:-/tmp}/wkhtmltox.deb;
        
        # Instalar dependencias necesarias
        install_sys_deps_internal xfonts-75dpi xfonts-base;
        
        # Descargar wkhtmltopdf
        if ! wget -q "$WKHTMLTOX_URL" -O "$wkhtmltox_path"; then
            echoe -e "${REDC}ERROR:${NC} Cannot download ${BLUEC}wkhtmltopdf${NC}!";
            return 1;
        fi
        
        # Instalar el paquete
        if ! with_sudo dpkg -i "$wkhtmltox_path"; then
            with_sudo apt-get install -f -y;
        fi
        
        # Crear enlaces simbólicos
        with_sudo ln -sf /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf;
        with_sudo ln -sf /usr/local/bin/wkhtmltoimage /usr/bin/wkhtmltoimage;
        
        # Limpiar archivo descargado
        rm "$wkhtmltox_path" || true;

        echoe -e "${GREENC}OK${NC}:${YELLOWC}wkhtmltopdf${NC} installed successfully!";
    else
        echoe -e "${GREENC}OK${NC}:${YELLOWC}wkhtmltopdf${NC} seems to be installed!";
    fi
}


# install_sys_deps_internal dep_1 dep_2 ... dep_n
function install_sys_deps_internal {
    # Odoo's debian/control file usualy contains this in 'Depends' section 
    # so we need to skip it before running apt-get
    echoe -e "${BLUEC}Installing system dependencies${NC}: $*";
    if [ -n "$ALWAYS_ANSWER_YES" ]; then
        local opt_apt_always_yes="-yq";
    fi
    with_sudo apt-get install $opt_apt_always_yes --no-install-recommends "$@";
}

# install_parse_debian_control_file <control file>
# parse debian control file to fetch odoo dependencies
function install_parse_debian_control_file {
    local file_path=$1;
    local sys_deps_raw=( );

    local python_cmd="import re; RE_DEPS=re.compile(r'.*Depends:(?P<deps>(\n [^,]+,)+).*', re.MULTILINE | re.DOTALL);";
    python_cmd="$python_cmd m = RE_DEPS.match(open('$file_path').read());";
    python_cmd="$python_cmd deps = m and m.groupdict().get('deps', '');";
    python_cmd="$python_cmd deps = deps.replace(',', '').replace(' ', '').split('\n');";
    python_cmd="$python_cmd print('\n'.join(filter(lambda l: l and not l.startswith('\\\${'), deps)))";

    mapfile -t sys_deps_raw < <(run_python_cmd "$python_cmd");

    # Preprocess odoo dependencies
    # TODO: create list of packages that should not be installed via apt
    for dep in "${sys_deps_raw[@]}"; do
        # shellcheck disable=SC2016
        case $dep in
            '${misc:Depends}')
                continue
            ;;
            '${python3:Depends}')
                continue
            ;;
            \$\{*)
                # Skip dependencies stared with ${
                continue
            ;;
            node-less)
                # Will be installed into virtual env via node-env
                continue
            ;;
            python-pypdf|python-pypdf2|python3-pypdf2)
                # Will be installed by pip from requirements.txt
                continue
            ;;
            python-pybabel|python-babel|python-babel-localedata|python3-babel)
                # Will be installed by setup.py or pip
                continue
            ;;
            python-feedparser|python3-feedparser)
                # Seems to be pure-python dependency
                continue
            ;;
            python-requests|python3-requests)
                # Seems to be pure-python dependency
                continue
            ;;
            python-urllib3)
                # Seems to be pure-python dependency
                continue
            ;;
            python-vobject|python3-vobject)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-decorator|python3-decorator)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-pydot|python3-pydot)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-mock|python3-mock)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-pyparsing|python3-pyparsing)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-vatnumber|python3-vatnumber)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-yaml|python3-yaml)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-xlwt|python3-xlwt)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-dateutil|python3-dateutil)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-openid|python3-openid)
                # Will be installed by setup.py or requirements
                continue
            ;;
            python-mako|python-jinja2|python3-mako|python3-jinja2)
                # Will be installed by setup.py or requirements
                continue
            ;;
            #-----
            python-lxml|python-libxml2|python-imaging|python-psycopg2|python-docutils|python-ldap|python-passlib|python-psutil)
                continue
            ;;
            python3-lxml|python3-pil|python3-psycopg2|python3-docutils|python3-ldap|python3-passlib|python3-psutil)
                continue
            ;;
            python-six|python-pychart|python-reportlab|python-tz|python-werkzeug|python-suds|python-xlsxwriter)
                continue
            ;;
            python3-six|python3-pychart|python3-reportlab|python3-tz|python3-werkzeug|python3-suds|python3-xlsxwriter|python3-html2text|python3-chardet|python3-libsass|python3-polib|python3-qrcode|python3-xlrd)
                continue
            ;;
            python-libxslt1|python-simplejson|python-unittest2)
                continue
            ;;
            *)
                echo "$dep";
        esac;
    done
}

# install_sys_deps_for_odoo_version <odoo version>
# Note that odoo version here is branch of official odoo repository
function install_sys_deps_for_odoo_version {
    local usage="
    Install system dependencies for specific Odoo version.
    Only Odoo 17.0+ is supported.

    Usage:

        $SCRIPT_NAME install sys-deps [options] <odoo-version> - install deps
        $SCRIPT_NAME install sys-deps --help                   - show help msg

    Options:

        -y|--yes              - Always answer yes
        -b|--branch <branch>  - Odoo branch to fetch deps for

    ";
    local odoo_branch;
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -y|--yes)
                ALWAYS_ANSWER_YES=1;
            ;;
            -b|--branch)
                odoo_branch="$2";
                shift;
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                break;
            ;;
        esac
        shift
    done

    local odoo_version=$1;
    if [ -z "$odoo_version" ]; then
        echoe -e "${REDC}ERROR${NC}: Odoo version is not specified!";
        return 1;
    fi
    
    # Validar versión antes de instalar dependencias
    if ! validate_odoo_version "$odoo_version"; then
        return 1;
    fi

    odoo_branch=${odoo_branch:-$odoo_version};
    local control_url="https://raw.githubusercontent.com/odoo/odoo/$odoo_branch/debian/control";
    local tmp_control;
    tmp_control=$(mktemp);
    wget -q -T 15 "$control_url" -O "$tmp_control";
    local sys_deps;
    mapfile -t sys_deps < <(ODOO_VERSION="$odoo_version" install_parse_debian_control_file "$tmp_control");
    install_sys_deps_internal "${sys_deps[@]}";
    rm "$tmp_control";
}

# install python requirements for specified odoo version via PIP requirements.txt
# This function uses version-specific dependencies based on Odoo saas-18.3 requirements.txt
function install_odoo_py_requirements_for_version {
    local usage="
    Install python dependencies for specific Odoo version.

    Usage:

        $SCRIPT_NAME install py-deps [options] [odoo-version] - install python dependencies
        $SCRIPT_NAME install py-deps --help         - show this help message

    Options:
        -b|--branch <branch>   - Odoo branch to install deps for

    ";
    local odoo_branch=${ODOO_BRANCH};
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            -b|--branch)
                odoo_branch="$2";
                shift;
            ;;
            *)
                break;
            ;;
        esac
        shift
    done

    local odoo_version=${1:-$ODOO_VERSION};
    local odoo_major_version;
    # Extraer versión numérica correctamente
    if [[ "$odoo_version" == saas-* ]]; then
        # Para versiones SaaS como saas-18.1, saas-18.2, saas-18.3
        odoo_major_version="${odoo_version#saas-}";
        odoo_major_version="${odoo_major_version%.*}";
    else
        # Para versiones estándar como 17.0, 18.0
        odoo_major_version="${odoo_version%.*}";
    fi
    odoo_branch=${odoo_branch:-$odoo_version};
    
    # Validar versión de Odoo antes de instalar dependencias Python
    if ! validate_odoo_version "$odoo_version"; then
        return 1;
    fi
    
    local requirements_url="https://raw.githubusercontent.com/odoo/odoo/$odoo_branch/requirements.txt";
    
    # Mostrar información sobre la versión de Python que se está usando
    local python_version_info;
    python_version_info=$(exec_py -c "\"import sys; print(f'Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')\"");
    echoe -e "${BLUEC}Instalando dependencias para ${YELLOWC}${python_version_info}${NC}";
    local tmp_requirements;
    local tmp_requirements_post;
    tmp_requirements=$(mktemp);
    tmp_requirements_post=$(mktemp);
    if wget -q -T 15 "$requirements_url" -O "$tmp_requirements"; then
        # Preprocess requirements to avoid known bugs
        while read -r dependency || [[ -n "$dependency" ]]; do
            dependency_stripped="$(echo "${dependency}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            if [[ "$dependency_stripped" =~ pyparsing* ]]; then
                # Pyparsing is used by new versions of setuptools, so it is bad idea to update it,
                # especialy to versions lower than that used by setuptools
                continue
            elif [[ "$dependency_stripped" =~ pychart* ]]; then
                # Pychart is not downloadable and not compatible with Python 3
                # Skip this dependency for modern Odoo versions
                echoe -e "${YELLOWC}WARNING${NC}: Skipping pychart dependency (not compatible with Python 3)";
                continue;

            elif [ "$odoo_major_version" -ge 17 ] && [[ "$dependency_stripped" =~ gevent* ]]; then
                # Odoo 17+ con Python 3.8+ - usar versiones específicas basadas en requirements.txt
                if exec_py -c "\"import sys; assert (3, 8) <= sys.version_info < (3, 10);\"" > /dev/null 2>&1; then
                    # Python 3.8-3.9 support for Odoo 17+
                    echo "gevent==22.10.2";
                elif exec_py -c "\"import sys; assert (3, 10) <= sys.version_info < (3, 11);\"" > /dev/null 2>&1; then
                    # Python 3.10 support for Odoo 17-18 (actualizado para compatibilidad con Cython moderno)
                    echo "gevent==22.10.2";
                elif exec_py -c "\"import sys; assert (3, 11) <= sys.version_info < (3, 12);\"" > /dev/null 2>&1; then
                    # Python 3.11 support for Odoo 17-18
                    echo "gevent==22.10.2";
                elif exec_py -c "\"import sys; assert (3, 12) <= sys.version_info < (3, 13);\"" > /dev/null 2>&1; then
                    # Python 3.12+ support for Odoo 18+
                    echo "gevent==24.2.1";
                else
                    # Default for newer Python versions
                    echo "gevent==24.2.1";
                fi
            elif [ "$odoo_major_version" -ge 17 ] && [[ "$dependency_stripped" =~ greenlet* ]]; then
                # Para Odoo 17+ con Python 3.8+, usar versiones específicas del requirements.txt
                if exec_py -c "\"import sys; assert (3, 8) <= sys.version_info < (3, 10);\"" > /dev/null 2>&1; then
                    # Python 3.8-3.9 support for Odoo 17+
                    echo "greenlet==1.1.2";
                elif exec_py -c "\"import sys; assert (3, 10) <= sys.version_info < (3, 11);\"" > /dev/null 2>&1; then
                    # Python 3.10 support for Odoo 17-18 (actualizado para compatibilidad con gevent 22.10.2)
                    echo "greenlet==2.0.2";
                elif exec_py -c "\"import sys; assert (3, 11) <= sys.version_info < (3, 12);\"" > /dev/null 2>&1; then
                    # Python 3.11 support for Odoo 17-18
                    echo "greenlet==2.0.2";
                elif exec_py -c "\"import sys; assert (3, 12) <= sys.version_info < (3, 13);\"" > /dev/null 2>&1; then
                    # Python 3.12+ support for Odoo 18+
                    echo "greenlet==3.0.3";
                else
                    # Default for newer Python versions
                    echo "greenlet==3.0.3";
                fi
            elif [ "$odoo_major_version" -ge 17 ] && [[ "$dependency_stripped" =~ psycopg2* ]]; then
                # Para Odoo 17+ con Python 3.8+, usar versiones específicas del requirements.txt
                if exec_py -c "\"import sys; assert (3, 8) <= sys.version_info < (3, 10);\"" > /dev/null 2>&1; then
                    # Python 3.8-3.9 support for Odoo 17+
                    echo "psycopg2==2.9.2";
                elif exec_py -c "\"import sys; assert (3, 10) <= sys.version_info < (3, 11);\"" > /dev/null 2>&1; then
                    # Python 3.10 support for Odoo 17-18
                    echo "psycopg2==2.9.2";
                elif exec_py -c "\"import sys; assert (3, 11) <= sys.version_info < (3, 12);\"" > /dev/null 2>&1; then
                    # Python 3.11 support for Odoo 17-18
                    echo "psycopg2==2.9.5";
                elif exec_py -c "\"import sys; assert (3, 12) <= sys.version_info < (3, 13);\"" > /dev/null 2>&1; then
                    # Python 3.12+ support for Odoo 18+
                    echo "psycopg2==2.9.9";
                else
                    # Default for newer Python versions
                    echo "psycopg2==2.9.9";
                fi
            elif [ "$odoo_major_version" -ge 17 ] && [[ "$dependency_stripped" =~ lxml ]]; then
                # Para Odoo 17+ con Python 3.8+, usar versiones específicas del requirements.txt
                if exec_py -c "\"import sys; assert (3, 8) <= sys.version_info < (3, 11);\"" > /dev/null 2>&1; then
                    echo "lxml==4.9.1";
                elif exec_py -c "\"import sys; assert (3, 11) <= sys.version_info < (3, 12);\"" > /dev/null 2>&1; then
                    echo "lxml==4.9.1";
                elif exec_py -c "\"import sys; assert (3, 12) <= sys.version_info < (3, 13);\"" > /dev/null 2>&1; then
                    echo "lxml==5.2.2";
                else
                    # Default for newer Python versions
                    echo "lxml==5.2.2";
                fi
            elif [ "$odoo_major_version" -ge 17 ] && [[ "$dependency_stripped" =~ cryptography ]]; then
                # Para Odoo 17+ con Python 3.8+, usar versiones específicas del requirements.txt
                if exec_py -c "\"import sys; assert (3, 8) <= sys.version_info < (3, 11);\"" > /dev/null 2>&1; then
                    echo "cryptography==41.0.7";
                elif exec_py -c "\"import sys; assert (3, 11) <= sys.version_info < (3, 12);\"" > /dev/null 2>&1; then
                    echo "cryptography==41.0.7";
                elif exec_py -c "\"import sys; assert (3, 12) <= sys.version_info < (3, 13);\"" > /dev/null 2>&1; then
                    echo "cryptography==42.0.4";
                else
                    echo "cryptography==42.0.4";
                fi
            else
                # Echo dependency line unchanged to rmp file
                echo "$dependency";
            fi
        done < "$tmp_requirements" > "$tmp_requirements_post";
        
        echoe -e "${BLUEC}Instalando dependencias Python para Odoo ${odoo_version}...${NC}";
        if ! exec_pip install -r "$tmp_requirements_post"; then
            echoe -e "${REDC}ERROR CRÍTICO${NC}: No se pudieron instalar las dependencias Python de Odoo.";
            echoe -e "${YELLOWC}Archivo de dependencias:${NC}";
            cat "$tmp_requirements_post";
            echoe -e "${REDC}ABORTANDO INSTALACIÓN${NC}: La instalación no puede continuar sin las dependencias Python.";
            
            # Limpiar archivos temporales antes de salir
            [ -f "$tmp_requirements" ] && rm "$tmp_requirements";
            [ -f "$tmp_requirements_post" ] && rm "$tmp_requirements_post";
            return 1;
        fi
        
        echoe -e "${GREENC}✓${NC} Dependencias Python instaladas exitosamente";
    else
        echoe -e "${REDC}ERROR CRÍTICO${NC}: No se pudo descargar el archivo requirements.txt de Odoo.";
        echoe -e "${YELLOWC}URL intentada:${NC} $requirements_url";
        echoe -e "${REDC}ABORTANDO INSTALACIÓN${NC}: Sin requirements.txt no se pueden instalar las dependencias.";
        
        # Limpiar archivos temporales antes de salir
        [ -f "$tmp_requirements" ] && rm "$tmp_requirements";
        [ -f "$tmp_requirements_post" ] && rm "$tmp_requirements_post";
        return 1;
    fi

    # Limpiar archivos temporales al final
    if [ -f "$tmp_requirements" ]; then
        rm "$tmp_requirements";
    fi

    if [ -f "$tmp_requirements_post" ]; then
        rm "$tmp_requirements_post";
    fi
}

function install_and_configure_postgresql {
    local usage="
    Install postgresql server and optionaly automatically create postgres user
    for this Odoo instance.

    Usage:

        Install postgresql only:
            $SCRIPT_NAME install postgres                   

        Install postgresql and create postgres user:
            $SCRIPT_NAME install postgres <user> <password>

    ";
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                break;
            ;;
        esac
        shift
    done
    local db_user=${1:-$DB_USER};
    local db_password=${2:-DB_PASSWORD};
    # Check if postgres is installed on this machine. If not, install it
    if ! postgres_is_installed; then
        postgres_install_postgresql;
        echo -e "${GREENC}Postgres installed${NC}";
    else
        echo -e "${YELLOWC}It seems that postgresql is already installed... Skipping this step...${NC}";
    fi

    if [ -n "$db_user" ] && [ -n "$db_password" ]; then
        postgres_user_create "$db_user" "$db_password";
    fi
}


# install_system_prerequirements
function install_system_prerequirements {
    local usage="
    Install system dependencies for odoo-helper-scripts itself and
    common dependencies for Odoo.

    Usage:

        $SCRIPT_NAME install pre-requirements [options]  - install requirements
        $SCRIPT_NAME install pre-requirements --help     - show this help message

    Options:

        -y|--yes     - Always answer yes

    ";
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -y|--yes)
                ALWAYS_ANSWER_YES=1;
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done

    echoe -e "${BLUEC}Updating package list...${NC}"
    with_sudo apt-get update -qq || true;

    echoe -e "${BLUEC}Installing system preprequirements...${NC}";
    
    # Detectar versión de Ubuntu para usar los paquetes correctos
    local ubuntu_version;
    ubuntu_version=$(lsb_release -rs);
    
    local python_dev_package;
    # Verificar si es Ubuntu 22.04 o superior
    if [ "$(echo "$ubuntu_version" | cut -d. -f1)" -ge 22 ]; then
        # Ubuntu 22.04+ usa python3-dev en lugar de python-dev
        python_dev_package="python3-dev";
    else
        # Versiones anteriores pueden usar python-dev
        python_dev_package="python-dev";
    fi
    
    install_sys_deps_internal git wget lsb-release \
        procps libevent-dev g++ libpq-dev libsass-dev \
        "$python_dev_package" libjpeg-dev libyaml-dev \
        libfreetype6-dev zlib1g-dev libxml2-dev libxslt-dev bzip2 \
        libsasl2-dev libldap2-dev libssl-dev libffi-dev fontconfig;

    if ! install_wkhtmltopdf; then
        echoe -e "${YELLOWC}WARNING:${NC} Cannot install ${BLUEC}wkhtmltopdf${NC}!!! Skipping...";
    fi
}

# Install virtual environment.
#
# install_virtual_env
function install_virtual_env {
    if [ -n "$VENV_DIR" ] && [ ! -d "$VENV_DIR" ]; then
        echoe -e "${BLUEC}Instalando entorno virtual...${NC}";
        
        # Usar virtualenv moderno desde pip en lugar del script antiguo
        if [ -z "$VIRTUALENV_PYTHON" ]; then
            local venv_python_version;
            venv_python_version=$(odoo_get_python_version);
            
            # Instalar virtualenv moderno si no está disponible
            if ! command -v virtualenv >/dev/null 2>&1; then
                echoe -e "${BLUEC}Instalando virtualenv moderno...${NC}";
                $venv_python_version -m pip install --user virtualenv;
            fi
            
            # Crear entorno virtual con virtualenv moderno
            $venv_python_version -m virtualenv "$VENV_DIR";
        else
            # Instalar virtualenv moderno si no está disponible
            if ! command -v virtualenv >/dev/null 2>&1; then
                echoe -e "${BLUEC}Instalando virtualenv moderno...${NC}";
                $VIRTUALENV_PYTHON -m pip install --user virtualenv;
            fi
            
            # Crear entorno virtual con virtualenv moderno
            $VIRTUALENV_PYTHON -m virtualenv "$VENV_DIR";
        fi
        
        echoe -e "${GREENC}✓${NC} Entorno virtual creado exitosamente";
        
        # Activar el entorno virtual para instalar nodeenv
        source "$VENV_DIR/bin/activate";
        
        # Instalar nodeenv en el entorno virtual
        pip install -q nodeenv;
        
        # Instalar entorno de Node.js
        nodeenv --python-virtualenv;
        
        # Configurar npm
        npm set user 0;
        npm set unsafe-perm true;
        
        echoe -e "${GREENC}✓${NC} Entorno de Node.js instalado";
    fi
}

# Install bin tools
#
# At this moment just installs expect-dev package, that provides 'unbuffer' tool
function install_bin_tools {
    local usage="
    Install extra tools.
    This command installs expect-dev package that brings 'unbuffer' program.
    'unbuffer' program allow to run command without buffering.
    This is required to make odoo show collors in log.

    Usage:

        $SCRIPT_NAME install bin-tools [options]  - install extra tools
        $SCRIPT_NAME install bin-tools --help     - show this help message

    Options:

        -y|--yes     - Always answer yes

    ";
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -y|--yes)
                ALWAYS_ANSWER_YES=1;
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done
    local deps=( );
    if ! check_command 'google-chrome' 'chromium' 'chromium-browser' > /dev/null; then
        echoe -e "${YELLOWC}Google Chrome${BLUEC} seems to be not installed. ${YELLOWC}chromium-browser${BLUEC} will be installed.${NC}";
        deps+=( chromium-browser );
    fi
    if ! check_command 'unbuffer' > /dev/null; then
        echoe -e "${YELLOWC}unbuffer${BLUEC} seems to be not installed. ${YELLOWC}expect-dev${BLUEC} and ${YELLOWC}tcl8.6${BLUEC} will be installed.${NC}";
        deps+=( expect-dev tcl8.6 );
    fi

    if [ -n "${deps[*]}" ]; then
        install_sys_deps_internal "${deps[@]}";
    fi
}

# Install extra python tools
function install_python_tools {
    local usage="
    Install extra python tools.

    Following packages will be installed:

        - setproctitle
        - watchdog
        - pylint-odoo
        - coverage
        - flake8
        - flake8-colors
        - websocket-client  (required for tests in Odoo 12.0)
        - jingtrang

    Usage:

        $SCRIPT_NAME install py-tools [options]  - install extra tools
        $SCRIPT_NAME install py-tools --help     - show this help message

    Options:

        -q|--quiet     - quiet mode. reduce output

    ";
    local pip_options=( );
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -q|--quiet)
                pip_options+=( --quiet );
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done
    exec_pip "${pip_options[@]}" install setproctitle watchdog pylint-odoo coverage \
        flake8 flake8-colors websocket-client jingtrang;
}

# Install extra javascript tools
function install_js_tools {
    local usage="
    Install extra javascript tools.

    Following packages will be installed:

        - eslint
        - phantomjs-prebuilt (only for Odoo below 12.0)
        - stylelint
        - stylelint-config-standard

    Usage:

        $SCRIPT_NAME install js-tools        - install extra tools
        $SCRIPT_NAME install js-tools --help - show this help message

    ";
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done
    local deps=( eslint stylelint stylelint-config-standard );
    local major_version=$(odoo_get_major_version);
    if [[ "$major_version" =~ ^[0-9]+$ ]] && [ "$major_version" -lt 12 ]; then
        deps+=( phantomjs-prebuilt );
    fi
    exec_npm install -g "${deps[@]}";
}

function install_dev_tools {
    local usage="
    Install extra development tools. May require sudo.

    This command is just an alias to run following commands with single call:
        - $SCRIPT_NAME install bin-tools
        - $SCRIPT_NAME install py-tools
        - $SCRIPT_NAME install js-tools

    Usage:

        $SCRIPT_NAME install dev-tools        - install extra dev tools
        $SCRIPT_NAME install dev-tools --help - show this help message
    ";
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done
    install_bin_tools;
    install_python_tools;
    install_js_tools;
}

function install_unoconv {
    local usage="
    Install unoconv;

    sudo is required for this command.
    Only available for odoo 11.0+
    Have to be run on per-project basis.

    Warning: this command is experimental.

    Usage:

        $SCRIPT_NAME install unoconv        - install unconv
        $SCRIPT_NAME install unoconv --help - show this help message
    ";
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done
    ALWAYS_ANSWER_YES=1 install_sys_deps_internal unoconv;
    local system_python;
    system_python=$(command -v python3);
    if [ -n "$VENV_DIR" ] && [ -n "$system_python" ]; then
        exec_pip install unoconv;
        sed -i "1s@.*@#!$system_python@" "$VENV_DIR/bin/unoconv";
    fi;
}

function install_openupgradelib {
    local usage="
    Install latest openupgradelib;

    Warning: this command is experimental.

    Usage:

        $SCRIPT_NAME install openupgradelib        - install openupgradelib
        $SCRIPT_NAME install openupgradelib --help - show this help message
    ";
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done
    exec_pip install --upgrade "git+https://github.com/OCA/openupgradelib.git@master#egg=openupgradelib"
}

# install_python_prerequirements
function install_python_prerequirements {
    # virtualenv >= 15.1.0 automaticaly installs last versions of pip and
    # setuptools, so we do not need to upgrade them
    echoe -e "${BLUEC}Instalando paquetes Python básicos...${NC}";
    if ! exec_pip -q install phonenumbers python-slugify setuptools-odoo cffi jinja2; then
        echoe -e "${REDC}ERROR CRÍTICO${NC}: No se pudieron instalar los paquetes Python básicos.";
        echoe -e "${YELLOWC}Paquetes requeridos:${NC} phonenumbers python-slugify setuptools-odoo cffi jinja2";
        return 1;
    fi

    # Python-Chart (pychart) es muy antiguo y no es compatible con Python 3
    # Para Odoo 18.3, no es necesario instalar pychart ya que no se usa
    # Si se necesita funcionalidad de gráficos, usar alternativas modernas
    echoe -e "${BLUEC}Nota: Python-Chart (pychart) no se instala por incompatibilidad con Python 3${NC}";
    
    echoe -e "${GREENC}✓${NC} Paquetes Python básicos instalados correctamente";
}

# Install javascript pre-requirements.
# Now it is less compiler. install if it is not installed yet
function install_js_prerequirements {
    if ! check_command lessc > /dev/null; then
        echoe -e "${BLUEC}Instalando compilador LESS...${NC}";
        if ! execu npm install -g less@3.9.0; then
            echoe -e "${REDC}ERROR CRÍTICO${NC}: No se pudo instalar el compilador LESS.";
            echoe -e "${YELLOWC}Comando fallido:${NC} npm install -g less@3.9.0";
            return 1;
        fi
        echoe -e "${GREENC}✓${NC} Compilador LESS instalado correctamente";
    else
        echoe -e "${GREENC}✓${NC} Compilador LESS ya está instalado";
    fi
}

# Generate configuration file fo odoo
# this function looks into ODOO_CONF_OPTIONS environment variable,
# which should be associative array with options to be written to file
# install_generate_odoo_conf <file_path>
function install_generate_odoo_conf {
    local conf_file=$1;

    # default addonspath
    local addons_path="$ODOO_PATH/addons,$ADDONS_DIR";
    if [ -e "$ODOO_PATH/odoo/addons" ]; then
        addons_path="$ODOO_PATH/odoo/addons,$addons_path";
    elif [ -e "$ODOO_PATH/openerp/addons" ]; then
        addons_path="$ODOO_PATH/openerp/addons,$addons_path";
    fi

    # default values
    ODOO_CONF_OPTIONS['addons_path']="${ODOO_CONF_OPTIONS['addons_path']:-$addons_path}";
    ODOO_CONF_OPTIONS['admin_passwd']="${ODOO_CONF_OPTIONS['admin_passwd']:-admin}";
    ODOO_CONF_OPTIONS['data_dir']="${ODOO_CONF_OPTIONS['data_dir']:-$DATA_DIR}";
    ODOO_CONF_OPTIONS['logfile']="${ODOO_CONF_OPTIONS['logfile']:-$LOG_FILE}";
    ODOO_CONF_OPTIONS['db_host']="${ODOO_CONF_OPTIONS['db_host']:-False}";
    ODOO_CONF_OPTIONS['db_port']="${ODOO_CONF_OPTIONS['db_port']:-False}";
    ODOO_CONF_OPTIONS['db_user']="${ODOO_CONF_OPTIONS['db_user']:-odoo}";
    ODOO_CONF_OPTIONS['db_password']="${ODOO_CONF_OPTIONS['db_password']:-False}";

    local conf_file_data="[options]";
    for key in "${!ODOO_CONF_OPTIONS[@]}"; do
        conf_file_data="$conf_file_data\n$key = ${ODOO_CONF_OPTIONS[$key]}";
    done

    echo -e "$conf_file_data" > "$conf_file";
}


# odoo_run_setup_py
function odoo_run_setup_py {
    # Install dependencies via pip (it is faster if they are cached)
    echoe -e "${BLUEC}Instalando dependencias Python desde requirements.txt...${NC}";
    if ! install_odoo_py_requirements_for_version; then
        echoe -e "${REDC}ERROR CRÍTICO${NC}: Falló la instalación de dependencias Python.";
        echoe -e "${REDC}ABORTANDO INSTALACIÓN DE ODOO${NC}";
        return 1;
    fi

    # Install odoo using modern pip install -e . (replaces deprecated setup.py develop)
    echoe -e "${BLUEC}Instalando Odoo en modo desarrollo (pip install -e .)...${NC}";
    if ! (cd "$ODOO_PATH" && exec_pip install -e .); then
        echoe -e "${REDC}ERROR CRÍTICO${NC}: Falló la instalación de Odoo con pip install -e.";
        echoe -e "${YELLOWC}Intentando método alternativo con setup.py como fallback...${NC}";
        
        # Fallback to setup.py develop if pip install -e fails
        if ! (cd "$ODOO_PATH" && exec_py setup.py -q develop); then
            echoe -e "${REDC}ERROR CRÍTICO${NC}: Falló también el método fallback con setup.py.";
            echoe -e "${REDC}ABORTANDO INSTALACIÓN DE ODOO${NC}";
            return 1;
        fi
        echoe -e "${YELLOWC}⚠${NC} Odoo instalado con setup.py (método legacy)";
    else
        echoe -e "${GREENC}✓${NC} Odoo instalado correctamente con pip install -e (método moderno)";
    fi
}


# Install odoo intself.
# Require that odoo is downloaded and directory tree structure created
function install_odoo_install {
    echoe -e "${BLUEC}═══════════════════════════════════════════════════════════════${NC}";
    echoe -e "${BLUEC}                    INSTALANDO ODOO 18.3                    ${NC}";
    echoe -e "${BLUEC}═══════════════════════════════════════════════════════════════${NC}";
    
    # Verificar si Odoo ya está descargado
    if [ ! -d "$ODOO_PATH" ]; then
        echoe -e "${REDC}ERROR${NC}: El directorio de Odoo no existe: ${YELLOWC}${ODOO_PATH}${NC}";
        echoe -e "${BLUEC}Primero debes descargar Odoo usando:${NC}";
        echoe -e "${YELLOWC}odoo-helper install fetch-odoo clone${NC}";
        return 1;
    fi
    
    # Install virtual environment
    echoe -e "${BLUEC}[1/4] Instalando entorno virtual...${NC}";
    if ! install_virtual_env; then
        echoe -e "${REDC}ERROR CRÍTICO${NC}: Falló la instalación del entorno virtual.";
        return 1;
    fi
    echoe -e "${GREENC}✓${NC} Entorno virtual instalado";

    # Install python requirements
    echoe -e "${BLUEC}[2/4] Instalando dependencias de Python básicas...${NC}";
    if ! install_python_prerequirements; then
        echoe -e "${REDC}ERROR CRÍTICO${NC}: Falló la instalación de dependencias Python básicas.";
        return 1;
    fi
    echoe -e "${GREENC}✓${NC} Dependencias de Python básicas instaladas";

    # Install js requirements
    echoe -e "${BLUEC}[3/4] Instalando dependencias de JavaScript...${NC}";
    if ! install_js_prerequirements; then
        echoe -e "${REDC}ERROR CRÍTICO${NC}: Falló la instalación de dependencias JavaScript.";
        return 1;
    fi
    echoe -e "${GREENC}✓${NC} Dependencias de JavaScript instaladas";

    # Run setup.py
    echoe -e "${BLUEC}[4/4] Instalando Odoo...${NC}";
    if ! odoo_run_setup_py; then
        echoe -e "${REDC}ERROR CRÍTICO${NC}: Falló la instalación de Odoo.";
        echoe -e "${REDC}ABORTANDO INSTALACIÓN COMPLETA${NC}";
        return 1;
    fi
    echoe -e "${GREENC}✓${NC} Odoo instalado correctamente";
    
    echoe -e "${BLUEC}═══════════════════════════════════════════════════════════════${NC}";
    echoe -e "${GREENC}                    INSTALACIÓN COMPLETADA                    ${NC}";
    echoe -e "${BLUEC}═══════════════════════════════════════════════════════════════${NC}";
}


# Reinstall virtual environment.
function install_reinstall_venv {
    local usage="
    Recreate virtualenv environment.

    Usage:

        $SCRIPT_NAME install reinstall-venv [options] - reinstall virtualenv
        $SCRIPT_NAME install reinstall-venv --help    - show this help message

    Options:

        -p|--python <python ver>  - python version to recreate virtualenv with.
                                    Same as --python option of virtualenv
        --no-backup               - do not backup virtualenv
    ";
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -p|--python)
                VIRTUALENV_PYTHON="$2";
                shift;
            ;;
            --no-backup)
                local do_not_backup_virtualenv=1;
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done

    if [ -z "$VENV_DIR" ]; then
        echo -e "${YELLOWC}This project does not use virtualenv! Do nothing...${NC}";
        return 0;
    fi

    # Backup old venv
    if [ -d "$VENV_DIR" ] && [ -z "$do_not_backup_virtualenv" ]; then
        local venv_backup_path;
        venv_backup_path="$PROJECT_ROOT_DIR/venv-backup-$(random_string 4)";
        mv "$VENV_DIR" "$venv_backup_path";
        echoe -e "${BLUEC}Old ${YELLOWC}virtualenv${BLUEC} backed up at ${YELLOWC}${venv_backup_path}${NC}";
    fi

    # Install odoo
    install_odoo_install;

    # Update python dependencies for addons
    addons_update_py_deps;
}

function install_reinstall_odoo {
    local usage="
    Reinstall odoo. Usualy used when initialy odoo was installed as archive,
    but we want to reinstall it as git repository to better track updates.

    Usage:

        $SCRIPT_NAME install reinstall-odoo <type> - reinstall odoo
        $SCRIPT_NAME install reinstall-odoo --help - show this help message

    <type> could be:
        clone     - reinstall Odoo as git repository.
        download  - reinstall Odoo from archive.
    ";

    local reinstall_action;
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            clone|git)
                reinstall_action="clone";
            ;;
            download|archive)
                reinstall_action="download";
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo -e "${REDC}ERROR${NC}: Unknown command $key";
                return 1;
            ;;
        esac
        shift
    done
    if [ -z "$reinstall_action" ]; then
        echo -e "${REDC}ERROR${NC}: Please specify reinstall type!";
        echo "";
        echo "$usage";
        return 1;
    fi

    if [ -d "$ODOO_PATH" ]; then
        mv "$ODOO_PATH" "$ODOO_PATH-backup-$(random_string 4)";
    fi

    install_fetch_odoo "$reinstall_action";
    install_reinstall_venv;
}


# Entry point for install subcommand
function install_entry_point {
    local usage="
    Install utils, fix installation, etc

    Usage:

        $SCRIPT_NAME install pre-requirements [--help]   - [sudo] install system pre-requirements
        $SCRIPT_NAME install sys-deps [--help]           - [sudo] install system dependencies for odoo version
        $SCRIPT_NAME install py-deps [--help]            - install python dependencies for odoo version (requirements.txt)
        $SCRIPT_NAME install py-tools [--help]           - install python tools (pylint, flake8, ...)
        $SCRIPT_NAME install js-tools [--help]           - install javascript tools (jshint, phantomjs)
        $SCRIPT_NAME install bin-tools [--help]          - [sudo] install binary tools. at this moment it is *unbuffer*,
                                                           which is in *expect-dev* package
        $SCRIPT_NAME install dev-tools [--help]          - [sudo] install dev tools.
        $SCRIPT_NAME install unoconv [--help]            - [sudo] install unoconv.
        $SCRIPT_NAME install openupgradelib [--help]     - install lates openupgradelib.
        $SCRIPT_NAME install wkhtmltopdf [--help]        - [sudo] install wkhtmtopdf
        $SCRIPT_NAME install postgres [user] [password]  - [sudo] install postgres.
                                                           and if user/password specified, create it
        $SCRIPT_NAME install reinstall-venv [--help]     - reinstall virtual environment
        $SCRIPT_NAME install fetch-odoo [--help]         - fetch odoo source code
                                                           Options are:
                                                              - clone odoo as git repository
                                                              - download odoo archieve and unpack source
        $SCRIPT_NAME install reinstall-odoo [--help]     - completly reinstall odoo
                                                           (downlload or clone new sources, create new virtualenv, etc).
                                                           Options are:
                                                              - clone odoo as git repository
                                                              - download odoo archieve and unpack source
        $SCRIPT_NAME install --help                      - show this help message

    ";

    if [[ $# -lt 1 ]]; then
        echo "$usage";
        return 0;
    fi

    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            pre-requirements)
                shift
                install_system_prerequirements "$@";
                return 0;
            ;;
            sys-deps)
                shift;
                install_sys_deps_for_odoo_version "$@";
                return 0;
            ;;
            py-deps)
                shift;
                config_load_project;
                install_odoo_py_requirements_for_version "$@";
                return 0;
            ;;
            py-tools)
                shift;
                config_load_project;
                install_python_tools "$@";
                return 0;
            ;;
            js-tools)
                shift;
                config_load_project;
                install_js_tools "$@";
                return 0;
            ;;
            bin-tools)
                shift;
                install_bin_tools "$@";
                return 0;
            ;;
            dev-tools)
                shift;
                config_load_project;
                install_dev_tools "$@";
                return 0;
            ;;
            unoconv)
                shift;
                config_load_project;
                install_unoconv "$@";
                return 0;
            ;;
            openupgradelib)
                shift;
                config_load_project;
                install_openupgradelib "$@";
                return;
            ;;
            wkhtmltopdf)
                shift;
                install_wkhtmltopdf "$@";
                return
            ;;
            fetch-odoo)
                shift;
                config_load_project;
                install_fetch_odoo "$@";
                return 0;
            ;;
            reinstall-venv)
                shift;
                config_load_project;
                install_reinstall_venv "$@";
                return 0;
            ;;
            reinstall-odoo)
                shift;
                config_load_project;
                install_reinstall_odoo "$@";
                return 0;
            ;;
            postgres)
                shift;
                install_and_configure_postgresql "$@";
                return 0;
            ;;
            -h|--help|help)
                echo "$usage";
                return 0;
            ;;
            *)
                echo "Unknown option / command $key";
                return 1;
            ;;
        esac
        shift
    done
}
