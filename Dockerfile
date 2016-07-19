FROM debian:jessie
MAINTAINER Evgeny Zhuravlev <evgeny@zhuravlev.com.ru>
# TODO: alpine + glibc

ENV PREFIX=/usr/local/firebird
ENV DEBIAN_FRONTEND noninteractive

ENV FIREBIRD_VERSION=2.5.5
ENV FIREBIRD_BUILD=26952-0
ENV FIREBIRD_SHA=1b04e30bc5092a6e8d2121ba627f24f6aa40de7d

RUN apt-get update \
    && apt-get install -qy wget bzip2 gcc g++ make libicu-dev libncurses5-dev libicu52 \
    && wget -q "http://downloads.sourceforge.net/project/firebird/firebird/${FIREBIRD_VERSION}-Release/Firebird-${FIREBIRD_VERSION}.${FIREBIRD_BUILD}.tar.bz2" \
    && echo "$FIREBIRD_SHA  Firebird-${FIREBIRD_VERSION}.${FIREBIRD_BUILD}.tar.bz2" | sha1sum -c - \
    && tar xvjf Firebird-${FIREBIRD_VERSION}.${FIREBIRD_BUILD}.tar.bz2 \
    && cd Firebird-${FIREBIRD_VERSION}.${FIREBIRD_BUILD} \
    && ./configure --prefix=${PREFIX} \
        --with-system-icu \
        --enable-superserver \
        --with-fbbin=/usr/bin \
        --with-fbsbin=/usr/sbin \
        --with-fblog=/var/log/firebird \
        --with-fbglock=/var/run/firebird \
        --with-fbconf=/etc/firebird \
        --with-fbsecure-db=/etc/firebird \
        --with-fblib=${PREFIX}/lib \
        --with-fbinclude=${PREFIX}/include \
        --with-fbdoc=${PREFIX}/doc \
        --with-fbudf=${PREFIX}/UDF \
        --with-fbsample=${PREFIX}/examples \
        --with-fbsample-db=${PREFIX}/examples/empbuild \
        --with-fbhelp=${PREFIX}/help \
        --with-fbintl=${PREFIX}/intl \
        --with-fbmisc=${PREFIX}/misc \
        --with-fbplugins=${PREFIX} \
        --with-fbmsg=${PREFIX} \
    # cleanup
    && make clean \
    # make with -j = cpu-cores
    && make -j $(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo) \
    && make silent_install \
    # forward logs to docker log collector
    && ln -sf /dev/stdout /var/log/firebird/firebird.log \
    # set default password FIXME
    && /usr/bin/gsec -user SYSDBA -password $(grep ISC_PASSWD /etc/firebird/SYSDBA.password | awk -F"=" '{print $2}') -modify SYSDBA -pw masterkey \
    && apt-get purge -qy --auto-remove wget bzip2 gcc g++ make libicu-dev libncurses5-dev \
    && apt-get clean -q \
    && rm -rf Firebird-${FIREBIRD_VERSION}.${FIREBIRD_BUILD} ${PREFIX}/*/.debug  /var/lib/apt/lists/*

VOLUME ["/databases", "/tmp/firebird"]

EXPOSE 3050/tcp

ENTRYPOINT ["/usr/sbin/fbguard"]
