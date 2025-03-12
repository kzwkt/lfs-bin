# Deps
apt install -y  binutils bison gawk gcc grep gzip make patch texinfo xz-utils wget 

##------------------------------------------------------------------------------------------------------##

# envs
export LFS=/lfs
export LC_ALL=POSIX 
export LFS_TGT=$(uname -m)-lfs-linux-gnu 
export MAKEFLAGS=-j$(nproc)
export CONFIG_SITE=$LFS/usr/share/config.site 
export PATH=$LFS/tools/bin:$PATH 

umask 022

##------------------------------------------------------------------------------------------------------##

# rootfs layout
mkdir /lfs
mkdir -v $LFS/sources
mkdir $LFS/tools
chmod 755 $LFS
chmod -v a+wt $LFS/sources

mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}
for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done
case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac

##------------------------------------------------------------------------------------------------------##

#sources
cd  $LFS/sources
wget https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv 
wget --input-file=wget-list-sysv --continue --directory-prefix=$LFS/sources
wget https://www.linuxfromscratch.org/lfs/view/stable/md5sums
md5sum -c md5sums

getver() {
 trarball=$(grep -oP "[^\s]+$1-[0-9\.]+(\.tar\.xz|\.tar\.gz)" $LFS/sources/wget-list-sysv | sed 's|.*/||')
dirname="${tarball%.tar.*}"
}

extsrc() {
cd  $LFS/sources
getver $1
tar xf $tarball
cd $dirname
}

prepare_gcc() {
extsrc gcc 
mv ../$pk ../gcc && cd ../gcc
getver mpfr
tar xf ../$tarball  
mv -v $dirnae mpfr
getver gmp
tar -xf ../$tarball
mv -v $dirnae gmp
getver mpv
tar -xf ../$tarball
mv -v $dirnae mpc
}

# chown root:root  *
# for all fast download 
#wget https://repo.jing.rocks/lfs/lfs-packages/lfs-packages-12.3.tar

##------------------------------------------------------------------------------------------------------##
extsrc binutils
mkdir build
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

##------------------------------------------------------------------------------------------------------##

prepare_gcc

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
  
##------------------------------------------------------------------------------------------------------##
 # for libstdc++ 

extsrc gcc
mkdir -v build
cd       build
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
  make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la

extsrc m4
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install

##------------------------------------------------------------------------------------------------------##
extsrc ncurses
mkdir build
pushd build
  ../configure AWK=gawk
  make -C include
  make -C progs tic
popd
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk         
make
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h

##------------------------------------------------------------------------------------------------------##
extsrc  bash
./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
make
make DESTDIR=$LFS install
ln -sv bash $LFS/bin/sh
##------------------------------------------------------------------------------------------------------##

extsrc coreutils
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
make
make DESTDIR=$LFS install
mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
mkdir -pv $LFS/usr/share/man/man8
mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

##------------------------------------------------------------------------------------------------------##

extsrc diffutils
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make
make DESTDIR=$LFS install

##------------------------------------------------------------------------------------------------------##

extsrc file
mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd
./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)
make FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/libmagic.la

##------------------------------------------------------------------------------------------------------##

extsrc findutils
./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
            
make
make DESTDIR=$LFS install

##------------------------------------------------------------------------------------------------------##

extsrc gawk
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)        
make
make DESTDIR=$LFS install

##------------------------------------------------------------------------------------------------------##

extsrc grep
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
            
make
make DESTDIR=$LFS install

##------------------------------------------------------------------------------------------------------##
extsrc gzip
./configure --prefix=/usr --host=$LFS_TGT
make
make DESTDIR=$LFS install
##------------------------------------------------------------------------------------------------------##

extsrc make
./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
##------------------------------------------------------------------------------------------------------##

extsrc patch
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)            
make
make DESTDIR=$LFS install
##------------------------------------------------------------------------------------------------------##

extsrc sed
./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make
make DESTDIR=$LFS install
##------------------------------------------------------------------------------------------------------##
extsrc tar
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make
make DESTDIR=$LFS install
##------------------------------------------------------------------------------------------------------##

extsrc xz
./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.4
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/liblzma.la
##------------------------------------------------------------------------------------------------------##





make
make DESTDIR=$LFS install
##------------------------------------------------------------------------------------------------------##

extsrc binutils
sed '6031s/$add_dir//' -i ltmain.sh
mkdir -v build
cd       build
../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
make
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

##------------------------------------------------------------------------------------------------------##

  cd $LFS/sources/
  rm -rf gcc 
  prepare_gcc
  sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build
cd       build

../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++



make
make DESTDIR=$LFS install
ln -sv gcc $LFS/usr/bin/cc
##------------------------------------------------------------------------------------------------------##

chown  -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
chown -R root:root $LFS/lib64
mkdir -pv $LFS/{dev,proc,sys,run}
rm -rf $LFS/sources
tar -cJf $LFS.tar.xz -C $LFS .






    




            

  
 


    
             





 
 
