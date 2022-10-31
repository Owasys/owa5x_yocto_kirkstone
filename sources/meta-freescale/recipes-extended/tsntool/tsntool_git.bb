SUMMARY = "Configure TSN funtionalitie"
DESCRIPTION = "A tool to configure TSN funtionalities in user space"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=ef58f855337069acd375717db0dbbb6d"

DEPENDS = "cjson libnl readline"

inherit pkgconfig

SRC_URI = "git://source.codeaurora.org/external/qoriq/qoriq-components/tsntool;protocol=https;nobranch=1"
SRCREV = "b767c260b851aac94828ed26c6a9a327e4e98334"

S = "${WORKDIR}/git"

do_configure[depends] += "virtual/kernel:do_shared_workdir"

do_compile:prepend() {
        mkdir -p ${S}/include/linux
        cp -r ${STAGING_KERNEL_DIR}/include/uapi/linux/tsn.h ${S}/include/linux
}     
do_install() {
    install -d ${D}${bindir} ${D}${libdir}
    install -m 0755 ${S}/tsntool ${D}${bindir}
    install -m 0755 ${S}/libtsn.so ${D}${libdir}
}

PACKAGES = "${PN}-dbg ${PN}"
FILES:${PN} = "${libdir}/libtsn.so ${bindir}/*"
INSANE_SKIP:${PN} += "file-rdeps rpaths dev-so"
COMPATIBLE_MACHINE = "(qoriq)"
PARALLEL_MAKE = ""
