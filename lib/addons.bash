if [ -z $ODOO_HELPER_LIB ]; then
    echo "Odoo-helper-scripts seems not been installed correctly.";
    echo "Reinstall it (see Readme on https://github.com/katyukha/odoo-helper-scripts/)";
    exit 1;
fi

if [ -z $ODOO_HELPER_COMMON_IMPORTED ]; then
    source $ODOO_HELPER_LIB/common.bash;
fi

# ----------------------------------------------------------------------------------------

set -e; # fail on errors


# List addons repositories
# Note that this function list only addons that are under git control
#
# addons_list_repositories [addons_path]
function addons_list_repositories {
    local addons_path=${1:-$ADDONS_DIR};
    local cdir=`pwd`;

    for addon in "$addons_path"/*; do
        cd $addon;
        if is_odoo_module . && ([ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1); then
            echo "$(git rev-parse --show-toplevel)";
        fi
        cd $cdir;
    done | sort -u;
}


# Show git status for each addon
# show_addons_status
function addons_show_status {
    local addons_dir=$ADDONS_DIR;
    local cdir=$(pwd);

    local usage="
    Usage 

        $SCRIPT_NAME addons show_status [options]

    Options:
        --addons-dir        - directory to search addons in. By default used one from
                              project config
        --only-unclean      - show only addons in unclean repo state
        --help|-h           - diplay this help message
    ";

    # Parse command line options and run commands
    while [[ $# -gt 0 ]]
    do
        key="$1";
        case $key in
            -h|--help|help)
                echo "$usage";
                exit 0;
            ;;
            --addons-dir)
                local addons_dir=$2;
                shift;
            ;;
            --only-unclean)
                local only_unclean=1
            ;;
            *)
                echo "Unknown option: $key";
                exit 1;
            ;;
        esac;
        shift;
    done;

    local git_status=;
    for addon_repo in $(addons_list_repositories $addons_dir); do
        IFS=$'\n' git_status=( $(git_parse_status $addon_repo || echo '') );
        if [ -z $git_status ]; then
            echo -e "No info available for addon $addon_repo";
            continue;
        fi

        if [ ! -z $only_unclean ] && [ ${git_status[3]} -eq 1 ]; then
            continue
        fi

        echo -e "Addon status for ${BLUEC}$addon_repo${NC}'";
        echo -e "\tRepo branch:          ${git_status[0]}";
        echov -e "\tRepo remote status:   ${git_status[1]}";
        echov -e "\tRepo upstream:        ${git_status[2]}";

        [ ${git_status[3]} -eq 1 ] && echo -e "\t${GREENC}Repo is clean!${NC}";
        [ ${git_status[4]} -gt 0 ] && echo -e "\t${YELLOWC}${git_status[4]} files staged for commit${NC}";
        [ ${git_status[5]} -gt 0 ] && echo -e "\t${YELLOWC}${git_status[5]} files changed${NC}";
        [ ${git_status[6]} -gt 0 ] && echo -e "\t${REDC}${git_status[6]} conflicts${NC}";
        [ ${git_status[7]} -gt 0 ] && echo -e "\t${YELLOWC}${git_status[7]} untracked files${NC}";
        [ ${git_status[8]} -gt 0 ] && echo -e "\t${YELLOWC}${git_status[8]} stashed${NC}";
    done;
}

function addons_command {
    local usage="Usage:

        $SCRIPT_NAME addons list_repos [addons path]
        $SCRIPT_NAME addons git_status --help
        $SCRIPT_NAME addons --help

    ";

    if [[ $# -lt 1 ]]; then
        echo "$usage";
        exit 0;
    fi

    while [[ $# -gt 0 ]]
    do
        local key="$1";
        case $key in
            list_repos)
                shift;
                addons_list_repositories "$@";
                exit 0;
            ;;
            show_status)
                shift;
                addons_show_status "$@";
                exit 0;
            ;;
            -h|--help|help)
                echo "$usage";
                exit 0;
            ;;
            *)
                echo "Unknown option / command $key";
                exit 1;
            ;;
        esac
        shift
    done
}
