FROM ghcr.io/glassrom/os-image-docker@sha256:322d1ca79ce1f476786414df0c89914c90ceec9881ca53560e138f641a7ac63d AS specbuilder

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

FROM ghcr.io/glassrom/os-image-docker@sha256:322d1ca79ce1f476786414df0c89914c90ceec9881ca53560e138f641a7ac63d AS pcrebuilder

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
RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg

FROM ghcr.io/glassrom/os-image-docker@sha256:322d1ca79ce1f476786414df0c89914c90ceec9881ca53560e138f641a7ac63d AS builder

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

FROM ghcr.io/glassrom/os-image-docker@sha256:322d1ca79ce1f476786414df0c89914c90ceec9881ca53560e138f641a7ac63d

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm

COPY --from=specbuilder --chown=root:root --chmod=0755 /home/user/lib/spectrethunk.tar.zst /
RUN pacman -U --noconfirm /spectrethunk.tar.zst && rm -v /spectrethunk.tar.zst

COPY --from=builder /hardened_malloc/out/libhardened_malloc.so /libhardened_malloc.so
RUN mv libhardened_malloc.so $(cat /etc/ld.so.preload)

COPY --from=pcrebuilder /pcre-pkgbuild-nojit/pcre.pkg.tar.zst /
RUN pacman -U --noconfirm pcre.pkg.tar.zst && rm -v pcre.pkg.tar.zst

RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg
