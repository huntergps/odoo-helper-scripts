# Copyright © 2016-2018 Dmytro Katyukha <dmytro.katyukha@gmail.com>

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

ohelper_require 'install';
ohelper_require 'server';
ohelper_require 'fetch';
ohelper_require 'git';
ohelper_require 'scaffold';
# ----------------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------------
# functions prefix: odoo_*
#-----------------------------------------------------------------------------------------

set -e; # fail on errors

# odoo_get_conf_val <key> [conf file]
# get value from odoo config file
function odoo_get_conf_val {
    local key=$1;
    local conf_file=${2:-$ODOO_CONF_FILE};

    if [ -z "$conf_file" ]; then
        return 1;
    fi

    if [ ! -f "$conf_file" ]; then
        return 2;
    fi

    awk -F " *= *" "/^$key/ {print \$2}" "$conf_file";
}

# odoo_get_conf_val_default <key> <default> [conf file]
# Get value from odoo config or return default value
function odoo_get_conf_val_default {
    local value;

    value=$(odoo_get_conf_val "$1" "$3");
    if [ -n "$value" ]; then
        echo "$value";
    else
        echo "$2";
    fi
}

function odoo_get_conf_val_http_host {
    odoo_get_conf_val_default 'http_interface' "$(odoo_get_conf_val_default 'xmlrpc_interface' 'localhost')";
}

function odoo_get_conf_val_http_port {
    odoo_get_conf_val_default 'http_port' "$(odoo_get_conf_val_default 'xmlrpc_port' '8069')";
}

function odoo_get_server_url {
    echo "http://$(odoo_get_conf_val_http_host):$(odoo_get_conf_val_http_port)/";
}

function odoo_update_sources_git {
    local update_date;
    local tag_name;
    update_date=$(date +'%Y-%m-%d.%H-%M-%S');

    # Ensure odoo is repository
    if ! git_is_git_repo "$ODOO_PATH"; then
        echo -e "${REDC}Cannot update odoo. Odoo sources are not under git.${NC}";
        return 1;
    fi

    # ensure odoo repository is clean
    if ! git_is_clean "$ODOO_PATH"; then
        echo -e "${REDC}Cannot update odoo. Odoo source repo is not clean.${NC}";
        return 1;
    fi

    # Update odoo source
    tag_name="$(git_get_branch_name "$ODOO_PATH")-before-update-$update_date";
    (cd "$ODOO_PATH" &&
        git tag -a "$tag_name" -m "Save before odoo update ($update_date)" &&
        git pull);
}

function odoo_update_sources_archive {
    local file_suffix;
    local wget_opt;
    local backup_path;
    local odoo_archive;

    file_suffix="$(date -I).$(random_string 4)";

    if [ -d "$ODOO_PATH" ]; then    
        # Backup only if odoo sources directory exists
        local backup_path=$BACKUP_DIR/odoo.sources.$ODOO_BRANCH.$file_suffix.tar.gz
        echoe -e "${LBLUEC}Saving odoo source backup:${NC} $backup_path";
        (cd "$ODOO_PATH/.." && tar -czf "$backup_path" "$ODOO_PATH");
        echoe -e "${LBLUEC}Odoo sources backup saved at:${NC} $backup_path";
    fi

    echoe -e "${LBLUEC}Downloading new sources archive...${NC}"
    odoo_archive=$DOWNLOADS_DIR/odoo.$ODOO_BRANCH.$file_suffix.tar.gz
    # TODO: use odoo-repo variable here
    if [ -z "$VERBOSE" ]; then
        wget -T 15 -q -O "$odoo_archive" "https://github.com/odoo/odoo/archive/$ODOO_BRANCH.tar.gz";
    else
        wget -T 15 -O "$odoo_archive" "https://github.com/odoo/odoo/archive/$ODOO_BRANCH.tar.gz";
    fi
    rm -r "$ODOO_PATH";
    echoe -e "${LBLUEC}Unpacking new source archive ...${NC}";
    (cd "$DOWNLOADS_DIR" && \
        tar -zxf "$odoo_archive" && \
        mv "odoo-$ODOO_BRANCH" "$ODOO_PATH");

}

