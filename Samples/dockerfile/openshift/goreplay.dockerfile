FROM registry.access.redhat.com/ubi8/ubi:8.6 as builder

ENV RELEASE_VERSION=1.3.3

RUN dnf install wget -y && wget https://github.com/buger/goreplay/releases/download/${RELEASE_VERSION}/gor_${RELEASE_VERSION}_x64.tar.gz -O gor.tar.gz
RUN tar xzf gor.tar.gz

FROM scratch
COPY --from=builder /gor /usr/local/bin/gor

ENTRYPOINT ["/usr/local/bin/gor", "--input-raw", ":8081", "--output-stdout"]