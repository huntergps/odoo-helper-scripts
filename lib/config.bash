# Copyright © 2017-2018 Dmytro Katyukha <dmytro.katyukha@gmail.com>

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
# -----------------------------------------------------------------------------

# function to print odoo-helper config
function config_print {
    echo "PROJECT_ROOT_DIR=$PROJECT_ROOT_DIR;";
    echo "PROJECT_CONFIG_VERSION=$PROJECT_CONFIG_VERSION;";
    echo "ODOO_VERSION=$ODOO_VERSION;";
    echo "ODOO_BRANCH=$ODOO_BRANCH;";
    echo "CONF_DIR=$CONF_DIR;";
    echo "LOG_DIR=$LOG_DIR;";
    echo "LOG_FILE=$LOG_FILE;";
    echo "LIBS_DIR=$LIBS_DIR;";
    echo "DOWNLOADS_DIR=$DOWNLOADS_DIR;";
    echo "ADDONS_DIR=$ADDONS_DIR;";
    echo "DATA_DIR=$DATA_DIR;";
    echo "BIN_DIR=$BIN_DIR;";
    echo "VENV_DIR=$VENV_DIR;";
    echo "ODOO_PATH=$ODOO_PATH;";
    echo "ODOO_CONF_FILE=$ODOO_CONF_FILE;";
    echo "ODOO_TEST_CONF_FILE=$ODOO_TEST_CONF_FILE;";
    echo "ODOO_PID_FILE=$ODOO_PID_FILE;";
    echo "BACKUP_DIR=$BACKUP_DIR;";
    echo "REPOSITORIES_DIR=$REPOSITORIES_DIR;";
    
    if [ -n "$INIT_SCRIPT" ]; then
        echo "INIT_SCRIPT=$INIT_SCRIPT;";
    fi
    if [ -n "$ODOO_REPO" ]; then
        echo "ODOO_REPO=$ODOO_REPO;";
    fi
}


# Function to configure default variables
function config_set_defaults {
    if [ -z "$PROJECT_ROOT_DIR" ]; then
        echo -e "${REDC}There is no PROJECT_ROOT_DIR set!${NC}";
        return 1;
    fi
    PROJECT_CONFIG_VERSION="${PROJECT_CONFIG_VERSION:-$ODOO_HELPER_CONFIG_VERSION}";
    CONF_DIR="${CONF_DIR:-$PROJECT_ROOT_DIR/conf}";
    ODOO_CONF_FILE="${ODOO_CONF_FILE:-$CONF_DIR/odoo.conf}";
    ODOO_TEST_CONF_FILE="${ODOO_TEST_CONF_FILE:-$CONF_DIR/odoo.test.conf}";
    LOG_DIR="${LOG_DIR:-$PROJECT_ROOT_DIR/logs}";
    LOG_FILE="${LOG_FILE:-$LOG_DIR/odoo.log}";
    LIBS_DIR="${LIBS_DIR:-$PROJECT_ROOT_DIR/libs}";
    DOWNLOADS_DIR="${DOWNLOADS_DIR:-$PROJECT_ROOT_DIR/downloads}";
    ADDONS_DIR="${ADDONS_DIR:-$PROJECT_ROOT_DIR/custom_addons}";
    DATA_DIR="${DATA_DIR:-$PROJECT_ROOT_DIR/data}";
    BIN_DIR="${BIN_DIR:-$PROJECT_ROOT_DIR/bin}";
    VENV_DIR="${VENV_DIR:-$PROJECT_ROOT_DIR/venv}";
    ODOO_PID_FILE="${ODOO_PID_FILE:-$PROJECT_ROOT_DIR/odoo.pid}";
    ODOO_PATH="${ODOO_PATH:-$PROJECT_ROOT_DIR/odoo}";
    BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT_DIR/backups}";
    REPOSITORIES_DIR="${REPOSITORIES_DIR:-$PROJECT_ROOT_DIR/repositories}";
    INIT_SCRIPT="${INIT_SCRIPT}";
}

