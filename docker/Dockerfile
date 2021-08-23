FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

ENV WKHTMLTOX_DEB_PATH /tmp/wkhtmltox_0.12.6-1.bionic_amd64.deb
RUN apt-get update \
  && echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections \
  && apt-get install --yes --no-install-recommends ca-certificates gnupg2 \
  && apt-get install --yes --no-install-recommends perl wget ttf-mscorefonts-installer ghostscript \
  && apt-get install --yes --no-install-recommends libnet-server-perl libplack-perl liblog-dispatch-perl \
    libarchive-zip-perl libcapture-tiny-perl libimage-exiftool-perl libconfig-tiny-perl \
  && wget -O $WKHTMLTOX_DEB_PATH https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb \
  && apt-get install --yes --no-install-recommends --fix-broken $WKHTMLTOX_DEB_PATH \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV HTMLTOPDF_VERSION 3.2.0
RUN useradd -r -c "api conversion html to pdf" -d /opt/htmltopdf -m -s /usr/sbin/nologin htmltopdf \
  && wget -O /tmp/htmltopdf_$HTMLTOPDF_VERSION.tar.gz https://github.com/krpsh123/htmltopdf/archive/refs/tags/$HTMLTOPDF_VERSION.tar.gz \
  && tar -xvzf /tmp/htmltopdf_$HTMLTOPDF_VERSION.tar.gz --strip=1 -C /opt/htmltopdf \
  && chown -R htmltopdf.htmltopdf /opt/htmltopdf

ENV HTMLTOPDF_PORT 50002

COPY container/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE $HTMLTOPDF_PORT

CMD ["htmltopdf"]
