#!/usr/bin/bash
# Written by: cyberknight777
# YAKB v1.0
# Copyright (c) 2022-2023 Cyber Knight <cyberknight755@gmail.com>
#
#			GNU GENERAL PUBLIC LICENSE
#			 Version 3, 29 June 2007
#
# Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.

# Some Placeholders: [!] [*] [✓] [✗]

# A function to send message(s) via Telegram's BOT api.
tg() {
    curl -sX POST https://api.telegram.org/bot"${TG_TOKEN}"/sendMessage \
        -d chat_id="-1001754559150" \
        -d parse_mode=html \
        -d disable_web_page_preview=true \
        -d text="$1"
}

tgs() {
    curl -fsSL -X POST -F document=@"$1" https://api.telegram.org/bot"${TG_TOKEN}"/sendDocument \
        -F "chat_id=-1001754559150" \
        -F "parse_mode=Markdown" \
        -F "caption=$2"
}

# Default defconfig to use for builds.
CONFIG="merlin_defconfig"

# Device and Codename
CODENAME=merlin
DEVICE=Redmi Note 9

# Default directory where kernel is located in.
KDIR=$(pwd)

# User and Host name
export KBUILD_BUILD_USER=ItsProf
export KBUILD_BUILD_HOST=github.com

# Number of jobs to run.
PROCS=$(nproc --all)

Ai1() {

    echo -e "\n\e[1;93m[*] Cloning Toolchain! \e[0m"
    git clone https://github.com/kenhv/gcc-arm64 --depth=1 -b master "${KDIR}"/gcc64
    git clone https://github.com/kenhv/gcc-arm --depth=1 -b master "${KDIR}"/gcc32
    git clone https://github.com/ImLonely13/AnyKernel3 -b merlin "${KDIR}"/anykernel3
    echo -e "\n\e[1;32m[✓] Cloning Done! \e[0m"

    LLD_VER=$("${KDIR}"/gcc64/bin/aarch64-elf-ld.lld -v | head -n1 | sed 's/(compatible with [^)]*)//' |
            head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
    KBUILD_COMPILER_STRING=$("${KDIR}"/gcc64/bin/aarch64-elf-gcc --version | head -n 1)
    export KBUILD_COMPILER_STRING
    export PATH="${KDIR}"/gcc32/bin:"${KDIR}"/gcc64/bin:/usr/bin/:${PATH}
    MAKE+=(
        CC=aarch64-elf-gcc
        LD=aarch64-elf-ld.lld
        CROSS_COMPILE=aarch64-elf-
        CROSS_COMPILE_ARM32=arm-eabi-
        AR=llvm-ar
        NM=llvm-nm
        OBJDUMP=llvm-objdump
        OBJCOPY=llvm-objcopy
        OBJSIZE=llvm-objsize
        STRIP=llvm-strip
        HOSTAR=llvm-ar
        HOSTCC=gcc
        HOSTCXX=aarch64-elf-g++
    )

    export KBUILD_BUILD_VERSION=$GITHUB_RUN_NUMBER
    export KBUILD_BUILD_HOST=$HOST
    export KBUILD_BUILD_USER=$BUILDER
    zipn=ProjectRandom-kernel-${CODENAME}


tg "
<b>Date</b>: <code>$(date)</code>
<b>Device</b>: <code>${DEVICE}</code>
<b>Kernel Version</b>: <code>$(make kernelversion 2>/dev/null)</code>
<b>Zip Name</b>: <code>${zipn}</code>
<b>Compiler</b>: <code>${KBUILD_COMPILER_STRING}</code>
<b>Linker</b>: <code>${LLD_VER}</code>
"

    echo -e "\n\e[1;93m[*] Building Kernel! \e[0m"
    BUILD_START=$(date +"%s")
     make -j$(nproc) O=out ARCH=arm64 ${CONFIG}
     make -j$(nproc) ARCH=arm64 O=out \
     "${MAKE[@]}" 2>&1 | tee log.txt
    BUILD_END=$(date +"%s")
    DIFF=$((BUILD_END - BUILD_START))
    if ! [ -a "${KDIR}"/out/arch/arm64/boot/Image.gz ]; then
            tgs "log.txt" "❌*Build failed* after: $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
            exit 1
    fi

        tg "<b>Building zip!</b>"
    echo -e "\n\e[1;93m[*] Building zip! \e[0m"
    mv "${KDIR}"/out/arch/arm64/boot/Image.gz "${KDIR}"/anykernel3
    cd "${KDIR}"/anykernel3 || exit 1
    zip -r9 "$zipn".zip . -x ".git*" -x "README.md" -x "LICENSE" -x "*.zip"
    echo -e "\n\e[1;32m[✓] Built zip! \e[0m"
        tgs "${zipn}.zip" "✅*Build success* after: $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
}
Ai1
