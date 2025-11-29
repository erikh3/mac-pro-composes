#!/usr/bin/env bash

# This script installs OpenTofu.
# https://opentofu.org/docs/intro/install/

if ! command -v tofu &> /dev/null; then
    echo "$(date) opentofu is not installed. Running install script."

    # configure install method
    if command -v apt-get &> /dev/null; then
        export OPENTOFU_INSTALL_METHOD="deb"
    elif command -v apk &> /dev/null; then
        export OPENTOFU_INSTALL_METHOD="apk"
    fi

    # install
    echo "$(date) Install method: $OPENTOFU_INSTALL_METHOD"

    curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh

    chmod +x install-opentofu.sh
    ./install-opentofu.sh --install-method $OPENTOFU_INSTALL_METHOD
    rm -f install-opentofu.sh
  
    # verify installation
    if command -v tofu &> /dev/null; then
        echo "$(date) Successfully installed opentofu: $(tofu --version)"
    else
        echo "$(date) Failed to install opentofu."
        exit 1
    fi
fi
