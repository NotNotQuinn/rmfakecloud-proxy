#!/bin/bash
# A shitter opkg
# This exists to make it easy to install on versions
# which toltec doesn't support, and for more rapid development.
# -- Imagine loading a docker image for your developement build
set -e

UNIT_NAME=rmfakecloud-multiproxy
DESTINATION="/home/root/rmfakecloud-multiproxy"
SYMLINK_DIR="/usr/bin"

function uninstall(){
    # Ignore errors to uninstall as much as posssible
    set +e
    # multiproxyctl handles all the good stuff
    ${DESTINATION}/multiproxyctl disable

    rm -v $SYMLINK_DIR/multiproxyctl
    rm -v $SYMLINK_DIR/rmfakecloud-multiproxy
    rm -v /etc/systemd/system/${UNIT_NAME}.service
    rm -v -rf $DESTINATION
    set -e
}


function doinstall(){
    echo "==== Extracting embedded tarball and placing files..."
    # Unpack tarball
    mkdir -vp ${DESTINATION}
    # Find __ARCHIVE__ maker, read archive content and decompress it
    ARCHIVE=$(awk '/^__ARCHIVE__/ {print NR + 1; exit 0; }' "${0}")
    tail -n+${ARCHIVE} "${0}" | gunzip | tar x -C ${DESTINATION} -vf -
    chmod +x ${DESTINATION}/rmfakecloud-multiproxy ${DESTINATION}/multiproxyctl

    # Create symlinks
    rm -vf $SYMLINK_DIR/multiproxyctl
    rm -vf $SYMLINK_DIR/rmfakecloud-multiproxy
    ln -vs "${DESTINATION}/multiproxyctl" "$SYMLINK_DIR/multiproxyctl"
    ln -vs "${DESTINATION}/rmfakecloud-multiproxy" "$SYMLINK_DIR/rmfakecloud-multiproxy"

    # Change the ExecStart path
    sed -i 's/^ExecStart=\/opt\/bin/ExecStart=\/home\/root\/rmfakecloud-multiproxy/' ${DESTINATION}/rmfakecloud-multiproxy.service
    cp ${DESTINATION}/rmfakecloud-multiproxy.service /etc/systemd/system/${UNIT_NAME}.service
    systemctl daemon-reload

    echo "==== Running \`multiproxyctl status\`..."
    ${DESTINATION}/multiproxyctl status
}


case $1 in
    "uninstall" )
        uninstall
        ;;

     "install" )
        doinstall
        ;;

     * )

        cat <<EOF
rmFakeCloud multiproxy installer

Usage:

install
    install rmFakeCloud multiproxy
    Use \`multiproxyctl enable\` to enable

uninstall
    disable, uninstall, removes everything created by the installer
    Does not remove configs created by \`multiproxyctl\`
EOF
        ;;

esac

exit 0

__ARCHIVE__
