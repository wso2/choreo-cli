#!/bin/bash
# Based on Deno and nvm installer: Copyright 2023 the Deno authors. All rights reserved. MIT license.
# TODO(everyone): Keep this script simple and easily auditable.
set -e

getArchitecture() {
    local ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')
    if [[ "$ARCH" == "x86_64" ]]; then
        echo "amd64"
    elif [[ "$ARCH" == "i386" ]]; then
        echo "386"
    elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
        echo "arm64"
    elif [[ "$ARCH" == "arm" ]]; then
        echo "arm"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi
}

getVersion() {
    if [ -n "$1" ]; then
        echo $1
        return
    fi
    local LAST_RELEASE=${LAST_RELEASE:-"false"}

    if [ "$LAST_RELEASE" == "true" ]; then
        local VERSION=$(curl --silent https://api.github.com/repos/wso2/choreo-cli/releases | grep -E 'tag_name|prerelease": true' | grep -E 'prerelease": true' -B1 | head -n 1 | awk -F '"' '{print $4}')
    else
        local VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/wso2/choreo-cli/releases/latest | cut -d/ -f8)
    fi

    echo $VERSION
}

main() {
    local OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local ARCH=$(getArchitecture)
    local SHELL_TYPE=$(basename $SHELL)
    local WDP_DIR=~/.wdp
    local WDP_BIN_DIR=$WDP_DIR/bin
    local WDP_CLI_EXEC=$WDP_BIN_DIR/wdp
    local WDP_TMP_DIR=$(mktemp -d -t wdp-XXXXXXXXXX)
    local LATEST_VERSION=$(getVersion $1)
    mkdir -p $WDP_BIN_DIR

    local FILE_NAME="wdp-cli-$LATEST_VERSION-$OS-$ARCH"
    local FILE_TYPE=""

    # if architecture is linux append .tar.gz to the installer url and if it is darwin add .zip
    if [[ "$OS" == "linux" ]]; then
        FILE_TYPE=".tar.gz"
    elif [[ "$OS" == "darwin" ]]; then
        FILE_TYPE=".zip"
    else
        echo "Unsupported OS: $OS"
        exit 1
    fi

    # TODO: change this to the actual release url
    # local INSTALLER_URL="https://cli.choreo.dev/latest/$FILE_NAME$FILE_TYPE"
    local INSTALLER_URL="https://github.com/wso2/choreo-cli/releases/download/$LATEST_VERSION/$FILE_NAME$FILE_TYPE"

    echo "Installing wdp..."
    echo "Downloading latest release..."
    echo "URL: $INSTALLER_URL"
    curl -q --fail --location --progress-bar --output "$WDP_TMP_DIR/$FILE_NAME$FILE_TYPE" "$INSTALLER_URL"

    local 
    echo "Extracting archive..."
    echo "Temp dir: $WDP_TMP_DIR"
    if [[ "$FILE_TYPE" == ".tar.gz" ]]; then
        mkdir -p "$WDP_TMP_DIR/$OS-$ARCH"
        tar -xzf "$WDP_TMP_DIR/$FILE_NAME$FILE_TYPE" -C "$WDP_TMP_DIR/$OS-$ARCH"
    elif [[ "$FILE_TYPE" == ".zip" ]]; then
        unzip -q "$WDP_TMP_DIR/$FILE_NAME$FILE_TYPE" -d "$WDP_TMP_DIR/$OS-$ARCH"
    fi

    echo "Moving executable to $WDP_BIN_DIR"

    mv "$WDP_TMP_DIR/$OS-$ARCH/wdp" "$WDP_CLI_EXEC"

    echo "Cleaning up..."
    rm -rf "$WDP_TMP_DIR"

    cd $WDP_BIN_DIR
    chmod +x $WDP_CLI_EXEC
    touch ./wdp-completion

    ./wdp completion $SHELL_TYPE > ./wdp-completion
    chmod +x ./wdp-completion

    local PROFILE=$(detect_profile)

    if [ -z $PROFILE ]; then
        echo "No profile detected"
        echo "Please add the following lines to the correct profile file yourself:"
        echo ""
        echo "export WDP_DIR=$WDP_DIR" >> $PROFILE
        echo "export PATH=$WDP_DIR/bin:\$PATH" >> "$PROFILE"
        echo "[ -f $WDP_DIR/wdp-completion ] && source $WDP_DIR/wdp-completion" >> "$PROFILE"
        echo ""
        echo "Then open a new terminal and run 'wdp --help' to get started."
    else
        echo "Detected profile: $PROFILE"
        if ! grep -qc "$WDP_DIR" "$PROFILE"; then
            echo "Adding wdp to PATH in $PROFILE"
            echo -e "\n# wdp cli" >> $PROFILE
            echo "export WDP_DIR=$WDP_DIR" >> $PROFILE
            echo "export PATH=$WDP_DIR/bin:\$PATH" >> "$PROFILE"
            echo "[ -f \$WDP_DIR/bin/wdp-completion ] && source \$WDP_DIR/bin/wdp-completion" >> "$PROFILE"
            echo "# wdp cli end" >> $PROFILE
            echo ""
            echo "WSO2 Developer Platform CLI was installed successfully 🎉"
            echo ""
            echo "Run 'source $PROFILE' or open a new terminal, then run 'wdp --help' to get started."
        else
            echo ""
            echo "WSO2 Developer Platform CLI was installed successfully 🎉"
            echo ""
            echo "Run 'wdp --help' to get started."
        fi
    fi
}

detect_profile() {
    if [ "${PROFILE-}" = '/dev/null' ]; then
        # the user has specifically requested NOT to touch their profile
        return
    fi

    if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
        nvm_echo "${PROFILE}"
        return
    fi

    local DETECTED_PROFILE
    DETECTED_PROFILE=''


    if [ "${SHELL#*bash}" != "$SHELL" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            DETECTED_PROFILE="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            DETECTED_PROFILE="$HOME/.bash_profile"
        fi
    elif [ "${SHELL#*zsh}" != "$SHELL" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            DETECTED_PROFILE="$HOME/.zshrc"
        elif [ -f "$HOME/.zprofile" ]; then
            DETECTED_PROFILE="$HOME/.zprofile"
        fi
    fi

    if [ -z "$DETECTED_PROFILE" ]; then
        if [ -f "$HOME/.profile" ]; then
            DETECTED_PROFILE="$HOME/.profile"
        elif [ -f "$HOME/.bashrc" ]; then
            DETECTED_PROFILE="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            DETECTED_PROFILE="$HOME/.bash_profile"
        elif [ -f "$HOME/.zshrc" ]; then
            DETECTED_PROFILE="$HOME/.zshrc"
        elif [ -f "$HOME/.zprofile" ]; then
            DETECTED_PROFILE="$HOME/.zprofile"
        fi
    fi

    if [ ! -z "$DETECTED_PROFILE" ]; then
        echo "$DETECTED_PROFILE"
    fi
}


main "$@"
unset -f main detect_profile getArchitecture 
