#!/bin/sh
#
# Owasys Yocto Project Build Environment Setup Script
#
# Copyright (C) 2011-2016 Freescale Semiconductor
# Copyright 2017 NXP
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

. sources/meta-imx/tools/setup-utils.sh

CWD=`pwd`
PROGNAME="setup-environment"

# get command line options
OLD_OPTIND=$OPTIND
unset FSLDISTRO

while getopts "k:r:t:b:e:gh" fsl_setup_flag
do
    case $fsl_setup_flag in
        b) BUILD_DIR="$OPTARG";
        echo -e "\nBuild directory is "$BUILD_DIR
        ;;
        h) fsl_setup_help='true';
        ;;
        \?) fsl_setup_error='true';
        ;;
    esac
done
shift $((OPTIND-1))
if [ $# -ne 0 ]; then

    fsl_setup_error=true
    echo -e "Invalid command line ending: '$@'"
fi
OPTIND=$OLD_OPTIND
if test $fsl_setup_help; then
    usage && clean_up && return 1
elif test $fsl_setup_error; then
    clean_up && return 1
fi

#===========================DISTRO IMPORTANT VARIABLES================================
FW_VERSION="1.0.0"
PROJECT_CONFIGURATION=0

################################# aux functions #############################

select_build() {
    echo ""
    echo "=> What would you like to build?"
    echo "1) Yocto image"
    echo "2) Full OTA update file"
    echo "3) Delta OTA update files"
    echo "4) Bootable SD flasher image"
    read -r -p "Option $(tput bold)[1/2/3/4]:$(tput sgr 0) " response
    tput sgr0
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(1)$ ]]; then
        configure_flashable_image

    elif [[ "$response" =~ ^(2)$ ]]; then
        create_full_ota_bundle

    elif [[ "$response" =~ ^(3)$ ]]; then
        create_diff_ota_bundle

    elif [[ "$response" =~ ^(4)$ ]]; then
        configure_bootable_usd_image

    else
        echo ""
        echo "Please choose options "1","2","3" or "4"..."
        echo ""
        select_build
    fi

}

select_layer_odm()
{
    echo ""
    echo "=> Add Owasys Device Manager layer?"
    read -r -p "Option $(tput bold)[y/n]:$(tput sgr 0) " response
    tput sgr0
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(y)$ ]]; then
        configure_layer_odm
    elif [[ "$response" =~ ^(n)$ ]]; then
        echo "Won't go with ODM layer..."
    else
        echo ""
        echo "Please answer "y" or "n"..."
        echo ""
        select_layer_odm
    fi
}

select_layer_machine_learning()
{
    echo ""
    echo "=> Add Owasys Machine Learning layer?"
    read -r -p "Option $(tput bold)[y/n]:$(tput sgr 0) " response
    tput sgr0
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(y)$ ]]; then
        echo "Adding meta-owasys-owa5x-ml layer..."
        echo "BBLAYERS += \"\${BSPDIR}/sources/meta-owasys-owa5x-ml\"" >> $BUILD_DIR/conf/bblayers.conf

    elif [[ "$response" =~ ^(n)$ ]]; then
        echo "Won't go with machine learning layer..."

    else
        echo ""
        echo "Please answer "y" or "n"..."
        echo ""
        configure_layer_machine_learning
    fi    
}

select_layers() {
    select_layer_machine_learning
}

