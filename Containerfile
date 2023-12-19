FROM docker.io/archlinux:base-devel as builder

# Setup keyring
RUN pacman-key --init && \
    pacman-key --populate

# Install git
RUN pacman -Syy git --noconfirm

# Create build user
RUN useradd -m --shell=/bin/bash build && usermod -L build && \
    echo "build ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install AUR builder and packages
USER build
WORKDIR /home/build

RUN git clone https://github.com/KyleGospo/xdg-utils-distrobox-arch.git --single-branch && \
    cd xdg-utils-distrobox-arch/trunk && \
    makepkg -si --noconfirm && \
    cd ../.. && \
    rm -drf xdg-utils-distrobox-arch

RUN git clone https://aur.archlinux.org/yay-bin.git --single-branch && \
    cd yay-bin && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -drf yay-bin && \
    yay -S --noconfirm \
        adw-gtk3 \
        alhp-keyring \
        alhp-mirrorlist \
        bash-completion \
        bc \
        curl \
        diffutils \
        findutils \
        glibc \
        gnupg \
        inetutils \
        keyutils \
        less \
        lsof \
        man-db \
        man-pages \
        mlocate \
        mtr \
        ncurses \
        nss-mdns \
        openssh \
        pigz \
        pinentry \
        procps-ng \
        rsync \
        shadow \
        sudo \
        tcpdump \
        time \
        traceroute \
        tree \
        tzdata \
        unzip \
        util-linux \
        util-linux-libs \
        vim \
        vte-common \
        wget \
        words \
        xorg-xauth \
        zip \
        mesa \
        opengl-driver \
        vulkan-intel \
        vulkan-radeon

# Install extra packages
COPY extra-packages /extra-packages
RUN cat /extra-packages | xargs | yay -Syu --needed --noconfirm
RUN rm /extra-packages

# Cleanup AUR builder
USER root
WORKDIR /
RUN userdel -r build && \
    rm -drf /home/build && \
    sed -i '/build ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    sed -i '/root ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/*

# Copy default configurations
COPY rootfs/ /

# Setup ALHP
# Do this last so we only have to reinstall final system packages and not build deps
RUN sed -i '/\#\[core-testing\]/i \
[core-x86-64-v3]\nInclude = /etc/pacman.d/alhp-mirrorlist\n\n[extra-x86-64-v3]\nInclude = /etc/pacman.d/alhp-mirrorlist\n' /etc/pacman.conf && \
    pacman -Syyu --noconfirm && pacman -Scc --noconfirm

# Native march & tune. We do this last because it'll only apply to updates the user makes going forward.
# We don't want to optimize for the build host's environment.
RUN sed -i 's/-march=x86-64 -mtune=generic/-march=native -mtune=native/g' /etc/makepkg.conf

# Copy contents of builder image to root to remove previous image layers
FROM scratch as arch-userenv
COPY --from=builder / /

