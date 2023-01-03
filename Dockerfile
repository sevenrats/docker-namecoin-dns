FROM alpine:latest as ncdns-builder
ENV GOPATH=/gopath
RUN \
mkdir /gopath && \
apk add --no-cache libcap-dev git go bash sed
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

FROM python:3.9-alpine3.16
ARG BUILD_DATE
ARG VERSION
LABEL	maintainer="sevenrats" \
		build-date=$BUILD_DATE \
		name="Electrum-NMC" \
		description="Electrum-NMC with JSON-RPC enabled" \
		version=$VERSION \
		license="MIT"

ENV ELECTRUM_VERSION $VERSION
ENV ELECTRUM_USER electrum
ENV ELECTRUM_PASSWORD electrumz
ENV ELECTRUM_HOME /home/$ELECTRUM_USER
ENV ELECTRUM_DATA /data/electrum-nmc
ENV ELECTRUM_NETWORK mainnet

RUN \
	echo "**** install electrum-nmc ****" && \
	apk --no-cache add --virtual build-dependencies gcc musl-dev && \
	apk --no-cache add libsecp256k1-dev bash catatonit procps libcap coredns && \
	wget https://www.namecoin.org/files/electrum-nmc/electrum-nmc-4.0.0b1/Electrum-NMC-4.0.0b1.tar.gz && \
	pip3 install Electrum-NMC-4.0.0b1.tar.gz pycryptodomex && \
	rm -f Electrum-NMC-4.0.0b1.tar.gz && \
	apk del build-dependencies && \
	cd / && \
	wget https://raw.githubusercontent.com/sevenrats/signalproxy.sh/main/signalproxy.sh && \
	rm -rf \
		/tmp/* \
		 /sbin/apk /etc/apk /lib/apk /usr/share/apk /var/lib/apk \
		 /usr/share/man/* /lib/python3.9/site-packages/pip \
		/root/.cache

RUN \
adduser -D $ELECTRUM_USER && \
mkdir -p ${ELECTRUM_DATA} && \
ln -sf ${ELECTRUM_DATA}/ ${ELECTRUM_HOME}/.electrum-nmc && \
chown -R ${ELECTRUM_USER} ${ELECTRUM_DATA} /data && \
ln -sf /usr/local/bin/electrum-nmc /usr/local/bin/nmc

USER $ELECTRUM_USER
WORKDIR $ELECTRUM_HOME
VOLUME /data
EXPOSE 1053
COPY root /
COPY --from=ncdns-builder /gopath/bin /usr/bin

ENTRYPOINT ["catatonit", "/entrypoint.sh"]
