Vagrant.require_version ">= 1.7.2"

# pre-loaded Docker images
PRELOADED_IMAGES = [
  "ubuntu:trusty",
  "centos:7",
  "debian:jessie",
  "busybox",
  "progrium/busybox",
  "alpine:3.1",
  "williamyeh/busybox-sh",
  "williamyeh/dash",
  "golang:1.4.2"
  ]

Vagrant.configure(2) do |config|
  config.vm.box = "williamyeh/ubuntu-trusty64-docker"


  config.vm.provision "docker", images: PRELOADED_IMAGES

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y redis-tools
  SHELL


end
