#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
TOOLCHAIN_DIR=/home/lennehberg/projects/embedded/arm_compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu
WRITER_DIR=/home/lennehberg/projects/embedded/assignment-1-lennehberg/finder-app

if [ $# -lt 1 ]; then
  echo "Using default directory ${OUTDIR} for output"
else
  OUTDIR=$1
  echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
  echo $OUTDIR
  pwd

  #Clone only if the repository does not exist.
  echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
  git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
  cd linux-stable
  echo "Checking out version ${KERNEL_VERSION}"
  git checkout ${KERNEL_VERSION}

  # build kernel
  # perform a deep clean of the build tree
  make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
  # generate a defconfig
  make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
  # build vmlinux target
  make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
  # build modules
  # make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
  # build devicetree
  make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp -fr ${OUTDIR}/linux-stable/arch/${ARCH}/boot/*Image* ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]; then
  echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
  sudo rm -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p rootfs
cd rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
  git clone git://busybox.net/busybox.git
  cd busybox
  git checkout ${BUSYBOX_VERSION}
  #Configure busybox
  # clean previous artifacts
  make distclean
  # configure defconfig
  make defconfig
else
  cd busybox
fi

# Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX="${OUTDIR}/rootfs/" install

# Add library dependencies to rootfs
echo "Library dependencies"
cd ${OUTDIR}/rootfs/
# DEBUG PRINTS
echo "${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter""
# ${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"

# program interpreter dependencies
#INT_DEPENDS=$(${CROSS_COMPILE}readelf -a /bin/busybox | grep "program interpreter" | awk -F '[]:[]' '{print $3}')
#for DEP_FILE in $INT_DEPENDS; do
# echo "copying ${DEP_FILE} from ${TOOLCHAIN_DIR} to rootfs"
# cp -r ${DEP_FILE} ${OUTDIR}/rootfs/lib/
#done

cp -r ${TOOLCHAIN_DIR}/libc/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/

# Shared library dependencies
LIB_DEPENDS=$(${CROSS_COMPILE}readelf -a /bin/busybox | grep "Shared library" | awk -F '[]:[]' '{print $3}')
for DEP_FILE in $LIB_DEPENDS; do
  echo "${DEP_FILE}"
  # echo "copying ${DEP_FILE} from ${TOOLCHAIN_DIR} to rootfs"
  cp -r ${TOOLCHAIN_DIR}/libc/lib64/${DEP_FILE} ${OUTDIR}/rootfs/lib64/
done
cp -r ${TOOLCHAIN_DIR}/libc/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/libm.so.6
echo "Making device nodes..."
# Make device nodes
cd "${OUTDIR}/rootfs/"
# make null device node
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 1 5
echo "cleaning writer artifacts..."
# Clean and build the writer utility
cd "${WRITER_DIR}"
if [ -e "writer.o" ]; then
  make clean
fi
echo "building writer... "
make CROSS_COMPILE=aarch64-none-linux-gnu-

echo "copying writer to rootfs/home..."
# Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer "${OUTDIR}"/rootfs/home/
cp finder.sh "${OUTDIR}"/rootfs/home/
cp finder-test.sh "${OUTDIR}"/rootfs/home/
cp autorun-qemu.sh "${OUTDIR}"/rootfs/home/
cp -r ../conf "${OUTDIR}"/rootfs/home/

echo "Chowning root directory and making initramfs.cpio"
# TODO: Chown the root directory
cd "${OUTDIR}"/rootfs
find . | cpio -H newc -ov --owner root:root >"${OUTDIR}"/initramfs.cpio
# TODO: Create initramfs.cpio.gz
cd "${OUTDIR}"
gzip -f initramfs.cpio
