FROM alpine:latest as glorytun-build

RUN apk add --update --no-cache \
    autoconf automake libtool git gcc musl-dev make file pkgconfig

RUN git clone https://github.com/jedisct1/libsodium --branch stable \
 && cd libsodium \
 && ./autogen.sh \
 && ./configure --enable-minimal --prefix=/usr \
 && make install-strip

ARG version

RUN git clone https://github.com/angt/glorytun --branch "${version:-master}" --recursive \
 && cd glorytun \
 && ./autogen.sh \
 && ./configure --prefix=/copy \
 && make install-strip

RUN ldd /copy/bin/glorytun \
  | awk '/usr/{print $3}' \
  | tar ch -T- \
  | tar x -C /copy

FROM alpine:latest

ARG key
RUN echo "$key" > /run/gt.key

COPY --from=glorytun-build /copy/ /

ENTRYPOINT ["glorytun", "keyfile", "/run/gt.key"]
