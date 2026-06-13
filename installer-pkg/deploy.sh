#!/usr/bin/env bash
# -*- coding:utf-8 -*-
#
# Copyright (C) 2024-2026 Apple, Inc.
#

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

# Script commands
COMMAND_INSTALL="INSTALL"
COMMAND_UNINSTALL="UNINSTALL"

#MARK: Defaults
LIST_ROW_LEN=3
DEPENDENCY_DIR="Dependencies"

# Install by default. (Without -i option)
COMMAND=${COMMAND_INSTALL}

LICENSE_FILE="License.txt"

# MARK: Logging
exec 3>&2
verbosity=3
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
inf_lvl=4
dbg_lvl=5
trc_lvl=6
BUILD_CONFIG="Deploy"
notify() { log $silent_lvl "$1"; } # Always prints
critical() { log $crt_lvl "CRITICAL: $1"; }
error() { log $err_lvl "ERROR: $1"; }
warn() { log $wrn_lvl "WARNING: $1"; }
inf() { log $inf_lvl "INFO: $1"; } # "info" is already a command
debug() { log $dbg_lvl "DEBUG: $1"; }
trace() { log $trc_lvl "TRACE: $1"; }
log ()
{
	if [ $verbosity -ge $1 ]; then
		echo "$2" >&3
	fi
}

# MARK: xtrace
shopt -s expand_aliases
_xtrace() {
	if [ $verbosity -ge $trc_lvl ]; then
		case $1 in
			on)
				set -x
				;;
			off)
				set +x
				;;
		esac
	fi
}

alias xtrace='{ _xtrace $(cat); } 2>/dev/null <<<'

# MARK: usage()
usage()
{
cat << EOF
usage: $0 [options]

options:
   -e          : erase (uninstall) packages
   -h          : help
   -i          : install packages
   -v          : verbose
EOF
}

function dislpay_license()
{
  if [ -f ${LICENSE_FILE} ]; then
    cat ${LICENSE_FILE} | more
    read -p "Do you accept this license? [Y/N]: " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      notify "Exiting installation as license is not accepted"
      exit 1
    fi
  fi
}

# Determine what Linux flavor we are running on.
get_linux_flavor() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        echo "unknown"
    fi
}

function install_packages()
{
	local length=${#DEPENDENCY_LIST[*]}
	OS_ID=$(get_linux_flavor)
	for (( i=0; i<length; i += LIST_ROW_LEN ));	do
		local package=${DEPENDENCY_LIST[$i]}
		debug "index: $i name: ${package} OS:${OS_ID}"
		if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
			if [[ "$OS_ID" == "debian" && "$package" == "corefoundation-release" ]]; then
				# corefoundation-release is different for Debian as opposed to UBuntu and RHEL9.
				# append '-debian' to the corefoundation-release artifact name to pick correct file when running on Debian.
				package="${package}-debian"
			fi
			if [[ "$OS_ID" == "ubuntu" && "$package" == "corefoundation-release" ]]; then
				# corefoundation-release is different for Debian as opposed to UBuntu and RHEL9.
				# append '-ubuntu' to the corefoundation-release artifact name to pick correct file when running on Ubuntu.
				package="${package}-ubuntu"
			fi
			local matching_package_name="$(ls -t1 | grep "$package-.*\.deb" | head -n 1)"; shift
			if [[ -n "${matching_package_name}" ]]; then
				notify ""
				notify "Installing ${matching_package_name}"
				dpkg -i "${matching_package_name}"
			fi
		elif [[ "$OS_ID" == "rhel" ]]; then
			local install_options="-Uvh --nodeps ${DEPENDENCY_LIST[$((i + 1))]}"
			local matching_package_name="$(ls -t1 | grep "$package-.*\.rpm" | head -n 1)"; shift
			notify ""
			notify "Installing ${matching_package_name}..."
			debug "rpm ${install_options} ${matching_package_name}"
			rpm ${install_options} "${matching_package_name}"
		else
			error "Unsupported Linux paltform ${OS_ID}"
		fi
	done
}

function remove_packages()
{
    local length=${#DEPENDENCY_LIST[*]}
    # Remove in reverse order
    # First index from the back
    local first_index=$((length - LIST_ROW_LEN))
    local prev_package=""
    for ((i=first_index ; i>=0 ; i -= LIST_ROW_LEN)); do
        local installed_packages
        if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
			installed_packages="$(dpkg -l | awk '{print $2}')"
		elif [[ "$OS_ID" == "rhel" ]]; then
			installed_packages=( $(rpm -qa) )
		fi
        local package=${DEPENDENCY_LIST[$i]}
        # e.g. ifs4l-release --> ifs4l
        local sanitized_package=${package%-*}
        notify "remove_packages sanitized_package is $sanitized_package"
        local remove_options="-ev ${DEPENDENCY_LIST[$((i + 2))]}"

        if [[ ${prev_package} == ${sanitized_package} ]]; then
            continue
        fi
		notify "remove_packages final sanitized_package is $sanitized_package"
        local matching_package_name="$(printf '%s\n' ${installed_packages[@]} | grep -i "${sanitized_package,,}-.*" | head -n 1)"; shift
        notify "Removing package:${package} sanitized_package:${sanitized_package} matching_package_name:${matching_package_name}"

        if [[ -n "${sanitized_package}" ]]; then
			if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
				dpkg -r "${sanitized_package}"
				prev_package=${sanitized_package}
			elif [[ "$OS_ID" == "rhel" ]]; then
				debug "index: $i name: ${package} remove_options: ${remove_options}"
				debug "rpm ${remove_options} `rpm -qa | grep -i ${sanitized_package}-.*`"
				rpm ${remove_options} `rpm -qa | grep -i ${sanitized_package}-.*`
				prev_package=${sanitized_package}
			fi
		fi
		notify ""
    done
}

# Listed in installation order. The order is important.
# List is used for removal in reverse order.
# List format: 'package_name' '<install_options>' '<remove_options>'
#
# install_options - additional options used during package installation. Ex: --force --nodeps
# remove_options - additional options used during package removal.

DEPENDENCY_LIST=(
	'libblocksruntime-release' '' ''
	'libdispatch-release' '' ''
	'libmd-release' '' ''
	'libbsd-release' '' ''
	'corefoundation-release' '' ''
	'IFS4L-release' '' ''
	'calinuxbase-release' '' ''
	'caulk-release' '' ''
	'coreaudioservices-release' '' ''
	'audiocodecs-hls-public' '' ''
	'CoreGraphics-hls' '' ''
	'ColorSync-release' '' ''
	'CoreVideo-release' '' ''
)

pushd "${SCRIPT_DIR}" > /dev/null

# MARK: - Collect Options
while getopts dehirv option
do
	case $option in
		e)
			COMMAND=${COMMAND_UNINSTALL}
			;;
		h)
			usage
			exit
			;;
		i)
			COMMAND=${COMMAND_INSTALL}
			;;
		v)
			if [ $verbosity -lt $dbg_lvl ];then
				verbosity=$dbg_lvl
			fi
			;;
		?)
			usage
			exit
			;;
	esac
