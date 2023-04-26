ARG FEDORA_MAJOR_VERSION=38
ARG BASE_CONTAINER_URL=ghcr.io/ublue-os/silverblue-main
ARG PKCS11_PROVIDER_VERSION=0.1

FROM fedora:${FEDORA_MAJOR_VERSION} AS builder
ARG FEDORA_MAJOR_VERSION
ARG PKCS11_PROVIDER_VERSION
RUN dnf install -y \
  rpmdevtools openssl-devel gcc autoconf-archive automake libtool \
  nss-devel nss-softokn nss-softokn-devel nss-tools openssl softhsm \
  opensc p11-kit-devel p11-kit-server gnutls-utils xz expect
RUN cd /root && rpmdev-setuptree
RUN cd /root/rpmbuild \
    && curl -L -o SOURCES/pkcs11-provider-${PKCS11_PROVIDER_VERSION}.tar.gz https://github.com/latchset/pkcs11-provider/archive/refs/tags/v${PKCS11_PROVIDER_VERSION}.tar.gz \
    && tar -xzf SOURCES/pkcs11-provider-${PKCS11_PROVIDER_VERSION}.tar.gz --strip-components=2 -C SPECS pkcs11-provider-${PKCS11_PROVIDER_VERSION}/packaging/pkcs11-provider.spec \
    && rpmbuild -bb SPECS/pkcs11-provider.spec

FROM ${BASE_CONTAINER_URL}:${FEDORA_MAJOR_VERSION}
ARG RECIPE
ARG FEDORA_MAJOR_VERSION
ARG PKCS11_PROVIDER_VERSION

# copy over configuration files
COPY etc /etc
# COPY usr /usr

COPY ${RECIPE} /tmp/ublue-recipe.yml

# yq used in build.sh and the setup-flatpaks recipe to read the recipe.yml
# copied from the official container image as it's not avaible as an rpm
COPY --from=docker.io/mikefarah/yq /usr/bin/yq /usr/bin/yq

COPY --from=builder /root/rpmbuild/RPMS/x86_64/pkcs11-provider-${PKCS11_PROVIDER_VERSION}-1.fc${FEDORA_MAJOR_VERSION}.x86_64.rpm /tmp/pkcs11-provider-${PKCS11_PROVIDER_VERSION}-1.fc${FEDORA_MAJOR_VERSION}.x86_64.rpm
RUN yq -i ".rpms += \"/tmp/pkcs11-provider-${PKCS11_PROVIDER_VERSION}-1.fc${FEDORA_MAJOR_VERSION}.x86_64.rpm\"" /tmp/ublue-recipe.yml

# copy and run the build script
COPY build.sh /tmp/build.sh
RUN chmod +x /tmp/build.sh && /tmp/build.sh

COPY nix.sh /tmp/nix.sh
RUN chmod +x /tmp/nix.sh && /tmp/nix.sh

# clean up and finalize container build
RUN rm -rf \
        /tmp/* \
        /var/* && \
    ostree container commit
