FROM alpine:latest AS prepare

ARG HATH_SRC=https://repo.e-hentai.org/hath/HentaiAtHome_1.6.4_src.zip

WORKDIR /root

RUN apk update && apk add --no-cache unzip wget && \
    wget ${HATH_SRC}  -O hath.zip && \
    mkdir -p hath && \
    unzip -q hath.zip -d ./hath && \
    rm -rf ./hath/src/hath/gui

# FROM ghcr.io/graalvm/native-image-community:25-muslib AS jre-builder
FROM ghcr.io/graalvm/native-image-community:25 AS jre-builder

WORKDIR /root
COPY --from=prepare /root/hath /root/hath
COPY start.sh start.sh

RUN cd /root/hath && mkdir -p build && \
    cd src && find . -type f -name "*.java" -exec printf "%s/%s\n" "$PWD" "{}" \; > ../build/srcfiles.txt && \
    cd .. && javac -Xlint:deprecation,unchecked --release 25 -d ./build "@build/srcfiles.txt"

# RUN cd /root/hath && \
#     native-image -O2 --static --libc=musl --enable-http --enable-https -cp ./build hath.base.HentaiAtHomeClient HentaiAtHome --no-fallback && \
#     chmod 755 /root/start.sh /root/hath/HentaiAtHome
RUN cd /root/hath && \
    native-image -O2 --enable-http --enable-https -cp ./build hath.base.HentaiAtHomeClient HentaiAtHome --no-fallback && \
    chmod 755 /root/start.sh /root/hath/HentaiAtHome

FROM alpine:latest

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV CLIENT_ID=""
ENV CLIENT_KEY=""

VOLUME /hath

WORKDIR /root

COPY --from=jre-builder /root/hath/HentaiAtHome /root/HentaiAtHome
COPY --from=jre-builder /root/start.sh /root/start.sh

RUN apk add --no-cache gcompat

CMD ["/root/start.sh"]
