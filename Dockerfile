FROM dock0/build
MAINTAINER akerl <me@lesaker.org>
RUN pacman -S --needed --noconfirm help2man
