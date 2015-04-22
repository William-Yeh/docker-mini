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

    config.vm.define "main", primary: true do |node|
        node.vm.box = "williamyeh/ubuntu-trusty64-docker"
        node.vm.box_version = ">= 1.6.0"

        node.vm.provision "docker", images: PRELOADED_IMAGES

        node.vm.provision "shell", inline: <<-SHELL
            sudo apt-get update
            sudo apt-get install -y redis-tools
        SHELL
    end


    config.vm.define "centos" do |node|
        node.vm.box = "chef/centos-7.0"

        node.vm.provider "virtualbox" do |vb|
            vb.customize ["modifyvm", :id, "--memory", "256"]
        end
    end

end
