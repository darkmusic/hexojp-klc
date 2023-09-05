FROM archlinux:base-devel AS base

USER root
RUN pacman-key --init
RUN pacman -Syy
RUN pacman -S archlinux-keyring --noconfirm
RUN pacman -S reflector rsync curl glibc --noconfirm
RUN reflector -l 5 --protocol https --sort rate --country US --save /etc/pacman.d/mirrorlist

RUN pacman -S git vi vim nano wget ninja cmake iproute2 python python-virtualenv libpqxx unzip openssh \
              man-db man-pages htop inetutils perl perl-dbi perl-dbd-pg perl-yaml-tiny nodejs rust cargo-make \
              postgresql nodejs npm --noconfirm
RUN npm install -g hexo-cli

FROM base AS config
RUN useradd -m hexojp

USER hexojp
WORKDIR /home/hexojp
RUN mkdir -p code/hexojp

WORKDIR /home/hexojp/code
RUN virtualenv3 py3venv && \
    echo "source ~/code/py3venv/bin/activate" >> ~/.bashrc

WORKDIR /home/hexojp/code/hexojp

COPY ci ci
COPY db db
COPY scaffolds scaffolds
COPY source source
COPY themes themes
COPY *.yml .
COPY package.json .
USER root
RUN chown -R hexojp:hexojp /home/hexojp

USER hexojp
WORKDIR /home/hexojp/code/hexojp
RUN npm install
