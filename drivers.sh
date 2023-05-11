#!/bin/bash
set -euxo pipefail

XONE_VERSION=v0.3
curl -Lo /tmp/xone.tar.gz https://github.com/medusalix/xone/archive/refs/tags/${XONE_VERSION}.tar.gz
mkdir -p /tmp/xone
tar -C /tmp/xone --strip-components=1 -xf /tmp/xone.tar.gz
make -C /lib/modules/$(rpm -q kernel | sed 's/^kernel-//')/build LD=ld.gold M=/tmp/xone modules
