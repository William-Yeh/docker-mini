# dockerize `boom`, with certificates.

FROM scratch

COPY dist/boom_static_linux-amd64  /boom
COPY ca-certificates.crt  /etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["/boom", "-allow-insecure"]