LD='\033[1m'
RED='\033[0;31m'
GREEN='\033[32m'
WHITE='\033[34m'
YELLOW='\033[33m'
NO_COLOR='\033[0m'
BLUE='\033[0;34m'

function info() {
    (>&2 echo -e "[${WHITE}${BOLD} INFO ${NO_COLOR}] $*")
}

function error() {
    (>&2 echo -e "[${RED} ERROR ${NO_COLOR}] $*")
}

function warning() {
    (>&2 echo -e "[${YELLOW} WARNING ${NO_COLOR}] $*")
}

function ok() {
    (>&2 echo -e "[${GREEN}${BOLD} OK ${NO_COLOR}] $*")
}

function print_delim() {
    echo '================================================='
}

function success() {
    print_delim
    ok "$1"
    print_delim
}

function fail() {
    print_delim
    error "$1"
    print_delim
}

function create_container() {
    ssh_port=$(dialog --stdout --title "Enter ssh port" --inputbox "Port_Used:$(netstat -tuln | grep 'LISTEN' | awk '{print $4}' | awk -F: '{print $NF}' | sort -n --unique | paste -sd "," )" 45 100)
    #ssh_port=$(dialog --stdout --inputbox "Enter your ssh port:" 0 0)
    if [ -z $ssh_port ]; then
        exit 1
    fi

    custom_port=$(dialog --stdout --title "Enter custom port" --inputbox "Port_Used:$(netstat -tuln | grep 'LISTEN' | awk '{print $4}' | awk -F: '{print $NF}' | sort -n --unique | paste -sd "," )" 45 100)
    #custom_port=$(dialog --stdout --inputbox "Enter your custom port:" 0 0)
    if [ -z $custom_port ]; then
        exit 1
    fi

    dialog --yesno "need ai_data?" 0 0
    if [ $? -eq 0 ]; then
        need_data=1
    else
        need_data=0
    fi
    create_container.sh create $ssh_port $custom_port $username $selected_image $need_data '--privileged --cap-add sys_ptrace -e NVIDIA_VISIBLE_DEVICES=all -e NVIDIA_DRIVER_CAPABILITIES=compute,utility'
    docker exec -it $container_name /bin/bash
}

username=$USER

add_or_remove_array=()
add_or_remove_array+=("ADD")
add_or_remove_array+=("add_a_new_container")
add_or_remove_array+=("REMOVE")
add_or_remove_array+=("remove_a_existent_container")
add_or_remove_array+=("SHOW")
add_or_remove_array+=("show_all_your_containers")

add_or_remove=$(dialog --stdout --menu "Select container action:" 0 0 0 ${add_or_remove_array[@]})
if [ -z $add_or_remove ]; then
    exit 1
fi
if [[ $add_or_remove == "SHOW" ]]; then
    echo "Your containers in this server are following: "
    docker ps -a | grep $username
    exit 0
fi

docker_tag=$(docker images --format "{{.Tag}}")
tags_array=()
while read -r line; do
    tags_array+=("$line")
    tags_array+=("-")
done <<< "$docker_tag"

selected_image=$(dialog --stdout --menu "Select an image:" 0 0 0 ${tags_array[@]})
if [ -z $selected_image ]; then
    exit 1
fi
container_name="${selected_image}_${username}"

if [[ $add_or_remove == "ADD" ]]; then
    if [ "$(docker ps -a -q -f name=$container_name)" ]; then
        dialog --yesno "Container $container_name already exists. Do you want to remove and recreate it?" 0 0
        response=$?
        if [ $response -eq 0 ]; then
            docker rm -f $container_name
            create_container
        else
            docker exec -it $container_name /bin/bash
        fi
    else
        create_container
    fi
else
    if [ "$(docker ps -a -q -f name=$container_name)" ]; then
        echo The container $container_name has been removed.
        docker rm -f $container_name
    else
        echo The container $container_name does not exist.
        exit 1
    fi
fi

