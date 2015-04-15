# building linux-amd64 native binary via Dockerized Go compiler
#
# @see https://registry.hub.docker.com/_/golang/
#

# pull base image
FROM golang:1.4.2
MAINTAINER William Yeh <william.pjyeh@gmail.com>


ENV EXE_NAME         boom_linux-amd64
ENV EXE_STATIC_NAME  boom_static_linux-amd64
ENV PROJECT_URL      github.com/rakyll/boom
#ENV PROJECT_URL      github.com/adjust/go-wrk
#ENV PROJECT_URL      github.com/tsliwowicz/go-wrk
ENV GOPATH    /opt
WORKDIR       /opt


# fetch and compile dynamically-linked version...
RUN  go get -u $PROJECT_URL
RUN  cp $GOPATH/bin/boom  /$EXE_NAME


#--
#    @see Static build method changed in Go 1.4
#         https://github.com/kelseyhightower/rocket-talk/issues/1
#--
RUN  CGO_ENABLED=0  \
     go get -x -a -installsuffix nocgo \
            -u $PROJECT_URL
RUN  cp $GOPATH/bin/boom  /$EXE_STATIC_NAME



# copy executable
RUN    mkdir -p /dist
VOLUME [ "/dist" ]
CMD    cp  /*_linux-amd64  /dist
