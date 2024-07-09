FROM ghcr.io/glassrom/os-image-docker@sha256:00e2ee3abde51393648d0c20ade232e75840c90f9f750332f5aa45e066705dc3

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm

RUN yes | pacman -Scc

RUN rm -rvf /etc/pacman.d/gnupg
