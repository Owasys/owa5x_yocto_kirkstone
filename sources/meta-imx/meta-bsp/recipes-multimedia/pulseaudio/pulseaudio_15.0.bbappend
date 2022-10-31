FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

IMX_PATCHES = " file://0001-Fix-pulseaudio-mutex-issue-when-do-pause-in-gstreame.patch \
                file://0001-bluetooth-Only-remove-cards-belonging-to-the-device.patch \
"
SRC_URI:append:mx6-nxp-bsp = "${IMX_PATCHES}"
SRC_URI:append:mx7-nxp-bsp = "${IMX_PATCHES}"
SRC_URI:append:mx8-nxp-bsp = "${IMX_PATCHES}"

# Enable allow-autospawn-for-root as default
PACKAGECONFIG:append = " autospawn-for-root"

# This default setting should be added on all i.MX SoC,
# For now, the setting for mx6(including mx6ul & mx6sll)/mx7 has been upstreamed
SRC_URI:append:mx8-nxp-bsp = " file://daemon.conf file://default.pa"

PACKAGE_ARCH:mx8-nxp-bsp = "${MACHINE_SOCARCH}"
