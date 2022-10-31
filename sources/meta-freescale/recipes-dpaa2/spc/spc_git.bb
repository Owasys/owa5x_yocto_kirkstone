SUMMARY = "Soft Parser Configuration tool"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;md5=163b09a1c249a6ff2b28da1ceca2e0a8"

DEPENDS = "libxml2 fmlib tclap"

SRC_URI = "git://source.codeaurora.org/external/qoriq/qoriq-components/spc;nobranch=1"
SRCREV = "398138687a3d3d6ef174501221711de74ff7bc40"

S = "${WORKDIR}/git"

EXTRA_OEMAKE = 'FMD_USPACE_HEADER_PATH="${STAGING_INCDIR}/fmd" \
    FMD_USPACE_LIB_PATH="${STAGING_LIBDIR}" LIBXML2_HEADER_PATH="${STAGING_INCDIR}/libxml2" \
    TCLAP_HEADER_PATH="${STAGING_INCDIR}" '
EXTRA_OEMAKE:class-native = 'FMCHOSTMODE=1 FMD_USPACE_HEADER_PATH="${STAGING_INCDIR}/fmd" \
    FMD_USPACE_LIB_PATH="${STAGING_LIBDIR}" LIBXML2_HEADER_PATH="${STAGING_INCDIR}/libxml2" \
    TCLAP_HEADER_PATH="${STAGING_INCDIR}" '

EXTRA_OEMAKE_PLATFORM ?= ""

do_compile () {
    oe_runmake  -C source
}

do_install () {
    install -d ${D}/${bindir}
    install -m 755 ${S}/source/spc ${D}/${bindir}

    install -d ${D}${sysconfdir}/spc/config
    install -m 644 ${S}${sysconfdir}/spc/config/* ${D}${sysconfdir}/spc/config

}

PARALLEL_MAKE = ""

PACKAGE_ARCH = "${MACHINE_SOCARCH}"

COMPATIBLE_MACHINE = "(qoriq-arm64)"
