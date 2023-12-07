FROM docker.io/archlinux:base-devel as bootstrap

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
RUN git clone https://aur.archlinux.org/yay-bin.git --single-branch && \
    cd yay-bin && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -drf yay-bin && \
    yay -S --noconfirm --removemake=yes \
        arch-install-scripts \
        alhp-keyring \
        alhp-mirrorlist

# Cleanup AUR builder
USER root
WORKDIR /
RUN userdel -r build && \
    rm -drf /home/build && \
    sed -i '/build ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    sed -i '/root ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/*d a user for it

# Setup ALHP
RUN sed -i '/\#\[core-testing\]/i \
[core-x86-64-v3]\nInclude = /etc/pacman.d/alhp-mirrorlist\n\n[extra-x86-64-v3]\nInclude = /etc/pacman.d/alhp-mirrorlist\n' /etc/pacman.conf && \
    pacman -Syy --noconfirm

# Bootstrap a new rootfs
RUN mkdir /newroot && \
    pacstrap -K /newroot base-devel

FROM scratch AS builder
COPY --from=bootstrap /newroot /

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
COPY extra-packages /home/build
RUN git clone https://aur.archlinux.org/yay-bin.git --single-branch && \
    cd yay-bin && \
    makepkg -si --noconfirm && \
    cd .. && \
    rm -drf yay-bin && \
    yay -S --noconfirm --removemake=yes \
        alhp-keyring \
        alhp-mirrorlist \
        - < extra-packages && \
        rm -f extra-packages

# Cleanup AUR builder
USER root
WORKDIR /
RUN userdel -r build && \
    rm -drf /home/build && \
    sed -i '/build ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    sed -i '/root ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers && \
    rm -rf \
        /tmp/* \
        /var/cache/pacman/pkg/*d a user for it

# Native march & tune. We do this last because it'll only apply to updates the user makes going forward.
# We don't want to optimize for the build host's environment.
RUN sed -i 's/-march=x86-64 -mtune=generic/-march=native -mtune=native/g' /etc/makepkg.conf

# Copy contents of builder image to root to remove previous image layers
FROM scratch as arch-userenv
COPY --from=builder / /

