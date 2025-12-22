#!/bin/bash
# Bootstrapper for buildbot slave

BUILD_DIR=.
PROGNAME="setup.sh"
DIR=$1
MACHINE="qemuriscv64"
DISTRO="poky-altcfg"
PACKAGE_CLASSES=${PACKAGE_CLASSES:-package_rpm}
SDKMACHINE=${SDKMACHINE:-"x86_64"}

if [ -z "$DIR" ]; then
    DIR=build
fi
usage(){
    echo  -e "
    Usage: source setup.sh [build_dir]
Examples:

- To create a new Yocto build directory:
  source $PROGNAME build

- To use an existing Yocto build directory:
  $ source $PROGNAME build
"
}

clean_up()
{
   unset MACHINE DISTRO OEROOT
}


# Reconfigure dash on debian-like systems
which aptitude > /dev/null 2>&1
ret=$?
if [ "$(readlink /bin/sh)" = "dash" -a "$ret" = "0" ]; then
  sudo aptitude install expect -y
  expect -c 'spawn sudo dpkg-reconfigure -freadline dash; send "n\n"; interact;'
elif [ "${0##*/}" = "dash" ]; then
  echo "dash as default shell is not supported"
  return
fi

if [ ! -e $1/conf/local.conf.sample ]; then
    build_dir_setup_enabled="true"
else
    build_dir_setup_enabled="false"
fi

# bootstrap OE
echo "Init OE"
OEROOT=$PWD/layers/openembedded-core

. $OEROOT/oe-init-build-env $PWD/$DIR > /dev/null

if [ "$build_dir_setup_enabled" = "true" ]; then
    mv conf/local.conf conf/local.conf.sample
    grep -v '^#\|^$' conf/local.conf.sample > conf/local.conf
    cat >> conf/local.conf <<EOF
DL_DIR ?= "\${BSPDIR}/downloads/"
SSTATE_DIR ?= "\${BSPDIR}/sstate-cache/"
EOF
    if ! grep -q "DISTRO ?=" conf/local.conf; then
        sed "1iDISTRO ?= '$DISTRO'" -i conf/local.conf
    fi
    sed -e "s,MACHINE ??=.*,MACHINE ??= '$MACHINE',g" \
        -e "s,DISTRO ?=.*,DISTRO ?= '$DISTRO',g" \
        -e "s,PACKAGE_CLASSES ?=.*,PACKAGE_CLASSES ?= '$PACKAGE_CLASSES',g" \
        -e "s,SDKMACHINE ??=.*,SDKMACHINE ??= '$SDKMACHINE',g" \
        -i conf/local.conf
    echo "PACKAGECONFIG:append:pn-qemu-system-native = \" sdl\"" conf/local.conf
fi
# core-image-sato, corea-image-sato-sdk
BITBAKEIMAGE="core-image-full-cmdline"

# add the missing layers
echo "Adding layers"
echo "BSPDIR := \"\${@os.path.abspath(os.path.dirname(d.getVar('FILE', True)) + '/../..')}\"" >> ${BUILD_DIR}/conf/bblayers.conf

echo "BBLAYERS += \"\${BSPDIR}/layers/meta-yocto/meta-poky \"" >> ${BUILD_DIR}/conf/bblayers.conf
echo "BBLAYERS += \"\${BSPDIR}/layers/meta-openembedded/meta-oe \"" >> ${BUILD_DIR}/conf/bblayers.conf
echo "BBLAYERS += \"\${BSPDIR}/layers/meta-openembedded/meta-python \"" >> ${BUILD_DIR}/conf/bblayers.conf
echo "BBLAYERS += \"\${BSPDIR}/layers/meta-openembedded/meta-multimedia \"" >> ${BUILD_DIR}/conf/bblayers.conf
echo "BBLAYERS += \"\${BSPDIR}/layers/meta-openembedded/meta-networking \"" >> ${BUILD_DIR}/conf/bblayers.conf
echo "BBLAYERS += \"\${BSPDIR}/layers/meta-riscv \"" >> ${BUILD_DIR}/conf/bblayers.conf

echo "To build an image run"
echo "---------------------------------------------------"
echo "bitbake core-image-full-cmdline"
echo "---------------------------------------------------"
echo ""
echo "Buildable machine info"
echo "---------------------------------------------------"
echo "* qemuriscv64: The 64-bit RISC-V machine"
echo "* qemuriscv32: The 32-bit RISC-V machine"
echo "* freedom-u540: The SiFive HiFive Unleashed board"
echo "* ae350-ax45mp: AE350 Platform"
echo "* beaglev-starlight-jh7100: Beta BeagleV Starlight board"
echo "* milkv-duo: Milk-V Duo platform"
echo "* nezha-allwinner-d1: Nezha Allwinner-d1 board"
echo "* orangepi-rv2-mainline: OrangePi RV2 with mainline Linux"
echo "* orangepi-rv2: OrangePi RV2"
echo "* star64: Star64 board"
echo "* visionfive: VisionFive board"
echo "* visionfive2: VisionFive 2 board"
echo "---------------------------------------------------"

# start build
#echo "Starting build"
#bitbake $BITBAKEIMAGE