configure_layer_odm()
{
    echo "Adding meta-owasys-owa5x-odm layer..."
    echo "BBLAYERS += \"\${BSPDIR}/sources/meta-owasys-owa5x-odm\"" >> $BUILD_DIR/conf/bblayers.conf

    # ODM VARS
    odm_credentials_configuration
    odm_certs_configuration
    custom_app_version_configuration
    IS_BUNDLE=0
    if [ $PROJECT_CONFIGURATION == 2 ] || [ $PROJECT_CONFIGURATION == 3 ]; then
        IS_BUNDLE=1
    fi

    change_or_add_value_to_conf "ODM_APP_VERSION" "$ODM_APP_VERSION" "# Version of the custom app" 1
    change_or_add_value_to_conf "ODM_APP_NAME" "$ODM_APP_NAME" "# Name of the custom app"
    change_or_add_value_to_conf "ODM_APP_DESCRIPTION" "$ODM_APP_DESCRIPTION" "# Description of the custom app"
    change_or_add_value_to_conf "ODM_USER" "$ODM_USER" "# Your ODM login user" 
    change_or_add_value_to_conf "ODM_PASS" "$ODM_PASS" "# Your ODM login password"
    change_or_add_value_to_conf "CERT_KEY_NAME" "$CERT_KEY_NAME" "# The path to your private certificate key, for signing the Rauc bundles"
    change_or_add_value_to_conf "CERT_NAME" "$CERT_NAME" "# The path to your public certificate, for signing the Rauc bundles"
    change_or_add_value_to_conf "TRUST_CHAIN" "$TRUST_CHAIN" "# The path to your certificate trust chain, public certs of the root and the intermediate CA that signed your certificate"
    change_or_add_value_to_conf "UPLOAD_BUNDLE" 1 "# Whether to upload the bundle to the ODM or not"
    change_or_add_value_to_conf "IS_BUNDLE" "$IS_BUNDLE" "# Is it a RAUC bundle?"   
}

change_or_add_value_to_conf() {
    local pattern="$1"
    local value="$2"
    local explanation="$3"
    local first=${4:-0}
    grep -q $pattern $BUILD_DIR/conf/local.conf
    if [[ $? -eq 0 ]]; then
        sed -i "/\\$pattern/ {s&=.*&= \"$value\"&}" $BUILD_DIR/conf/local.conf
    else
        if [[ $first -eq 1 ]]; then
            echo >> $BUILD_DIR/conf/local.conf
        fi
        echo "$explanation" >> $BUILD_DIR/conf/local.conf
        echo "$pattern ?= \"$value\"" >> $BUILD_DIR/conf/local.conf
    fi
}

