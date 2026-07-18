# syntax=docker/dockerfile:1

FROM ubuntu:24.04 AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential nasm pkg-config curl \
      libcjson-dev libwebsockets-dev libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY Makefile ./
COPY asm asm
COPY include include
COPY ffi ffi
COPY tests tests
RUN chmod +x tests/foundation.sh && make -j"$(nproc)" && make check

FROM ubuntu:24.04 AS run
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      libcjson1 libwebsockets19t64 libcurl4t64 libssl3t64 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /src/build/hollow-grid-asm /usr/local/bin/hollow-grid-asm
VOLUME ["/data"]
EXPOSE 8793
ENTRYPOINT ["/usr/local/bin/hollow-grid-asm"]
CMD ["--addr", "0.0.0.0:8793", "--world-name", "Basalt Relay"]

