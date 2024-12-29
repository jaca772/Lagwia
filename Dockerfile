# Etap budowania (build)
FROM ubuntu:22.04 AS build

# Ustawienie strefy czasowej
ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/Warsaw

# Instalacja zależności kompilacji
RUN apt-get update && apt-get install --no-install-recommends -y \
  git \
  autoconf \
  automake \
  pkg-config \
  build-essential \
  cmake \
  liblua5.1-0-dev \
  libsqlite3-dev \
  libmysqlclient-dev \
  libxml2-dev \
  libgmp3-dev \
  libboost-filesystem-dev \
  libboost-regex-dev \
  libboost-thread-dev \
  libboost-iostreams-dev \
  gcc \
  g++ \
  cpp \
  wget \
  libcrypto++-dev \
  libpugixml-dev \
  libgomp1 \
  libfmt-dev \
  zlib1g-dev \
  libstdc++-11-dev \
  && apt-get clean

# Skopiowanie kodu źródłowego do kontenera
COPY cmake /usr/src/forgottenserver/cmake/
COPY src /usr/src/forgottenserver/src/
COPY CMakeLists.txt /usr/src/forgottenserver/

# Ustawienie katalogu roboczego i kompilowanie projektu
WORKDIR /usr/src/forgottenserver/build

# Opcja, aby wymusić użycie Lua (a nie LuaJIT), jeśli LuaJIT nie jest potrzebny
RUN cmake .. -DUSE_LUAJIT=OFF && make -j$(nproc)
