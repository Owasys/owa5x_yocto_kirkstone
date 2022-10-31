LICENSE = "GFDL-1.3 & ( GPL-3.0-only & The-Qt-Company-GPL-Exception-1.0 ) & ( GPL-2.0-or-later | LGPL-3.0-only ) | The-Qt-Company-Commercial"
LIC_FILES_CHKSUM = " \
    file://LICENSE.GPL3-EXCEPT;md5=763d8c535a234d9a3fb682c7ecb6c073 \
    file://LICENSE.GPLv2;md5=c96076271561b0e3785dad260634eaa8 \
    file://LICENSE.GPLv3;md5=88e2b9117e6be406b5ed6ee4ca99a705 \
    file://LICENSE.LGPL3;md5=e6a600fd5e1d9cbde2d983680233ad02 \
"

inherit qt6-cmake

include recipes-qt/qt6/qt6-git.inc
include recipes-qt/qt6/qt6.inc

DEPENDS += "qtbase"

BBCLASSEXTEND = "native nativesdk"