function odoo_update_sources {
    if git_is_git_repo "$ODOO_PATH"; then
        echoe -e "${LBLUEC}Odoo source seems to be git repository. Attemt to update...${NC}";
        odoo_update_sources_git;

    else
        echoe -e "${LBLUEC}Updating odoo sources...${NC}";
        odoo_update_sources_archive;
    fi

    echoe -e "${LBLUEC}Reinstalling odoo...${NC}";

    # Run setup.py with gevent workaround applied.
    odoo_run_setup_py;  # imported from 'install' module

    echoe -e "${GREENC}Odoo sources update finished!${NC}";

}


# Echo major odoo version (10, 11, ...)
function odoo_get_major_version {
    # Handle SaaS versions like saas-18.3
    if [[ "$ODOO_VERSION" == saas-* ]]; then
        # Extract the version number from saas-18.3 -> 18
        echo "${ODOO_VERSION#saas-}" | cut -d. -f1;
    else
        echo "${ODOO_VERSION%.*}";
    fi
}

# Get python version number - only 2 or 3
function odoo_get_python_version_number {
    if [ -n "$ODOO_VERSION" ]; then
        local major_version=$(odoo_get_major_version);
        # Check if major_version is a valid number
        if [[ "$major_version" =~ ^[0-9]+$ ]]; then
            if [ "$major_version" -ge 11 ]; then
                echo "3";
            elif [ "$major_version" -lt 11 ]; then
                echo "2";
            fi
        else
            # For SaaS versions (saas-18.3, etc.) or unknown formats, always use Python 3
            echo "3";
        fi
    else
        # If no ODOO_VERSION specified, default to Python 3 for modern systems
        echo "3";
    fi
}

# Get python interpreter name to run odoo with
# Returns one of: python2, python3, python
# Default: python3 (for modern systems)
function odoo_get_python_version {
    local py_version;
    py_version=$(odoo_get_python_version_number);
    if [ -n "$py_version" ]; then
        echo "python${py_version}";
    else
        echoe -e "${YELLOWC}WARNING${NC}: odoo version not specified, using default python executable";
        # Always prefer python3 for modern systems
        echo "python3";
    fi
}

# Get python interpreter (full path to executable) to run odoo with
function odoo_get_python_interpreter {
    local python_version;
    python_version=$(odoo_get_python_version);
    check_command "$python_version";
}

function odoo_recompute_stored_fields {
    local usage="
    Recompute stored fields

    Usage:

        $SCRIPT_NAME odoo recompute <options>            - recompute stored fields for database
        $SCRIPT_NAME odoo recompute --help               - show this help message

    Options:

        -d|--db|--dbname <dbname>  - name of database to recompute stored fields on
        -m|--model <model name>    - name of model (in 'model.name.x' format)
                                     to recompute stored fields on
        -f|--field <field name>    - name of field to be recomputed.
                                     could be specified multiple times,
                                     to recompute few fields at once.
        --parent-store             - recompute parent left and parent right fot selected model
                                     conflicts wiht --field option
    ";

    if [[ $# -lt 1 ]]; then
        echo "$usage";
        return 0;
    fi

    local dbname=;
    local model=;
    local fields=;
    local parent_store=;
    local conf_file=$ODOO_CONF_FILE;
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -d|--db|--dbname)
                dbname=$2;
                shift;
            ;;
            -m|--model)
                model=$2;
                shift;
            ;;
            -f|--field)
                fields="'$2',$fields";
                shift;
            ;;
            --parent-store)
                parent_store=1;
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

    if [ -z "$dbname" ]; then
        echoe -e "${REDC}ERROR${NC}: database not specified!";
        return 1;
    fi

    if ! odoo_db_exists -q "$dbname"; then
        echoe -e "${REDC}ERROR${NC}: database ${YELLOWC}${dbname}${NC} does not exists!";
        return 2;
    fi

    if [ -z "$model" ]; then
        echoe -e "${REDC}ERROR${NC}: model not specified!";
        return 3;
    fi

    if [ -z "$fields" ] && [ -z "$parent_store" ]; then
        echoe -e "${REDC}ERROR${NC}: no fields nor ${YELLOWC}--parent-store${NC} option specified!";
        return 4;
    fi

    local python_cmd="import lodoo; db=lodoo.LocalClient(['-c', '$conf_file'])['$dbname'];";
    if [ -z "$parent_store" ]; then
        python_cmd="$python_cmd db.recompute_fields('$model', [$fields]);"
    else
        python_cmd="$python_cmd db.recompute_parent_store('$model');"
    fi

    run_python_cmd "$python_cmd";
}

