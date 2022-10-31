LICENSE = "The-Qt-Company-Commercial"
LIC_FILES_CHKSUM = " \
    file://src/qmlcompilerplus/cppcodegen_p.h;endline=27;md5=6a1dccd03d0d5864357e72b67def8ff2 \
"

inherit qt6-cmake

include recipes-qt/qt6/qt6-git.inc
include recipes-qt/qt6/qt6.inc

python() {
    if d.getVar('QT_EDITION') != 'commercial':
        raise bb.parse.SkipRecipe('Available only with Commercial Qt')
}

QT_GIT = "git://codereview.qt-project.org"
QT_GIT_PROTOCOL = "ssh"
QT_MODULE = "tqtc-qmlcompilerplus"

DEPENDS += "qtbase qtdeclarative qtdeclarative-native"

PTEST_ENABLED = "0"

BBCLASSEXTEND = "native nativesdk"
