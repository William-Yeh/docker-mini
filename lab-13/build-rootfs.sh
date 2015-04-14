#!/bin/bash

WRK_ELF=wrk_linux-amd64


echo
echo "=====> Packing wrk executable and NSS stuff..."
../extract-elf-so_static_linux-amd64  \
    --nss-net  -z  \
    $WRK_ELF


echo
echo "=====> Done!"
