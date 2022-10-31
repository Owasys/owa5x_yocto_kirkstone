SUMMARY = "NNStreamer, Stream Pipeline Paradigm for Neural Network Applications"
DESCRIPTION = "NNStreamer is a GStreamer plugin allowing to construct neural network applications with stream pipeline paradigm."
SECTION = "AI"
LICENSE = "LGPL-2.0-or-later"
LIC_FILES_CHKSUM = "\
    file://LICENSE;md5=c25e5c1949624d71896127788f1ba590 \
    file://debian/copyright;md5=0462ef8fa89a1f53f2e65e74940519ef \
"

DEPENDS = "\
	bison-native \
	flex-native \
	orc-native \
	glib-2.0 \
	gstreamer1.0 \
	gstreamer1.0-plugins-base \
	gtest \
	libpng \
"

SRCREV = "354a149d8d174ad40f758bb19c6a6718f95d3103"
SRC_URI = "\
    git://github.com/nnstreamer/nnstreamer.git;branch=main;protocol=https \
    file://0001-decoder-bounding_box-Fix-ssd-box-decoding-without-po.patch \
"

S = "${WORKDIR}/git"

inherit meson pkgconfig

PACKAGECONFIG ??= "protobuf python3 tensorflow-lite "

PACKAGECONFIG[flatbuf] = "\
	-Dflatbuf-support=enabled, \
	-Dflatbuf-support=disabled, \
	flatbuffers-native flatbuffers, \
	,,\
"

PACKAGECONFIG[grpc] = "\
	-Dgrpc-support=enabled, \
	-Dgrpc-support=disabled, \
	grpc-native grpc, \
	,,\
"

PACKAGECONFIG[protobuf] = "\
	-Dprotobuf-support=enabled, \
	-Dprotobuf-support=disabled, \
	protobuf-native protobuf, \
	,,\
"

PACKAGECONFIG[python3] = "\
	-Dpython3-support=enabled, \
	-Dpython3-support=disabled, \
	python3 python3-numpy-native, \
	,,\
"

PACKAGECONFIG[tensorflow-lite] = "\
	-Dtflite2-support=enabled, \
	-Dtflite2-support=disabled, \
	tensorflow-lite flatbuffers, \
	,,\
"

EXTRA_OEMESON += "\
	-Denable-test=true \
	-Dinstall-test=true \
"

do_install:append() {
    rm -f ${D}/${bindir}/unittest-nnstreamer/tests/test_models/models/tvm_add_one.so_
}

PACKAGES =+ "\
	${PN}-unittest \
	${@bb.utils.contains('PACKAGECONFIG', 'armnn','${PN}-armnn', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'flatbuf','${PN}-flatbuf', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'flatbuf grpc','${PN}-grpc-flatbuf', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'grpc','${PN}-grpc', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'protobuf','${PN}-protobuf', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'protobuf grpc','${PN}-grpc-protobuf', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'python3','${PN}-python3', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'tensorflow-lite','${PN}-tensorflow-lite', '', d)} \
"

RDEPENDS:${PN} = "\
	gstreamer1.0-plugins-base \
"

RDEPENDS:${PN}-unittest = "gstreamer1.0-plugins-good nnstreamer ssat \
	${@bb.utils.contains('PACKAGECONFIG', 'armnn','${PN}-armnn', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'flatbuf','${PN}-flatbuf', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'flatbuf grpc','${PN}-grpc-flatbuf', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'grpc','${PN}-grpc', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'protobuf','${PN}-protobuf', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'protobuf grpc','${PN}-grpc-protobuf', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'python3','${PN}-python3', '', d)} \
	${@bb.utils.contains('PACKAGECONFIG', 'tensorflow-lite','${PN}-tensorflow-lite', '', d)} \
"

FILES:${PN} += "\
	${libdir}/*.so \
	${libdir}/gstreamer-1.0/*.so \
	${libdir}/nnstreamer/decoders/* \
	${sysconfdir}/nnstreamer.ini \
"

FILES:${PN}-armnn = "\
	${libdir}/nnstreamer/filters/libnnstreamer_filter_armnn.so \
"

FILES:${PN}-dev = "\
	${includedir}/nnstreamer/* \
	${libdir}/*.a \
	${libdir}/pkgconfig/*.pc \
"

FILES:${PN}-flatbuf = "\
	${libdir}/nnstreamer/converters/libnnstreamer_converter_flatbuf.so \
	${libdir}/nnstreamer/converters/libnnstreamer_converter_flexbuf.so \
	${libdir}/nnstreamer/decoders/libnnstreamer_decoder_flatbuf.so \
	${libdir}/nnstreamer/decoders/libnnstreamer_decoder_flexbuf.so \
"

FILES:${PN}-grpc = "\
	${libdir}/gstreamer-1.0/libnnstreamer-grpc.so \
"

FILES:${PN}-grpc-flatbuf = "\
	${libdir}/libnnstreamer_grpc_flatbuf.so \
"

FILES:${PN}-grpc-protobuf = "\
	${libdir}/libnnstreamer_grpc_protobuf.so \
"

FILES:${PN}-protobuf = "\
	${libdir}/nnstreamer/converters/libnnstreamer_converter_protobuf.so \
	${libdir}/nnstreamer/decoders/libnnstreamer_decoder_protobuf.so \
	${libdir}/libnnstreamer_protobuf.so \
"

FILES:${PN}-python3 = "\
	${libdir}/nnstreamer/converters/libnnstreamer_converter_python3.so \
	${libdir}/nnstreamer/decoders/libnnstreamer_decoder_python3.so \
	${libdir}/nnstreamer/filters/libnnstreamer_filter_python3.so \
	${libdir}/nnstreamer/extra/nnstreamer_python3.so \
"

FILES:${PN}-tensorflow-lite = "\
	${libdir}/nnstreamer/filters/libnnstreamer_filter_tensorflow2-lite.so \
"

FILES:${PN}-unittest = "\
	${bindir}/unittest-nnstreamer/* \
	${libdir}/libnnstreamer_unittest_util.so \
	${libdir}/libcppfilter_test.so \
	${libdir}/nnstreamer/customfilters/* \
	${libdir}/nnstreamer/unittest/* \
"

INSANE_SKIP:${PN} += "dev-so"

#
# Fixes: 076a78ea [TVM/test] Add models for more architectures
#
do_install:append() {
    bash -c "shopt -s extglob;
    rm -f ${D}/${bindir}/unittest-nnstreamer/tests/test_models/models/tvm_add_one_!(${HOST_ARCH}).so_;
    shopt -u extglob;"
}