custom_app_version_configuration() {
    local default_version
    default_version="$(cat $BUILD_DIR/conf/local.conf| grep ODM_APP_VERSION | tr -d '"')"
    default_version=${default_version#*=} # get value from the '=' symbol
    default_version=${default_version##*( )} # trim
    default_version=${default_version:-"1.0.0"}
    echo ""
    echo "User App configuration"
    echo "=> Enter your custom app version"
    read -r -p "$(tput bold)[$default_version]:$(tput sgr 0) " ODM_APP_VERSION
    tput sgr0
    ODM_APP_VERSION=${ODM_APP_VERSION:-$default_version}

    local default_name
    default_name="$(cat $BUILD_DIR/conf/local.conf| grep ODM_APP_NAME | tr -d '"')"
    default_name=${default_name#*=}
    default_name=${default_name##*( )}
    default_name=${default_name:-"odm"}
    echo ""
    echo "=> Enter your custom app name"
    read -r -p "$(tput bold)[$default_name]:$(tput sgr 0) " ODM_APP_NAME
    tput sgr0
    ODM_APP_NAME=${ODM_APP_NAME:-$default_name}

    local default_description
    default_description="$(cat $BUILD_DIR/conf/local.conf| grep ODM_APP_DESCRIPTION | tr -d '"')"
    default_description=${default_description#*=}
    default_description=${default_description##*( )}
    default_description=${default_description:-"ODM reference app"}
    echo ""
    echo "=> Enter your custom app description"
    read -r -p "$(tput bold)[$default_description]:$(tput sgr 0) " ODM_APP_DESCRIPTION
    tput sgr0
    ODM_APP_DESCRIPTION=${ODM_APP_DESCRIPTION:-$default_description}
}

odm_credentials_configuration() {
    local default_user
    default_user="$(cat $BUILD_DIR/conf/local.conf| grep ODM_USER | tr -d '"')"
    default_user=${default_user#*=}
    default_user=${default_user##*( )}
    echo ""
    echo "ODM credentials configuration"
    echo "=> Enter your ODM user"
    read -r -p "$(tput bold)[$default_user]:$(tput sgr 0) " ODM_USER
    tput sgr0
    ODM_USER=${ODM_USER:-$default_user}

    local default_pass
    default_pass="$(cat $BUILD_DIR/conf/local.conf| grep ODM_PASS | tr -d '"')"
    default_pass=${default_pass#*=}
    default_pass=${default_pass##*( )}
    echo ""
    echo "=> Enter your ODM password"
    read -r -p "$(tput bold)[$default_pass]:$(tput sgr 0) " ODM_PASS
    tput sgr0
    ODM_PASS=${ODM_PASS:-$default_pass}
}

odm_certs_configuration() {
    local default_cert_name
    default_cert_name="$(cat $BUILD_DIR/conf/local.conf| grep CERT_NAME | tr -d '"')"
    default_cert_name=${default_cert_name#*=}
    default_cert_name=${default_cert_name##*( )}
    echo ""
    echo "ODM certificates configuration"
    echo "=> Enter the path to your public certificate"
    read -r -p "$(tput bold)[$default_cert_name]:$(tput sgr 0) " CERT_NAME
    tput sgr0
    CERT_NAME=${CERT_NAME:-$default_cert_name}
    #if [[ ! -f "$CERT_NAME" ]]; then
    #    echo ""
    #    echo "Bad cert path ($CERT_NAME). Aborting building process..."
    #    echo ""
    #    exit 1
    #fi

    local default_cert_key
    default_cert_key="$(cat $BUILD_DIR/conf/local.conf| grep CERT_KEY_NAME | tr -d '"')"
    default_cert_key=${default_cert_key#*=}
    default_cert_key=${default_cert_key##*( )}
    echo ""
    echo "=> Enter the path to your private certificate key"
    read -r -p "$(tput bold)[$default_cert_key]:$(tput sgr 0) " CERT_KEY_NAME
    tput sgr0
    CERT_KEY_NAME=${CERT_KEY_NAME:-$default_cert_key}
    #if [[ ! -f "$CERT_KEY_NAME" ]]; then
    #    echo ""
    #    echo "Bad cert key path ($CERT_KEY_NAME). Aborting building process..."
    #    echo ""
    #    exit 1
    #fi

    local default_trust_chain
    default_trust_chain="$(cat $BUILD_DIR/conf/local.conf| grep TRUST_CHAIN | tr -d '"')"
    default_trust_chain=${default_trust_chain#*=}
    default_trust_chain=${default_trust_chain##*( )}
    echo ""
    echo "=> Enter the path to your trust chain (root and intermediate CA public certificates)"
    read -r -p "$(tput bold)[$default_trust_chain]:$(tput sgr 0) " TRUST_CHAIN
    tput sgr0
    TRUST_CHAIN=${TRUST_CHAIN:-$default_trust_chain}
    #if [[ ! -f "$TRUST_CHAIN" ]]; then
    #    echo ""
    #    echo "Bad trust chain path ($TRUST_CHAIN). Aborting building process..."
    #    echo ""
    #    exit 1
    #fi
}

configure_developer_mode()
{
    # is meta-owasys-owa5x-sdk available at sources/ ?
    if [ -d ../sources/meta-owasys-owa5x-sdk ]; then
        echo ""
        echo "=> Would you like to add SDK layer so you can work with fresh binaries? "
        read -r -p "Option $(tput bold)[y/n]:$(tput sgr 0) " response
        tput sgr0
        response=${response:-y}
        if [[ "$response" =~ ^(y)$ ]]; then
            echo "BBLAYERS += \"\${BSPDIR}/sources/meta-owasys-owa5x-sdk\"" >> $BUILD_DIR/conf/bblayers.conf

        elif [[ "$response" =~ ^(n)$ ]]; then
            echo ""
        else
            echo ""
            echo "Please choose "Y" or "N" "
            echo ""
            configure_developer_mode
        fi
    fi
}

configure_dry_build() {

    echo ""
    echo "=> Would you like us to launch the build for you at the end?"
    read -r -p "Option $(tput bold)[y/n]:$(tput sgr 0) " response
    response=${response:-y}
    tput sgr0
    response=${response,,}    # tolower
    if [[ "$response" =~ ^(y)$ ]]; then
        echo ""
        echo "Cooking the image in a few seconds..."
        echo ""
        DRY_BUILD=1
    elif [[ "$response" =~ ^(n)$ ]]; then
        echo ""
        echo "Okay, we'll let you bitbake recipes..."
        echo ""
        DRY_BUILD=0
    else
        echo ""
        echo "Aborting building process..."
        echo ""
        exit 1
    fi 

}

configure_flashable_image() {

    PROJECT_CONFIGURATION=1
    select_layers
    select_layer_odm
    configure_dry_build

}

create_full_ota_bundle() {
    PROJECT_CONFIGURATION=2
    DRY_BUILD=1
    change_or_add_value_to_conf "DIFF_UPDATE" "0" "# Whether is diff or full update"
    select_layers
    configure_layer_odm
    change_or_add_value_to_conf "DIFF_UPDATE" 0 "# Whether is diff or full update"
}

create_diff_ota_bundle() {
    PROJECT_CONFIGURATION=3
    DRY_BUILD=1
    change_or_add_value_to_conf "DIFF_UPDATE" "1" "# Whether is diff or full update"
    select_layers
    configure_layer_odm
    change_or_add_value_to_conf "DIFF_UPDATE" 1 "# Whether is diff or full update"
}

configure_bootable_usd_image() {
    PROJECT_CONFIGURATION=4
    select_layers
    select_layer_odm
    configure_dry_build
}

show_chosen_build_options()
{   
    cat <<EOF
Your build environment has been configured with:
    MACHINE=$MACHINE
    SDKMACHINE=$SDKMACHINE
    DISTRO=$DISTRO
    EULA=$FSL_EULA_FILE
EOF

}

bitbake_image()
{
    if [ "$DRY_BUILD" = 1 ]; then 
        if [ "$PROJECT_CONFIGURATION" = 1 ]; then
            bitbake -c clean imx-boot-owasys; bitbake -c clean owa5-image-nand; bitbake owa5-image-nand
        elif [ "$PROJECT_CONFIGURATION" = 2 ] || [ "$PROJECT_CONFIGURATION" == 3 ]; then
            bitbake -c clean imx-boot-owasys; bitbake -c clean owa5-image-nand; bitbake owa5x-rootfs-bundle
        elif [ "$PROJECT_CONFIGURATION" = 4 ]; then
            bitbake -c clean imx-boot-owasys; bitbake -c clean owa5-image-nand; bitbake owa5-bootable-usd
        else 
            echo "We haven't got that image, sorry for the inconvenience"
        fi
    else
    cat <<EOF

You can now run 'bitbake <target>'

Common Owasys targets are:
    bitbake owa5-image-nand
    bitbake owa5x-rootfs-bundle

EOF
    fi
}

put_os_id_in_conf() {
    grep -q OS_ID $BUILD_DIR/conf/local.conf
    if [[ $? -ne 0 ]]; then
        echo "OS_ID ?= \"yocto\"" >> $BUILD_DIR/conf/local.conf
    fi
}


#cleanup() {
#    echo "Cleaning...."
#    rm -rf "$WARNING_TMP_FILE"
#    sudo rm -rf "${BUILD_TMP_DIR:?}"/*
#}

################################# main function #############################

exit_message ()
{
   echo "To return to this build environment later please run:"
   echo "    source setup-environment <build_dir>"

}

usage()
{
    echo -e "\nUsage: source imx-setup-release.sh
    Optional parameters: [-b build-dir] [-h]"
echo "
    * [-b build-dir]: Build directory, if unspecified script uses 'build' as output directory
    * [-h]: help
"
}


clean_up()
{

    unset CWD BUILD_DIR FSLDISTRO
    unset fsl_setup_help fsl_setup_error fsl_setup_flag
    unset usage clean_up
    unset ARM_DIR META_FSL_BSP_RELEASE
    exit_message clean_up
}

normal_flow()
{
    if [ -z "$DISTRO" ]; then
        if [ -z "$FSLDISTRO" ]; then
            FSLDISTRO='owa5'
        fi
    else
        FSLDISTRO="$DISTRO"
    fi

    if [ -z "$BUILD_DIR" ]; then
        BUILD_DIR='build'
    fi

    if [ -z "$SDKMACHINE" ]; then
        SDKMACHINE='i686'
    fi

    if [ -z "$MACHINE" ]; then
        echo setting to default machine owa5x
        MACHINE='owa5x'
    fi

    case $MACHINE in
    imx8*)
        case $DISTRO in
        *owa5)
            : ok
            ;;
        *)
            echo -e "\n ERROR - Only Wayland distros are supported for i.MX 8 or i.MX 8M"
            echo -e "\n"
            return 1
            ;;
        esac
        ;;
    *)
        : ok
        ;;
    esac

    # Cleanup previous meta-freescale/EULA overrides
    cd $CWD/sources/meta-freescale
    if [ -h EULA ]; then
        echo Cleanup meta-freescale/EULA...
        git checkout -- EULA
    fi
    if [ ! -f classes/fsl-eula-unpack.bbclass ]; then
        echo Cleanup meta-freescale/classes/fsl-eula-unpack.bbclass...
        git checkout -- classes/fsl-eula-unpack.bbclass
    fi
    cd -

    # Override the click-through in meta-freescale/EULA
    FSL_EULA_FILE=$CWD/sources/meta-imx/EULA.txt

    # Set up the basic yocto environment
    if [ -z "$DISTRO" ]; then
        DISTRO=$FSLDISTRO MACHINE=$MACHINE . ./$PROGNAME $BUILD_DIR
    else
        MACHINE=$MACHINE . ./$PROGNAME $BUILD_DIR
    fi

    # Point to the current directory since the last command changed the directory to $BUILD_DIR
    BUILD_DIR=.

    if [ ! -e $BUILD_DIR/conf/local.conf ]; then
        echo -e "\n ERROR - No build directory is set yet. Run the 'setup-environment' script before running this script to create " $BUILD_DIR
        echo -e "\n"
        return 1
    fi

    # On the first script run, backup the local.conf file
    # Consecutive runs, it restores the backup and changes are appended on this one.
    if [ ! -e $BUILD_DIR/conf/local.conf.org ]; then
        cp $BUILD_DIR/conf/local.conf $BUILD_DIR/conf/local.conf.org
    else
        cp $BUILD_DIR/conf/local.conf.org $BUILD_DIR/conf/local.conf
    fi

    if [ ! -e $BUILD_DIR/conf/bblayers.conf.org ]; then
        cp $BUILD_DIR/conf/bblayers.conf $BUILD_DIR/conf/bblayers.conf.org
    else
        cp $BUILD_DIR/conf/bblayers.conf.org $BUILD_DIR/conf/bblayers.conf
    fi

    put_os_id_in_conf

    META_FSL_BSP_RELEASE="${CWD}/sources/meta-imx/meta-bsp"

    echo "" >> $BUILD_DIR/conf/bblayers.conf
    echo "# i.MX Yocto Project Release layers" >> $BUILD_DIR/conf/bblayers.conf
    hook_in_layer meta-imx/meta-bsp
    hook_in_layer meta-imx/meta-sdk
    hook_in_layer meta-imx/meta-ml

    echo "" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${BSPDIR}/sources/meta-openembedded/meta-gnome\"" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${BSPDIR}/sources/meta-openembedded/meta-networking\"" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${BSPDIR}/sources/meta-openembedded/meta-filesystems\"" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${BSPDIR}/sources/meta-security/meta-tpm\"" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${BSPDIR}/sources/meta-rauc\"" >> $BUILD_DIR/conf/bblayers.conf
    
    echo "#Owasys Layers" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${BSPDIR}/sources/meta-owasys-owa5x-bsp\"" >> $BUILD_DIR/conf/bblayers.conf
    echo "BBLAYERS += \"\${BSPDIR}/sources/meta-owasys-owa5x-security\"" >> $BUILD_DIR/conf/bblayers.conf


    # Support integrating community meta-freescale instead of meta-fsl-arm
    if [ -d ../sources/meta-freescale ]; then
        # Change settings according to environment
        sed -e "s,meta-fsl-arm\s,meta-freescale ,g" -i conf/bblayers.conf
        sed -e "s,\$.BSPDIR./sources/meta-fsl-arm-extra\s,,g" -i conf/bblayers.conf
    fi

}

make_local_conf_backup() {
    cp $BUILD_DIR/conf/local.conf $BUILD_DIR/conf/local.conf.org
}

main() 
{
    normal_flow
    configure_developer_mode
    select_build
    show_chosen_build_options
    make_local_conf_backup
    #cd $BUILD_DIR
    clean_up
    unset FSLDISTRO
    bitbake_image

}

#trap cleanup EXIT
main "$@"
