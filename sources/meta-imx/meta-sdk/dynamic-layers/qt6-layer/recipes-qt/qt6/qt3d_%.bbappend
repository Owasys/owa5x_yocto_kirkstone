PACKAGECONFIG += "examples"

do_install:append() {
if ls ${D}${libdir}/pkgconfig/Qt6*.pc >/dev/null 2>&1; then
    sed -i 's,-L${STAGING_DIR_HOST}/usr/lib,,' ${D}${libdir}/pkgconfig/Qt6*.pc
fi
}
