FROM ghcr.io/glassrom/os-image-docker@sha256:d7faaa5a2d886b9a67a38edf60410f71dbce23c4e7fb8ec0199f1eeaaa994d1f AS specbuilder

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm base-devel git gcc gcc-libs clang llvm

RUN useradd -m user

USER user

WORKDIR /home/user
RUN git clone https://github.com/GlassROM/x86_userspace_spectre_mitigation.git --depth=1 --single-branch --branch=master lib
WORKDIR /home/user/lib
RUN makepkg -sf --noconfirm
RUN rm *debug* && mv *.tar.zst spectrethunk.tar.zst

USER root

RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg

FROM ghcr.io/glassrom/os-image-docker@sha256:d7faaa5a2d886b9a67a38edf60410f71dbce23c4e7fb8ec0199f1eeaaa994d1f AS builder

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm base-devel git

WORKDIR /
RUN git clone https://github.com/GlassROM/hardened_malloc.git --depth=1 --single-branch --branch=containers
RUN pacman -S --noconfirm clang lld llvm
WORKDIR /hardened_malloc
RUN chown -R nobody:nobody /hardened_malloc
USER nobody
RUN make
USER root
RUN cp -av out/libhardened_malloc.so $(cat /etc/ld.so.preload)

RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg

FROM ghcr.io/glassrom/os-image-docker@sha256:d7faaa5a2d886b9a67a38edf60410f71dbce23c4e7fb8ec0199f1eeaaa994d1f

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm

COPY --from=specbuilder --chown=root:root --chmod=0755 /home/user/lib/spectrethunk.tar.zst /
RUN pacman -U --noconfirm /spectrethunk.tar.zst && rm -v /spectrethunk.tar.zst

COPY --from=builder /hardened_malloc/out/libhardened_malloc.so /libhardened_malloc.so
RUN mv libhardened_malloc.so $(cat /etc/ld.so.preload)

RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg
