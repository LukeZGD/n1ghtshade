#!/bin/bash
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig

Color_G=$(tput setaf 10)
Color_N=$(tput sgr0)
function Echo {
    echo "${Color_G}$1 ${Color_N}"
}

function Compile {
    git clone https://github.com/$1/$2
    cd $2
    if [[ $1 != libimobiledevice ]] && [[ $1 != libirecovery ]] && [[ -z $3 ]]; then
        ./autogen.sh --enable-static --disable-shared
    elif [[ ! -z $3 ]]; then
        ./autogen.sh --prefix="$(cd ../.. && pwd)/$2"
    else
        ./autogen.sh
    fi
    make
    if [[ ! -z $3 ]]; then
        make install
    else
        sudo make install
    fi
    cd ..
}

function Make {
    Echo "Make n1ghtshade-cli"
    . /etc/os-release
    if [[ ! -z $UBUNTU_CODENAME ]]; then
        sudo apt update
        sudo apt install -y libtool automake g++ python-dev libzip-dev libcurl4-openssl-dev cmake libssl-dev libusb-1.0-0-dev libreadline-dev libbz2-dev libpng-dev pkg-config git gobjc
        Compile libimobiledevice libplist
        Compile libimobiledevice libusbmuxd
        Compile libimobiledevice libimobiledevice
    elif [[ $ID == arch ]] || [[ $ID_LIKE == arch ]]; then
        sudo pacman -S --needed --noconfirm gcc-objc libimobiledevice
    elif [[ $ID == fedora ]]; then
        sudo dnf install automake gcc-g++ gcc-objc libcurl-devel libusb-devel libtool libzip-devel make openssl-devel pkgconf-pkg-config readline-devel
    fi

    mkdir builds
    cd builds
    Compile synackuk libirecovery
    Compile tihmstar libgeneral
    Compile tihmstar libfragmentzip
    git clone https://github.com/gwilymk/bin2c && cd bin2c && make && sudo cp bin2c /usr/local/bin && cd ..
    cd ..
    rm -rf builds

    if [[ $(basename $(pwd)) != n1ghtshade ]]; then
        git clone --recursive https://github.com/synackuk/n1ghtshade
        cd n1ghtshade
    fi
    cd belladonna/src/exploits/checkm8/payload
    sed -z -i s/"PYTHON = python\n"/"PYTHON = python2\n"/g makefile
    cd ../../../../..
    ./autogen.sh
    make
    mv pilocarpine/cli/n1ghtshade .
}

cd "$(dirname $0)"
if [[ $1 == make ]]; then
    Make
elif [[ $1 == libimobiledevice ]]; then
    mkdir builds
    cd builds
    Compile libimobiledevice libplist
    Compile libimobiledevice libusbmuxd
    Compile libimobiledevice libimobiledevice
    cd ..
    rm -rf builds
elif [[ ! -d libirecovery ]]; then
    Echo "n1ghtshade Linux script"
    Echo "Compiling synackuk/libirecovery first..."
    mkdir builds
    cd builds
    Compile synackuk libirecovery prefix
    cd ..
    rm -rf builds
    Echo "Done compiling synackuk/libirecovery"
else
    sudo LD_LIBRARY_PATH=libirecovery/lib:/usr/local/lib ./n1ghtshade $@
fi
