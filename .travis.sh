#!/bin/bash
set -xe

# Use latest Augeas
sudo add-apt-repository -y ppa:raphink/augeas
sudo apt-get update
sudo apt-get install augeas-tools libaugeas-dev libxml2-dev
