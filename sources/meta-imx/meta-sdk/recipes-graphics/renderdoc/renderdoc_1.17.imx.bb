require renderdoc-1.13.inc

SRCREV = "22d4dc45749c8d1ddbb9e869ec5db142bfe1d7bd"
SRC_URI += " \
    file://0001-Continue-running-when-EnumerateDeviceExtensionProper.patch \
    file://0002-Pass-memory-checking-when-replaying-captures.patch \
    file://0003-Use-specific-integer-format-to-generate-a-dummy-mult.patch \
    file://0004-Add-basic-support-for-Wayland-replay-on-renderdoccmd.patch \
    file://0005-Add-window-functionalities-for-Wayland-replay-suppor.patch \
    file://0006-Fix-compilation-for-iMX.patch \
    file://0001-renderdoc-CMakeLists.txt-Set-TARGET-DESTINATION-usin.patch \
"

REQUIRED_DISTRO_FEATURES:remove = "opengl"

PACKAGECONFIG ?= " \
    egl \
    ${@bb.utils.filter('DISTRO_FEATURES', 'vulkan wayland', d)} \
"

PACKAGECONFIG[egl]     = "-DENABLE_EGL=ON,-DENABLE_EGL=OFF"
PACKAGECONFIG[gl]      = "-DENABLE_GL=ON,-DENABLE_GL=OFF,virtual/libgl"
PACKAGECONFIG[gles]    = "-DENABLE_GLES=ON,-DENABLE_GLES=OFF"
PACKAGECONFIG[vulkan]  = "-DENABLE_VULKAN=ON,-DENABLE_VULKAN=OFF"
PACKAGECONFIG[wayland] = "-DENABLE_WAYLAND=ON,-DENABLE_WAYLAND=OFF,wayland"
PACKAGECONFIG[xcb]     = "-DENABLE_XCB=ON,-DENABLE_XCB=OFF"
PACKAGECONFIG[xlib]    = "-DENABLE_XLIB=ON,-DENABLE_XLIB=OFF"

do_compile:prepend () {
    if [ "${base_libdir}" != "lib" ]; then
        export LIB_SUFFIX="64"
    fi
}
