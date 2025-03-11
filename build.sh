apt install -y  binutils bison gawk gcc grep gzip make patch texinfo xz-utils wget 
export LFS=/lfs
umask 022
mkdir /lfs
chmod 755 $LFS
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources
cd  $LFS/sources
wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv 
wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources
wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums
md5sum -c md5sums

# chown root:root  *

# for all fast download 
#wget https://repo.jing.rocks/lfs/lfs-packages/lfs-packages-12.3.tar


# rootfs layout
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac


LC_ALL=POSIX 
LFS_TGT=$(uname -m)-lfs-linux-gnu 
export MAKEFLAGS=-j$(nproc)
CONFIG_SITE=$LFS/usr/share/config.site 
PATH=$LFS/tools/bin:$PATH 
mkdir $LFS/tools

tar xf binutils-2.44.tar.xz 
cd binutils-2.44/
cd build
../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu


make
make install


cd $LFS/sources
tar xf gcc-14.2.0.tar.xz
mv -v  gcc-14.2.0 gcc
cd gcc
tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc


 sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64

        
mkdir -v build
cd       build


../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.41 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++

 make
 make install
 cd ..
 cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h

  

  
 


    
             





 
 
