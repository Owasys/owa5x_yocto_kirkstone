FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " \
    file://0001-Prefer-to-create-GLES2-context-for-glamor-EGL.patch \
    file://0003-glamor-Fix-fbo-pixmap-format-with-GL_BGRA_EXT.patch \
"

OPENGL_PKGCONFIGS:remove:imxgpu = "glx"
