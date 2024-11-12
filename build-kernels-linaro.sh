cd ../../../..
export ANDROID_ROOT=$(pwd)
export kernel_top=$ANDROID_ROOT/kernel/sony/msm-4.9
export kernel_tmp=$ANDROID_ROOT/out/kernel-4.9-linaro

export USE_CCACHE=1
#export CCACHE_DIR="$HOME/.ccache"
export CCACHE_COMPRESS=1

# Cross Compiler
export CROSS_COMPILE=$HOME/downloads/linaro/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
# Mkdtimg tool
export MKDTIMG=$ANDROID_ROOT/out/host/linux-x86/bin/mkdtimg

LOIRE="suzu"
TONE="dora kagura keyaki"
YOSHINO="lilac maple poplar"
NILE="discovery"
GANGES="kirin mermaid"
TAMA="akari apollo akatsuki"
KUMANO="griffin"

PLATFORMS="loire tone yoshino nile ganges tama kumano"

# Override:
#TAMA="apollo"
#PLATFORMS="tama"

cd $kernel_top/kernel

echo "================================================="
echo "Your Environment:"
echo "ANDROID_ROOT: ${ANDROID_ROOT}"
echo "kernel_top  : ${kernel_top}"
echo "kernel_tmp  : ${kernel_tmp}"

for platform in $PLATFORMS; do \

case $platform in
loire)
    DEVICE=$LOIRE;
    DTBO="false";;
tone)
    DEVICE=$TONE;
    DTBO="false";;
yoshino)
    DEVICE=$YOSHINO;
    DTBO="false";;
nile)
    DEVICE=$NILE;
    DTBO="false";;
ganges)
    DEVICE=$GANGES;
    DTBO="false";;
tama)
    DEVICE=$TAMA;
    DTBO="true";;
kumano)
    DEVICE=$KUMANO;
    DTBO="true";;
esac

for device in $DEVICE; do \
    device_out=$kernel_tmp/${device}-gcc
    ret=$(mkdir -p $device_out 2>&1);
    if [ ! -d $device_out ] ; then
        echo "Check your environment";
        echo "ERROR: ${ret}";
        exit 1;
    fi

    # Build mkdtimg if necessary
    if [ $DTBO != "true" ]; then
        if [ ! -f $MKDTIMG ]; then
            echo "mkdtimg: File not found!"
            echo "Building mkdtimg"
            export ALLOW_MISSING_DEPENDENCIES=true
            make mkdtimg
        fi
    fi

    # Build command
    build="make O=$device_out ARCH=arm64 -j$(nproc)"
    build_log="$kernel_tmp/build_log_${platform}_${device}_gcc"

    echo "================================================="
    echo "Platform -> ${platform} :: Device -> $device"

    echo "Cleaning ..."
    ret=$($build clean >$build_log 2>&1);
    case "$ret" in
        *"error"*|*"ERROR"*) echo "ERROR: $ret"; exit 1;;
    esac

    echo "Building defconfig"
    ret=$(${build} aosp_$platform"_"$device\_defconfig >>$build_log 2>&1);
    case "$ret" in
        *"error"*|*"ERROR"*) echo "ERROR: $ret"; exit 1;;
    esac

    #ret=$($build modules >>$build_log 2>&1);
    #case "$ret" in
    #    *"error"*|*"ERROR"*) echo "ERROR: $ret"; exit 1;;
    #esac

    echo "The build may take up to 10 minutes. Please be patient ..."
    echo "Building new kernel image ..."
    echo "Logging to $build_log"
    ret=$($build CROSS_COMPILE="/usr/bin/ccache $CROSS_COMPILE" >>$build_log 2>&1;)
    case "$ret" in
        *"error"*|*"ERROR"*) echo "ERROR: $ret"; exit 1;;
    esac

    # Copy prebuilt kernel
    CP_BLOB="cp $device_out/arch/arm64/boot/Image.gz-dtb $kernel_top/common-kernel/kernel-dtb"
    echo "Copying new kernel image ..."
    ret=$(${CP_BLOB}-${device} 2>&1);
    case "$ret" in
        *"error"*|*"ERROR"*) echo "ERROR: $ret"; exit 1;;
    esac

    if [ $DTBO = "true" ]; then
        echo "Creating dtbo-${device}.img ..."
        $MKDTIMG create $kernel_top/common-kernel/dtbo-$device\.img `find $device_out/arch/arm64/boot/dts -name "*.dtbo"`
    fi
done
done

echo "================================================="
echo "Clean up environment"
unset ANDROID_ROOT
unset KERNEL_CFG
unset USE_CCACHE
unset CCACHE_COMPRESS
unset CROSS_COMPILE
unset MKDTIMG
echo "Done!"
