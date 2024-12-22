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
  gcc-10 \
  g++-10 \
  cpp-10 \
  wget \
  libcrypto++-dev \
  libpugixml-dev \
  libgomp1 \
  libfmt-dev \
  zlib1g-dev \
  && apt-get clean

# Ustawienie wersji kompilatora gcc i g++
RUN rm -rf /usr/bin/gcc && rm -rf /usr/bin/g++ \
  && ln -s /usr/bin/gcc-10 /usr/bin/gcc \
  && ln -s /usr/bin/g++-10 /usr/bin/g++

# Skopiowanie kodu źródłowego do kontenera
COPY cmake /usr/src/forgottenserver/cmake/
COPY src /usr/src/forgottenserver/src/
COPY CMakeLists.txt /usr/src/forgottenserver/

# Ustawienie katalogu roboczego i kompilowanie projektu
WORKDIR /usr/src/forgottenserver/build

# Opcja, aby wymusić użycie Lua (a nie LuaJIT), jeśli LuaJIT nie jest potrzebny
RUN cmake .. -DUSE_LUAJIT=OFF && make -j$(nproc)

# Etap uruchomienia (runtime)
FROM ubuntu:22.04

# Instalacja zależności runtime (z Crypto++ i OpenSSL 3.0)
RUN apt-get update && apt-get install -y \
  liblua5.1-0 \
  libsqlite3-dev \
  libmysqlclient-dev \
  libxml2 \
  libgmp10 \
  libboost-filesystem1.74.0 \
  libboost-regex1.74.0 \
  libboost-thread1.74.0 \
  libboost-iostreams1.74.0 \
  libssl-dev \
  libcrypto++-dev \
  libpugixml-dev \
  zlib1g-dev \
  libfmt-dev \
  && apt-get clean

# Kopiowanie skompilowanego pliku binarnego oraz innych danych
COPY --from=build /usr/src/forgottenserver/build/tfs /bin/tfs
COPY data /srv/data/
COPY config.lua *.sql key.pem /srv/

# Ustawienia portów oraz katalogu roboczego
EXPOSE 7171 7172
WORKDIR /srv
VOLUME /srv

# Uruchomienie pliku wykonywalnego
ENTRYPOINT ["/bin/tfs"]
