# BUILD
~~~~sh
source owasys-setup.sh -b build_owa5x
bitbake cetus-image
~~~~

After that place the *.uuu script in the *build_owa5x/tmp/deploy/images/owa5x* folder and execute it to flash the owa5X unit:

`$sudo uuu owa_uboot_nand_rootfs_YOCTO_2.0.0.uuu`