## SET-UP REPO
Owasys has developed its yocto layer from the yocto kirkstone distribution provided by NXP.

In order to use Yocto in any PC some dependencies must be installed. 
You can find them in [this](https://www.nxp.com/docs/en/user-guide/IMX_YOCTO_PROJECT_USERS_GUIDE.pdf) document provided by NXP in chapter 3 as a reference or install them yourself with this command:

`sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat cpio pylint3 xterm rsync curl zstd pzstd xz-utils python python3 python3-pip python3-pexpect python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev debianutils iputils-ping lz4c lz4 libssl-dev`

Once everything's installed you can follow on with the steps below.

To setup a building yocto environment for the owa5X family: 

1. Setup owa5X Yocto repo: 

```
git clone --recursive https://github.com/Owasys/owa5x_yocto_kirkstone.git
```

# BUILD CETUS IMAGE
~~~~sh
source owasys-setup.sh -b build_owa5x
bitbake cetus-image-nand
~~~~

After that place the *.uuu script in the *build_owa5x/tmp/deploy/images/owa5x* folder and execute it to flash the owa5X unit:

`$sudo uuu owa_uboot_nand_rootfs_YOCTO_2.0.0.uuu`