done

debug "DEPENDENCY_LIST: ${DEPENDENCY_LIST[*]}"
# Check dependency list
length=${#DEPENDENCY_LIST[*]}
if [ $((length % $LIST_ROW_LEN)) -ne 0 -o  $length -eq 0 ]; then
	usage "Config error: incomplete dependency list"
fi

if [ -z ${COMMAND} ]; then
	echo "No command specified."
	usage
	exit
fi

OS_ID=$(get_linux_flavor)
platform_dir=""
if [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
	platform_dir="deb"
elif [[ "$OS_ID" == "rhel" ]]; then
	platform_dir="rhel"
else
	error "Unsupported Linux platform $OS_ID"
	exit -1
fi

case "${COMMAND}" in
	${COMMAND_INSTALL} )
        # display license
        dislpay_license

		notify "Installing packages..."
		if [ ! -d "${DEPENDENCY_DIR}/${BUILD_CONFIG}/${platform_dir}" ]
		then
			echo "${DEPENDENCY_DIR}/${BUILD_CONFIG}/${platform_dir} does not exist..."
			exit
		fi
		
		# Install packages
		pushd "${DEPENDENCY_DIR}/${BUILD_CONFIG}/${platform_dir}" > /dev/null
		install_packages
		popd > /dev/null
		
		# Install tools
		notify ""
		notify "Installing hlstools..."
		if [[ "$OS_ID" == "ubuntu" ]]; then
			if [ -f hlstools-ubuntu-*.deb ]; then
				debug "hlstools package found."
				dpkg -i hlstools-ubuntu-*.deb
			else
				warn "No ubuntu hlstools package found. Skipping."
			fi
		elif [[ "$OS_ID" == "debian" ]]; then
			if [ -f hlstools-debian-*.deb ]; then
				debug "hlstools package found."
				dpkg -i hlstools-debian-*.deb
			else
				warn "No debian hlstools package found. Skipping."
			fi
		elif [[ "$OS_ID" == "rhel" ]]; then
			if [ -f hlstools-*.rpm ]; then
				debug "hlstools package found."
				rpm -Uvh hlstools-*.rpm
			else
				warn "No rhel hlstools package found. Skipping."
			fi
		fi
		notify ""
		notify "Done"
		;;

	${COMMAND_UNINSTALL} )
		notify "Removing packages..."
		# Remove tools
		notify ""
		notify "Removing hlstools..."
		case "$OS_ID" in
			ubuntu|debian)
				hlstools_package_name="$(dpkg -l | grep "hlstools" | awk '{print $2}')"
				if [ -z ${hlstools_package_name} ]; then
					warn "No hlstools package found. Skipping."
				else
					dpkg -r ${hlstools_package_name}
				fi
			;;
			rhel)
				hlstools_package_name="$(rpm -qa | grep "hlstools-.*" | head -n 1)"
				if [ -z ${hlstools_package_name} ]; then
					warn "No hlstools package found. Skipping."
				else
					rpm -ev ${hlstools_package_name}
				fi
			;;
		*)
		;;
		esac
		notify ""
		# Remove packages
		pushd "${DEPENDENCY_DIR}" > /dev/null
		remove_packages
		popd > /dev/null

		notify ""
		notify "Done"
		;;			
	?)
		error "Undefined command"
		exit -1 ;;
esac

popd > /dev/null
