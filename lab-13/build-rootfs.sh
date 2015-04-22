#!/bin/bash

WRK_ELF=wrk_linux-amd64


echo
echo "=====> Packing wrk executable and NSS stuff..."
#curl -sSL http://bit.ly/install-extract-elf-so | sudo bash
extract-elf-so     \
    --nss-net  -z  \
    $WRK_ELF


echo
echo "=====> Done!"
