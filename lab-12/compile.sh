#!/bin/bash

WRK_VERSION=${1:-1.0.0}
WRK_TARBALL=https://github.com/wg/wrk/archive/$WRK_VERSION.tar.gz


echo "==> Installing toolchain for building..."
sudo apt-get update
sudo apt-get -f -y install curl make gcc


echo
echo "==> Installing dependencies..."
sudo apt-get -f -y install libssl-dev


echo
echo "===> Downloading wrk source..."
#curl -L -o wrk-$WRK_VERSION.tar.gz $WRK_TARBALL
tar zxvf wrk-$WRK_VERSION.tar.gz
cd wrk-$WRK_VERSION


echo
echo "===> Patching for static linking..."
sed -i 's/LDFLAGS := -pthread/LDFLAGS := -pthread -static -static-libgcc/' Makefile


echo
echo "==> Building..."
make
#sudo make install


echo
echo "==> Copying out executable..."
cp  wrk  ../wrk_linux-amd64


echo
echo "==> Done!"