function odoo_recompute_menu {
    local usage="
    Recompute menu hierarchy.
    Useful to recompute menu hierarchy when it is broken.
    this is usualy caused by errors during update.

    Usage:

        $SCRIPT_NAME odoo recompute-menu <options>  - recompute menu for specified db
        $SCRIPT_NAME odoo recompute-menu --help     - show this help message

    Options:

        -d|--db|--dbname <dbname>  - name of database to recompute menu for
    ";
    if [[ $# -lt 1 ]]; then
        echo "$usage";
        return 0;
    fi

    local dbname=;
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -d|--db|--dbname)
                dbname=$2;
                shift;
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

    if [ -z "$dbname" ]; then
        echoe -e "${REDC}ERROR${NC}: database not specified!";
        return 1;
    fi

    odoo_recompute_stored_fields --db "$dbname" --model 'ir.ui.menu' --parent-store;
}

function odoo_shell {
    local odoo_shell_opts=( );
    local major_version=$(odoo_get_major_version);
    # Check if major_version is a valid number
    if [[ "$major_version" =~ ^[0-9]+$ ]] && [ "$major_version" -gt 10 ]; then
        odoo_shell_opts+=( "--no-http" );
    else
        odoo_shell_opts+=( "--no-xmlrpc" );
    fi
    server_run --no-unbuffer -- shell "${odoo_shell_opts[@]}" "$@";
}

function odoo_clean_compiled_assets {
    local usage="
    Remove compiled assets (css, js, etc) to enforce Odoo
    to regenerate compiled assets.
    This is required some times, when compiled assets are broken,
    and Odoo do not want to regenerate them in usual way.

    Usage:

        $SCRIPT_NAME odoo clean-compiled-assets <options>  - clean-up assets
        $SCRIPT_NAME odoo recompute-menu --help            - show this help

    Options:

        -d|--db|--dbname <dbname>  - name of database to clean-up assets for
    ";
    if [[ $# -lt 1 ]]; then
        echo "$usage";
        return 0;
    fi

    local dbname=;
    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            -d|--db|--dbname)
                dbname=$2;
                shift;
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

    if [ -z "$dbname" ]; then
        echoe -e "${REDC}ERROR${NC}: database not specified!";
        return 1;
    fi
    # TODO select id,name,store_fname from ir_attachment where name ilike '%/web/content/%-%/%';
PGAPPNAME="odoo-helper-clean-compiled-assets" postgres_psql -d "$dbname" << EOF
    DELETE FROM ir_attachment where name ilike '%/web/content/%/web.assets%';
EOF
}

function odoo_command {
    local usage="
    Helper functions for Odoo

    Usage:

        $SCRIPT_NAME odoo recompute --help       - recompute stored fields for database
        $SCRIPT_NAME odoo recompute-menu --help  - recompute menus for db
        $SCRIPT_NAME odoo server-url             - print URL to access this odoo instance
        $SCRIPT_NAME odoo shell                  - open odoo shell
        $SCRIPT_NAME odoo clean-compiled-assets  - Remove compilled versions of assets
        $SCRIPT_NAME odoo --help                 - show this help message

    ";

    if [[ $# -lt 1 ]]; then
        echo "$usage";
        return 0;
    fi

    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            recompute)
                shift;
                odoo_recompute_stored_fields "$@";
                return 0;
            ;;
            recompute-menu)
                shift;
                odoo_recompute_menu "$@";
                return 0;
            ;;
            server-url)
                shift;
                odoo_get_server_url;
                return;
            ;;
            shell)
                shift;
                odoo_shell "$@";
                return;
            ;;
            clean-compiled-assets)
                shift;
                odoo_clean_compiled_assets "$@";
                return;
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
