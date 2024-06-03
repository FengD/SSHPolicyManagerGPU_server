#!/bin/bash
# Description: This script is used to create container for each user.
# Author: fengding
# Parameters:
# ssh_port: Used for ssh login.
# custom_port: Used for custom usage.
# user: the name of the user. Used for data transform from container to host. It will create a folder in /data/datasets/users/ with the name of the username given. If you want to use other storage, you could mount the storage and create the folder in the volume.
# image tag: the tag of the docker image. The namespace of the image should be the same as it is in the create command part
# ai_data: whether mount a read-only data volume
# option: custom create container options


BOLD='\033[1m'
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
    info "10.30.5.16 airi-server-4010.hirain.local"
    info "10.30.5.17 airi-server-3002.hirain.local"
    info "10.30.5.18 airi-server-0171.hirain.local"
    info "10.30.5.19 airi-server-0205.hirain.local"

    if [ -z $2 ]; then
        fail "ssh_port not given"
        exit 1
    fi
    ssh_port=$2
    is_port_used=$(netstat -an | grep $ssh_port | awk 'END{print NR}')
    if [ $is_port_used -ne 0 ]; then
        fail "The given ssh_port ${ssh_port} is used"
        exit 1
    fi
    info "ssh_port: $ssh_port"

    if [ -z $3 ]; then
        fail "custom_port not given"
        exit 1
    fi
    custom_port=$3
    is_port_used=$(netstat -an | grep $custom_port | awk 'END{print NR}')
    if [ $is_port_used -ne 0 ]; then
        fail "The given custom_port ${custom_port} is used"
        exit 1
    fi
    info "custom_port: $custom_port"

    if [ -z $4 ]; then
        fail "username not given"
        exit 1
    fi
    user=$4
    info "user: $user"

    if [ -z $5 ]; then
        fail "image tag not given"
        exit 1
    fi
    tag=$5
    info "tag: $tag"

    if [ -z $6 ]; then
        warning "Is /data/ai_data/ use in your container? End with: 1(yes) 0(no)"
        exit 1
    fi
    mount_ai_data=""
    if [ $6 -ne 0 ]; then
        info "The container has /data/ai_data!"
        mount_ai_data="--mount type=bind,source=/data/ai_data,destination=/data/ai_data,readonly --mount type=bind,source=/data/hirain_lab_data_b,destination=/data/hirain_lab_data_b,readonly"
    fi

    option=""
    if [ -z $7 ]; then
        info "No option"
        warning "if need -e NVIDIA_VISIBLE_DEVICES=0,1 could be add"
        warning "if cuda not found. -e NVIDIA_VISIBLE_DEVICES=all -e NVIDIA_DRIVER_CAPABILITIES=compute,utility, could be used"
    else
        index=1
        for i in $@; do
            tmp=$i
            if [ $index -gt 6 ]; then
                option="$option $tmp "
            fi
            index=$((index+1))
        done
        info $option
    fi

    mkdir -p /data/ai_data/users/$user
    mkdir -p /data/dataset/$user
    docker run -d --restart=always --shm-size 64g --name="${tag}_${user}" -p $ssh_port:22 -p $custom_port:8000 $option $mount_ai_data -v /data/ai_data/users/$user:/data/dataset/$user dockerhub.com[need change to users]/[namespace]:$tag [/etc/start_ssh.sh optional]
    if [ $? -ne 0 ]; then
        fail "Create container error!"
        exit 1
    fi
    success "Create container success!"
}

function print_usage() {
    echo -e "\n${RED}Usage${NO_COLOR}:"
    echo -e "${BOLD}./create_container.sh${NO_COLOR} [OPTION]"
    echo -e "\n${RED}Options${NO_COLOR}: create container"
    echo -e "\n${BLUE}Examples${NO_COLOR}:"
    info "[ubuntu_1804_ros] create_container.sh create 11111 11112 firstname.lastname ubuntu_1804_ros-v1.0"
    info "[ubuntu_1804] create_container.sh create 11111 11112 firstname.lastname ubuntu_1804-v1.2"
    info "[ubuntu_2004] create_container.sh create 11111 11112 firstname.lastname ubuntu_2004-v2.0"
    info "[ubuntu_2204_ros2] create_container.sh create 11111 11112 firstname.lastname ubuntu_2204_ros2-v1.1"
}

function main() {
    local cmd=$1
    case $cmd in
        create)
            create_container $@
            ;;
        *)
            print_usage
            ;;
    esac
}

main $@

