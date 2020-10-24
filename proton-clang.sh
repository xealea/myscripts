#
 # Script For Building Android arm64 Kernel
 #
 # Copyright (c) 2018-2019 Panchajanya1999 <rsk52959@gmail.com>
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #

#! /bin/sh

#Kernel building script

KERNEL_DIR=$PWD
ARG1=$1 #It is the devicename [generally codename]
ARG2=$2 #It is the make arguments, whether clean / dirty / def_regs [regenerates defconfig]
ARG3=$3 #Build should be pushed or not [PUSH / NOPUSH]
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
export ZIPNAME="NOELE" #Specifies the name of kernel
#We should fetch the latest clang build from android_googlesource
export CLANG_URL=https://github.com/kdrag0n/proton-clang

##----------------------------------------------------##

# START : Arguments Check
if [ $# -lt 3 ] # 3 arguments is must
  then
        echo -e "\nToo less Arguments..!! Provided - $# , Required - 3\nCheck README"
        return
  #Get outta
elif [ $# == 3 ]
  then
# START : Argument 1 [ARG1] Check
case "$ARG1" in
  "X00T" ) # Execute X00T function / scripts
      export DEVICE="ASUS Zenfone Max Pro M1"
      DEFCONFIG=X00T_defconfig
      CHATID="-1001161055876"
  ;;
  * ) echo -e "\nError..!! Unknown device. Please add device details to script and re-execute\n"
      return
  ;;
esac # END : Argument 1 [ARG2] Check

##----------------------------------------------------##

# START : Argument 2 [ARG1] Check
case "$ARG2" in
  "clean" ) # Execute Clean build function
      alias MAKE="make clean && make mrproper && rm -rf out"
  ;;
  "dirty" ) # Do not CLEAN
      
  ;;
  "def_reg" ) # Regenerate defconfig
      export ARCH=arm64
      export SUBARCH=arm64
      make O=out $DEFCONFIG
      mv out/.config $DEFCONFIG
      echo "Defconfig Regenerated"
      exit 1;
  ;;
  * ) echo -e "\nError..!! Unknown Build Command.\n"
      return
  ;;
esac # END : Argument 2 [ARG2] Check

##---------------------------------------------------##

#START : Argument 3 [ARG3] Check
case "$ARG3" in
  "PUSH" ) # Push build to TG Channel
      build_push=true
  ;;
  "NOPUSH" ) # Do not push
      build_push=false
  ;;
  * ) echo -e "\nError..!! Unknown command. Please refer README.\n"
      return
  ;;
esac # END : Argument 3 [ARG3] Check

##-----------------------------------------------------##

else
  echo -e "\nToo many Arguments..!! Provided - $# , Required - 3\nCheck README"
  return
#Get outta
fi

##------------------------------------------------------##

#Now Its time for other stuffs like cloning, exporting, etc

function clone {
	echo " "
	echo "★★Cloning Proton clang-10 sources"
	wget $CLANG_URL
	tar -I zstd -xvf proton_clang-latest.tar.zst
	rm -rf proton_clang-latest.tar.zst
	mv proton_clang-11.0.0-20200117 clang-llvm
	echo "★★Clang Done, Now Its time for AnyKernel .."
	git clone --depth 1 --no-single-branch https://github.com/VISakura/AnyKernel3 -b master-x00td $ARG1
	echo "★★Cloning libufdt"
	git clone https://android.googlesource.com/platform/system/libufdt $KERNEL_DIR/scripts/ufdt/libufdt
	echo "★★Cloning Kinda Done..!!!"
}

##------------------------------------------------------##

function exports {
	export KBUILD_BUILD_USER="Hazukashio"
	export KBUILD_BUILD_HOST="VISakura"
	export ARCH=arm64
	export SUBARCH=arm64
	export KBUILD_COMPILER_STRING=$($KERNEL_DIR/clang-llvm/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
	LD_LIBRARY_PATH=$KERNEL_DIR/clang-llvm/lib:$KERNEL_DIR/clang-llvm/lib64:$LD_LIBRARY_PATH
	export LD_LIBRARY_PATH
	PATH=$KERNEL_DIR/clang-llvm/bin/:$PATH
	export PATH
	export BOT_MSG_URL="https://api.telegram.org/bot$token/sendMessage"
	export BOT_BUILD_URL="https://api.telegram.org/bot$token/sendDocument"
	env_exports
	export PROCS=$(nproc --all)
	export BUILD_DTBO=0 #do not build dtbo
}

##---------------------------------------------------------##

function tg_post_msg {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##----------------------------------------------------------------##

function tg_post_build {
	curl --progress-bar -F document=@"$1" $BOT_BUILD_URL \
	-F chat_id="$2"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"  
}

##----------------------------------------------------------##

function env_exports {
	export CROSS_COMPILE=$KERNEL_DIR/clang-llvm/aarch64-linux-android-4.9/bin/aarch64-linux-gnu-
	export CROSS_COMPILE_ARM32=$KERNEL_DIR/clang-llvm/arm-linux-androideabi-4.9/bin/arm-linux-gnueabi-
	export CC=$KERNEL_DIR/clang-llvm/bin/clang
	export LD=$KERNEL_DIR/clang-llvm/bin/ld.lld
	export AR=$KERNEL_DIR/clang-llvm/bin/llvm-ar
	export NM=$KERNEL_DIR/clang-llvm/bin/llvm-nm
	export OBJCOPY=$KERNEL_DIR/clang-llvm/bin/llvm-objcopy
	export OBJDUMP=$KERNEL_DIR/clang-llvm/bin/llvm-objdump
	export STRIP=$KERNEL_DIR/clang-llvm/bin/llvm-strip
}

##----------------------------------------------------------##

function build_kernel {
	if [ "$build_push" = true ]; then
		tg_post_msg "<b>$CIRCLE_BUILD_NUM CI Build Triggered</b>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$DEVICE</code>%0A<b>Pipeline Host : </b><code>CircleCI</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0a<b>Branch : </b><code>$CIRCLE_BRANCH</code>%0A<b>Status : </b>#Nightly" "$CHATID"
	fi
	make O=out $DEFCONFIG
	BUILD_START=$(date +"%s")
	make -j$PROCS O=out \
		CROSS_COMPILE=$CROSS_COMPILE \
		CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
		CC=$CC \
		LD=$LD \
		AR=$AR \
		NM=$NM \
		OBJCOPY=$OBJCOPY \
		OBJDUMP=$OBJDUMP \
		STRIP=$STRIP \
		CLANG_TRIPLE=aarch64-linux-gnu- 2>&1 | tee error.log
	if [ $BUILD_DTBO = 1 ] 
	 then
		make O=out dtbo.img
	fi
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
	check_img
}

##-------------------------------------------------------------##

function check_img {
	if [ -f $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ] 
	    then
		gen_zip
	else
		tg_post_build "error.log" "$CHATID" "<b>Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</b>"
	fi
}

##--------------------------------------------------------------##

function gen_zip {
	mv $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb AnyKernel3/Image.gz-dtb
	if [ $BUILD_DTBO = 1 ] 
	 then
		mv $KERNEL_DIR/out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img
	fi
	cd AnyKernel3
	zip -r9 $ZIPNAME-$ARG1-$DATE * -x .git README.md
	MD5CHECK=$(md5sum $ZIPNAME-$ARG1-$DATE.zip | cut -d' ' -f1)
	tg_post_build $ZIPNAME* "$CHATID" "Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s) | MD5 Checksum : <code>$MD5CHECK</code>"
	cd ..
}

clone
exports
build_kernel

##----------------*****-----------------------------##