# Return default config for specified tool
# TODO: look at project level for configuration files
function config_get_default_tool_conf {
    local default_conf_dir="${ODOO_HELPER_LIB}/default_config";
    local tool_name="$1";
    local tool_conf="$default_conf_dir/$tool_name";
    if [ -f "$tool_conf" ]; then
        echo "$tool_conf";
    else
        return 1;
    fi
}

# Check current project configuration
function config_check_project_config {
    local proj_conf_version=${PROJECT_CONFIG_VERSION:-0};
    local expected_conf_version=${ODOO_HELPER_CONFIG_VERSION};
    if [[ $proj_conf_version -ge $expected_conf_version ]]; then
        return 0;
    fi

    echoe -e "${YELLOWC}WARNING${NC}: Current project config version" \
             "${YELLOWC}${proj_conf_version}${NC} is less than" \
             "odoo-helper expected config version ${YELLOWC}${expected_conf_version}${NC}.\n" \
             "Please, upgrade config file for this project (${YELLOWC}$ODOO_HELPER_PROJECT_CONF${NC})!";
    if [ -z "$PROJECT_CONFIG_VERSION" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}PROJECT_CONFIG_VERSION${NC} is not specified.";
    fi
    if [ -z "$PROJECT_ROOT_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}PROJECT_ROOT_DIR${NC} is not specified.";
    fi
    if [ -z "$CONF_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}CONF_DIR${NC} is not specified.";
    fi
    if [ -z "$ODOO_CONF_FILE" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}ODOO_CONF_FILE${NC} is not specified.";
    fi
    if [ -z "$ODOO_TEST_CONF_FILE" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}ODOO_TEST_CONF_FILE${NC} is not specified.";
    fi
    if [ -z "$LOG_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}LOG_DIR${NC} is not specified.";
    fi
    if [ -z "$LOG_FILE" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}LOG_FILE${NC} is not specified.";
    fi
    if [ -z "$LIBS_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}LIBS_DIR${NC} is not specified.";
    fi
    if [ -z "$DOWNLOADS_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}DOWNLOADS_DIR${NC} is not specified.";
    fi
    if [ -z "$ADDONS_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}ADDONS_DIR${NC} is not specified.";
    fi
    if [ -z "$DATA_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}DATA_DIR${NC} is not specified.";
    fi
    if [ -z "$BIN_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}BIN_DIR${NC} is not specified.";
    fi
    if [ -z "$ODOO_PID_FILE" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}ODOO_PID_FILE${NC} is not specified.";
    fi
    if [ -z "$ODOO_PATH" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}ODOO_PATH${NC} is not specified.";
    fi
    if [ -z "$BACKUP_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}BACKUP_DIR${NC} is not specified.";
    fi
    if [ -z "$REPOSITORIES_DIR" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}REPOSITORIES_DIR${NC} is not specified.";
    fi
    if [ -z "$ODOO_VERSION" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}ODOO_VERSION${NC} is not specified.";
    fi
    if [ -z "$ODOO_BRANCH" ]; then
        echoe -e "${YELLOWC}WARNING${NC}: config variable ${YELLOWC}ODOO_BRANCH${NC} is not specified.";
    fi
}


# Load project configuration. No args provided
function config_load_project {
    local project_conf;
    local work_dir="${1:-$(pwd)}";
    if [ -z "$PROJECT_ROOT_DIR" ]; then
        # Load project conf, only if it is not loaded yet.
        project_conf=$(search_file_up "$work_dir" "$CONF_FILE_NAME");
        if [ -f "$project_conf" ] && [ ! "$project_conf" == "$HOME/odoo-helper.conf" ]; then
            echov -e "${LBLUEC}Loading conf${NC}: $project_conf";
            ODOO_HELPER_PROJECT_CONF=$project_conf;
            source "$project_conf";

            # Set configuration defaults
            config_set_defaults;
        fi

        if [ -z "$PROJECT_ROOT_DIR" ]; then
            echoe -e "${YELLOWC}WARNING${NC}: no project config file found!";
        else
            config_check_project_config;
        fi

    fi
}

