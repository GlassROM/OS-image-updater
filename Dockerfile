FROM ghcr.io/glassrom/os-image-docker@sha256:ea3d500b6f48a333fef6f763fbe65e935073208dd3036b4913cbee1f40878014 AS specbuilder

RUN rm -vf /etc/ld.so.preload
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

RUN rm -rvf /var/cache/pacman/pkg/*
RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg

FROM ghcr.io/glassrom/os-image-docker@sha256:ea3d500b6f48a333fef6f763fbe65e935073208dd3036b4913cbee1f40878014 AS pcrebuilder

RUN rm -vf /etc/ld.so.preload

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm base-devel git

WORKDIR /
RUN git clone https://github.com/GlassROM/pcre-pkgbuild-nojit --depth=1 --single-branch --branch=main
RUN pacman -Syyuu --noconfirm base-devel git clang lld llvm
WORKDIR /pcre-pkgbuild-nojit
RUN chown -R nobody:nobody /pcre-pkgbuild-nojit
USER nobody
RUN makepkg -sf --skippgpcheck
RUN rm -rf *debug* && mv *.tar.zst pcre.pkg.tar.zst

USER root
RUN rm -rvf /var/cache/pacman/pkg/*
RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg

FROM ghcr.io/glassrom/os-image-docker@sha256:ea3d500b6f48a333fef6f763fbe65e935073208dd3036b4913cbee1f40878014 AS builder

RUN rm -vf /etc/ld.so.preload

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
#RUN cp -av out/libhardened_malloc.so $(cat /etc/ld.so.preload)

RUN rm -rvf /var/cache/pacman/pkg/*
RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg

FROM ghcr.io/glassrom/os-image-docker@sha256:ea3d500b6f48a333fef6f763fbe65e935073208dd3036b4913cbee1f40878014

RUN mv /etc/ld.so.preload /etc/ld.so.preload.bak

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm

COPY --from=specbuilder --chown=root:root --chmod=0755 /home/user/lib/spectrethunk.tar.zst /
RUN pacman -U --noconfirm /spectrethunk.tar.zst && rm -vf /spectrethunk.tar.zst

COPY --from=builder /hardened_malloc/out/libhardened_malloc.so /libhardened_malloc.so
RUN mv libhardened_malloc.so $(cat /etc/ld.so.preload.bak)

COPY --from=pcrebuilder /pcre-pkgbuild-nojit/pcre.pkg.tar.zst /
RUN pacman -U --noconfirm /pcre.pkg.tar.zst && rm -vf /pcre.pkg.tar.zst

RUN rm -rvf /var/cache/pacman/pkg/*
RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg

RUN mv /etc/ld.so.preload.bak /etc/ld.so.preload
