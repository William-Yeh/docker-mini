# dockerize `boom`
#
# CAUTION: doesn't work well with "HTTPS";
#          refer to "Dockerfile.correct-version" for canonical answer.
#

FROM scratch

COPY dist/boom_static_linux-amd64  /boom

ENTRYPOINT ["/boom"]