FROM eclipse-temurin:25-jdk-alpine AS jre-builder

RUN $JAVA_HOME/bin/jlink \
      --add-modules java.base,java.logging,java.naming,java.net.http,jdk.naming.dns \
      --strip-debug \
      --no-header-files \
      --no-man-pages \
      --compress=zip-6 \
      --output /custom-jre

ARG HATH_SRC=https://repo.e-hentai.org/hath/HentaiAtHome_1.6.4_src.zip

WORKDIR /root
COPY ${HATH_SRC} hath.zip
COPY start.sh start.sh

RUN apk update && apk add --no-cache unzip wget && \
    wget ${HATH_SRC}  -O hath.zip && \
    mkdir -p hath && \
    unzip -q hath.zip -d ./hath && \
    cd ./hath && mkdir -p build && \
    cd src && find . -type f -name "*.java" -exec printf "%s/%s\n" "$PWD" "{}" \; > ../build/srcfiles.txt && \
    cd .. && javac -Xlint:deprecation,unchecked --release 25 -d ./build "@build/srcfiles.txt" && \
    cd build && jar cvfm HentaiAtHome.jar ../src/hath/base/HentaiAtHome.manifest hath/base && \
    chmod 755 /root/start.sh

FROM alpine:latest

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/custom-jre
ENV PATH="$JAVA_HOME/bin:$PATH"

ENV CLIENT_ID=""
ENV CLIENT_KEY=""

VOLUME /hath

WORKDIR /root

COPY --from=jre-builder /custom-jre /usr/lib/jvm/custom-jre
COPY --from=jre-builder /root/hath/build/HentaiAtHome.jar /root/HentaiAtHome.jar
COPY --from=jre-builder /root/start.sh /root/start.sh

CMD ["/root/start.sh"]
