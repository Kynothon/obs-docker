FROM ubuntu:18.04 as build

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /usr/src

RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list \
    && apt update \
    && apt upgrade -y \
    && apt install -yqq build-essential git ca-certificates devscripts 

RUN git clone --depth=1 https://git.videolan.org/git/ffmpeg/nv-codec-headers.git \
    && cd nv-codec-headers \
    && make \
    && make install
    
RUN apt-get -yqq build-dep ffmpeg \
    && apt source ffmpeg \
    && cd ffmpeg-* \
    && echo "\nCONFIG += --enable-nonfree --enable-nvenc\n" >> debian/rules \
    && debuild -us -uc -b 

FROM nvidia/cuda:10.2-runtime-ubuntu18.04 as release

ENV NVIDIA_DRIVER_CAPABILITIES video,graphics

COPY --from=build /usr/src/*.deb  /var/cache/apt/archives/

RUN dpkg -i /var/cache/apt/archives/*.deb \
    ; apt update \
    && apt --fix-broken install -y 

RUN apt install -yqq software-properties-common \
    && add-apt-repository ppa:obsproject/obs-studio \
    && apt install -yqq obs-studio libgl1

CMD ["obs"]
