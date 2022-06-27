#!/bin/bash

ARCH="$1";
SOURCE_DIR="$2"

GOOS=linux

case $ARCH in
    "armhf" )
        GOARCH=arm;
        GOARM=6;;
    "arm64" )
        GOARCH=arm;
        GOARM=7;;
    "amd64" )
        GOARCH="amd64";;
    * )
        echo "$ARCH doesn't support Go"; exit;;
esac

rm -rf gocryptfs
git clone https://github.com/rfjakob/gocryptfs
cd gocryptfs

# Prevent the build script from running the binary
sed -i '95,98d' ./build.bash

./build-without-openssl.bash

cp ./gocryptfs ../install
cp ./gocryptfs-xray/gocryptfs-xray ../install
