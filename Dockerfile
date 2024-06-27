FROM ghcr.io/glassrom/os-image-docker@sha256:031127ff3e0eaf80cedc09e5d02f35feb0c20c67aee8e777d60eb6c4aab220b7

RUN pacman-key --init && pacman-key --populate archlinux

RUN pacman -Syyuu --noconfirm

RUN rm -rvf /etc/pacman.d/gnupg
