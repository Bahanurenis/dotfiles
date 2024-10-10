#!/bin/env bash
#set -x

while [ $# -gt 0 ]; do
    case $1 in
        -p|--with-packaging)
            INCLUDE_PACKAGING="true"
            ;;
        *)
            echo "Unknown argument $1"
            ;;
    esac
    shift
done

dotfiles_version=`cat ./.version`
echo "Dotfiles version $dotfiles_version"
if [ -d ~/.config/dotfiles ]; then
    config_dotfiles_version=`cat ~/.config/dotfiles/.version`
    if [ "$dotfiles_version" != "$config_dotfiles_version" ]; then
	echo "Make sure you are executing this script from ~/.config/dotfiles"
        exit 1
    fi
else
    echo "There is no ~/.config/dotfiles make sure you cloned the dotfiles repo in ~/.config directory"
    exit 1
fi

cd ~/.config/dotfiles
DOTFILES_DIR=~/.config/dotfiles

nix_version=`which nix`
is_macos=`uname -a | grep Darwin`
is_linux=`uname -a | grep Linux`
if [ -z "$nix_version" ]; then
    if [ -n "$is_macos" -a ! which nix &> /dev/null ]; then
        echo "Detected a macos system..."
        curl -L https://nixos.org/nix/install | sh
    elif [ -n "$is_linux" -a ! which nix &> /dev/null ]; then
        echo "Detected a linux system..."
        curl -L https://nixos.org/nix/install | sh -s -- --daemon
    fi
    ln -s $DOTFILES_DIR/nix.conf ~/.config/nix/nix.conf
else
    echo "nix is already installed skipping the installation step for nix"
fi

if [ -n "$is_linux" ]; then
    if [ ! which home-manager &> /dev/null ]; then
        INCLUDE_PACKAGING="$INCLUDE_PACKAGING" nix run home-manager -- init --switch "$HOME"/.config/dotfiles/nix --impure
    else
        echo "home-manager is already activated so no need for nix run."
        INCLUDE_PACKAGING="$INCLUDE_PACKAGING" home-manager init --switch $DOTFILES_DIR/nix --show-trace --impure
    fi
    if [ "$INCLUDE_PACKAGING" = "true" ]; then
        echo "Packaging tools installation is enabled. Installing packaging tools..."

        packaging_related_apt_tools=(
            sbuild
            ubuntu-dev-tools
            apt-cacher-ng
            autopkgtest
            lintian
            git-buildpackage
        )
        # TODO: add missing packaging related configurations

        # sudo apt install "${packaging_related_apt_tools[@]}"
        # source ~/.packaging.bashrc
        # setup-packaging-environment
    fi
fi

