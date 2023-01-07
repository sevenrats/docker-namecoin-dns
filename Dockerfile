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

FROM sevenrats/namecoin-core
USER root
RUN \
apk add --no-cache coredns libcap curl && \
mkdir -p data
USER namecoin
EXPOSE 1053
COPY root /
COPY --from=ncdns-builder /gopath/bin /usr/bin

ENV NMCCORE_CONF "namecoin-core/namecoin.conf"
ENV NCDNS_CONF "ncdns/ncdns.conf"
ENV COREDNS_CONF "coredns/corefile"
ENV CONFS $NMCCORE_CONF $NCDNS_CONF $COREDNS_CONF
ENV LC_ALL C

ENTRYPOINT ["catatonit", "/entrypoint.sh"]
