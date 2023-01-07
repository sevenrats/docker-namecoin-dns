FROM alpine:latest as ncdns-builder
ENV GOPATH=/gopath
RUN \
mkdir /gopath && \
apk add --no-cache libcap-dev git go bash sed gcc musl-dev
RUN \
git clone https://github.com/namecoin/x509-compressed.git && \
cd x509-compressed && \
go mod init github.com/namecoin/x509-compressed && \
go mod tidy && \
go generate ./... && \
go mod tidy && \
cd .. && \
git clone https://github.com/namecoin/certinject.git && \
cd certinject && \
go mod init github.com/namecoin/certinject && \
go mod tidy && \
go generate ./... && \
go mod tidy && \
go install ./... && \
cd .. && \
git clone https://github.com/namecoin/ncdns.git && \
cd ncdns && \
go mod init github.com/namecoin/ncdns && \ 
go mod edit -replace github.com/namecoin/certinject=../certinject -replace github.com/namecoin/x509-compressed=../x509-compressed && \
go mod tidy && \
go install ./...

FROM sevenrats/electrum-nmc
USER root
RUN \
apk add --no-cache coredns libcap curl
USER namecoin

ENV NCDNS_CONF "ncdns/ncdns.conf"
ENV COREDNS_CONF "coredns/corefile"
ENV CONFS $NCDNS_CONF $COREDNS_CONF

EXPOSE 1053
COPY root /
COPY --from=ncdns-builder /gopath/bin /usr/bin

ENTRYPOINT ["catatonit", "/entrypoint.sh"]
