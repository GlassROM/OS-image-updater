FROM ghcr.io/glassrom/os-image-docker@sha256:00e2ee3abde51393648d0c20ade232e75840c90f9f750332f5aa45e066705dc3 AS builder

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
RUN mv out/libhardened_malloc.so $(cat /etc/ld.so.preload)

RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg

FROM ghcr.io/glassrom/os-image-docker@sha256:00e2ee3abde51393648d0c20ade232e75840c90f9f750332f5aa45e066705dc3

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm

COPY --from=builder /hardened_malloc/out/libbardened_malloc.so /libhardened_malloc.so
RUN mv libhardened_malloc.so $(cat /etc/ld.so.preload)

RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg
