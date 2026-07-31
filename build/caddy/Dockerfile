FROM caddy:2.10.2-builder

ENV GOOS=linux
ENV CGO_ENABLED=0

COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

CMD ["/usr/local/bin/build.sh"]
