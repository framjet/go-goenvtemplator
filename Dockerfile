ARG TARGET_OS
ARG TARGET_ARCH
FROM golang:1.23.6 AS builder
ENV GO111MODULE=on \
  CGO_ENABLED=0 \
  GOOS=${TARGET_OS} \
  GOARCH=${TARGET_ARCH} \
  CONTAINER_BUILD=1


COPY . /go/src/github.com/seznam/

WORKDIR /go/src/github.com/seznam

RUN PATH="/tmp/go/bin:$PATH" make goenvtemplator

# use a distroless base image with glibc
FROM gcr.io/distroless/base-debian11:debug-nonroot

LABEL org.opencontainers.image.source="https://github.com/framjet/go-goenvtemplator"

# copy our compiled binary
COPY --from=builder --chown=nonroot /go/src/github.com/seznam/goenvtemplator/goenvtemplator /usr/local/bin/

# run as non-privileged user
USER nonroot

ENTRYPOINT ["goenvtemplator"]