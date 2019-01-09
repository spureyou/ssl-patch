#!/bin/sh
export WORKDIRECTORY=$PWD
export ARCH=$(uname -m)
if command -v git > /dev/null 2>&1; then
  echo "Checking git: OK"
else
  echo "Checking git: FAILED, please install git"
  exit 1
fi

if command -v cmake > /dev/null 2>&1; then
  echo "Checking cmake: OK"
else
  echo "Checking cmake: FAILED, please install cmake"
  exit 1
fi

if command -v curl > /dev/null 2>&1; then
  echo "Checking curl: OK"
else
  echo "Checking curl: FAILED, please install curl"
  exit 1
fi

if [ -d $WORKDIRECTORY/go ]; then
export PATH=$WORKDIRECTORY/go/bin:$PATH
export GOROOT=$WORKDIRECTORY/go
else
if [ -z $GOROOT ];then
if [ "$ARCH" = "x86_64" ]; then
GOURL=`curl -so- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | head -n 1`
fi
if [ "$ARCH" = "i386" ]; then
GOURL=`curl -so- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-386\.tar\.gz' | head -n 1`
fi
if [ "$ARCH" = "armv6l" ]; then
GOURL=`curl -so- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-armv6l\.tar\.gz' | head -n 1`
fi
if [ "$ARCH" = "armv7l" ]; then
GOURL=`curl -so- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-armv6l\.tar\.gz' | head -n 1`
fi
echo "Downloading golang"
curl -so $WORKDIRECTORY/go.tar.gz $GOURL
tar -xzf $WORKDIRECTORY/go.tar.gz
rm -rf $WORKDIRECTORY/go.tar.gz
export PATH=$WORKDIRECTORY/go/bin:$PATH
export GOROOT=$WORKDIRECTORY/go
fi
fi

NETWORK_CHECK=$(curl -I -s --connect-timeout 5 https://github.com -w %{http_code} | tail -n1)
if [ -d $WORKDIRECTORY/boringssl ]; then
cd $WORKDIRECTORY/boringssl
git reset --hard remotes/origin/master
git am $WORKDIRECTORY/*.patch
rm -rf $WORKDIRECTORY/boringssl/boringssl/build
rm -rf $WORKDIRECTORY/boringssl/boringssl/build2
rm -rf $WORKDIRECTORY/boringssl/boringssl/.openssl
else
if [ "$NETWORK_CHECK" = "200" ]; then
  git clone --depth 1 https://github.com/google/boringssl.git $WORKDIRECTORY/boringssl
  cd $WORKDIRECTORY/boringssl
  git am $WORKDIRECTORY/*.patch
else
  echo "Unable to connect to GitHub, please check your Internet availability"
  exit 1
fi
fi

mkdir $WORKDIRECTORY/boringssl/build
cd $WORKDIRECTORY/boringssl/build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j`nproc`
mkdir $WORKDIRECTORY/boringssl/build2
cd $WORKDIRECTORY/boringssl/build2
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=1
make -j`nproc`
mkdir $WORKDIRECTORY/boringssl/.openssl
mkdir $WORKDIRECTORY/boringssl/.openssl/include
mkdir $WORKDIRECTORY/boringssl/.openssl/include/openssl
cd $WORKDIRECTORY/boringssl/.openssl/include/openssl
ln $WORKDIRECTORY/boringssl/include/openssl/* .
mkdir $WORKDIRECTORY/boringssl/.openssl/lib
cp $WORKDIRECTORY/boringssl/build/crypto/libcrypto.a $WORKDIRECTORY/boringssl/.openssl/lib/libcrypto.a
cp $WORKDIRECTORY/boringssl/build/ssl/libssl.a $WORKDIRECTORY/boringssl/.openssl/lib/libssl.a
cp $WORKDIRECTORY/boringssl/build2/crypto/libcrypto.so $WORKDIRECTORY/boringssl/.openssl/lib/libcrypto.so
cp $WORKDIRECTORY/boringssl/build2/ssl/libssl.so $WORKDIRECTORY/boringssl/.openssl/lib/libssl.so
echo "Configure nginx with \"--with-openssl=$WORKDIRECTORY/boringssl\". Use nginx version >= 1.15 for best result."
echo "Run \"touch $WORKDIRECTORY/boringssl/.openssl/include/openssl/ssl.h\" AFTER you encountered a build error"
