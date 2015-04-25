name: inverse
layout: true
class: center, middle, inverse

---

.percent40[.center[![bg](img/squeeze.jpg)]]

# 追求極簡化 Docker image 之路

## Quest for minimal Docker images

???

Img src: http://www.flickr.com/photos/69670601@N05/9262527767
License: CC BY 2.0

---

layout: false
class: middle

# Slides: http://bit.ly/docker-mini

<br/>

## If you want to follow my labs...

```bash
$ git clone https://github.com/William-Yeh/docker-mini.git
$ cd docker-mini
$ vagrant  up
```

---

# Labs in this talk

| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|  01 |  redis  |  `ubuntu`  |   C   | dyn |   347.3
|  02 |  redis  |  `debian`  |   C   | dyn |   305.7
|  03 |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; cmd chaining       |
|  04 |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; docker-squash      |
|  05 |  redis  |  `scratch` |   C   | dyn |    7.73        | &nbsp;&nbsp; rootfs: .so        |
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; ------------------ |
|  11 |  boom   |  `scratch` |  Go   | s   |   6.445
|  12 |  wrk    |  `scratch` |   C   | s   |   1.282        | &nbsp;&nbsp; fail to execute!   |
|  13 |  wrk    |  `scratch` |   C   | dyn |   8.307        | &nbsp;&nbsp; rootfs: .so & conf |



.footnote[.red[*] "dyn": dynamically linked ELF; "s": statically-linked ELF.]


---


template: inverse

# Lab #01
## Images for Redis


---

# Dockerfile

```dockerfile
FROM ubuntu:trusty

ENV VER     3.0.0
ENV TARBALL http://download.redis.io/releases/redis-$VER.tar.gz

# ==> Install curl and helper tools...
RUN apt-get update
RUN apt-get install -y  curl make gcc

# ==> Download, compile, and install...
RUN curl -L $TARBALL | tar zxv
WORKDIR  redis-$VER
RUN make
RUN make install
#...

# ==> Clean up...
WORKDIR /
RUN apt-get remove -y --auto-remove curl make gcc
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*  /redis-$VER

#...
CMD ["redis-server"]
```

---

# Build procedure

```bash
$ docker build  -t redis-01  .
```


---

# Size?

<br/>

| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|  01 |  redis  |  `ubuntu`  |   C   | dyn |   347.3


---

# Seek advices

☛ [Dockerfile Best Practices - take 2](http://crosbymichael.com/dockerfile-best-practices-take-2.html) - by Michael Crosby, 2014-03-09.

--

> 4: **Use small base images**

> Some images are more bloated than others. I suggest using .red[`debian:jessie`] as your base.

--

> If you are coming from ubuntu, you will find a more lightweight and happy home on debian. .red[It's small and does not contain any unneeded bloat.]

---

# All base images aren't created equal...

```
REPOSITORY          TAG        IMAGE ID         VIRTUAL SIZE
---------------     ------     ------------     ------------
centos              7          214a4932132a     215.7 MB
centos              6          f6808a3e4d9e     202.6 MB
ubuntu              trusty     d0955f21bf24     188.3 MB
ubuntu              precise    9c5e4be642b7     131.9 MB
*debian              jessie     65688f7c61c4     122.8 MB
debian              wheezy     1265e16d0c28     84.96 MB
```

---

template: inverse

# Lab #02
## Change base image:<br/>"ubuntu" to "debian:jessie"


---

# Dockerfile

```dockerfile
*FROM debian:jessie

ENV VER     3.0.0
ENV TARBALL http://download.redis.io/releases/redis-$VER.tar.gz

# ==> Install curl and helper tools...
RUN apt-get update
RUN apt-get install -y  curl make gcc

# ==> Download, compile, and install...
RUN curl -L $TARBALL | tar zxv
WORKDIR  redis-$VER
RUN make
RUN make install
#...

# ==> Clean up...
WORKDIR /
RUN apt-get remove -y --auto-remove curl make gcc
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*  /redis-$VER

#...
CMD ["redis-server"]
```

---

# Build procedure

```bash
$ docker build  -t redis-02  .
```

---

# Size?

<br/>

| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|  01 |  redis  |  `ubuntu`  |   C   | dyn |   347.3
|  02 |  redis  |  `debian`  |   C   | dyn |   305.7

--
<br/>
Overhead?

- Too large... 305.7 MB vs. 122.8 MB

```
REPOSITORY          TAG        IMAGE ID         VIRTUAL SIZE
---------------     ------     ------------     ------------
*debian              jessie     65688f7c61c4     122.8 MB
```

---

# Seek advices

☛ [Optimizing Docker Images](http://www.centurylinklabs.com/optimizing-docker-images/) - by Brian DeHamer, 2014-07-28.

> [Why]

> **Each additional instruction in your `Dockerfile` will only ever increase the overall size of your image.**

--

<br/>

```bash
$ docker history redis-02
```


---

# Analogy: git

<br/>

```bash
$ git add  A_VERY_LARGE_FILE
$ git commit


$ git rm  A_VERY_LARGE_FILE
$ git commit
```

Is the `A_VERY_LARGE_FILE` still in the git repo?

---

# Seek advices (continued)

☛ [Optimizing Docker Images](http://www.centurylinklabs.com/optimizing-docker-images/) - by Brian DeHamer, 2014-07-28.

> [How]

> .red[**Chain Your Commands**]

> Instead of executing each command as a separate `RUN` instruction we've .red[chained them all together in a single line using the `&&` operator.]


---

template: inverse

# Lab #03
## Chain commands in Dockerfile


---

# Dockerfile

```dockerfile
FROM debian:jessie

ENV VER     3.0.0
ENV TARBALL http://download.redis.io/releases/redis-$VER.tar.gz


RUN echo "==> Install curl and helper tools..."  && \
    apt-get update                      && \
    apt-get install -y  curl make gcc   && \
    \
    echo "==> Download, compile, and install..."  && \
    curl -L $TARBALL | tar zxv  && \
    cd redis-$VER               && \
    make                        && \
    make install                && \
    ...
    echo "==> Clean up..."  && \
    apt-get remove -y --auto-remove curl make gcc  && \
    apt-get clean                                  && \
    rm -rf /var/lib/apt/lists/*  /redis-$VER

#...
CMD ["redis-server"]
```

---

# Build procedure

```bash
$ docker build  -t redis-03  .
```

---

# Size?

<br/>

| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|  01 |  redis  |  `ubuntu`  |   C   | dyn |   347.3
|  02 |  redis  |  `debian`  |   C   | dyn |   305.7
|  03 |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; cmd chaining       |

--
<br/>
Overhead?

- Much better... 151.4 MB vs. 122.8 MB

```
REPOSITORY          TAG        IMAGE ID         VIRTUAL SIZE
---------------     ------     ------------     ------------
*debian              jessie     65688f7c61c4     122.8 MB
```



---

# Seek advices

☛ [Squashing Docker Images](http://jasonwilder.com/blog/2014/08/19/squashing-docker-images/) - by Jason Wilder, 2014-08-19.


> `docker-squashis` a standalone Go application that works similarly to the idea described in [332 (a flatten images proposal)](https://github.com/docker/docker/issues/332).

> It’s intended to be used as a publishing tool in your workflow and would be run before pushing to a registry.

---

template: inverse

# Lab #04
## docker-squash

.footnote[https://github.com/jwilder/docker-squash]


---

# Dockerfile

The same as lab-03.


---

# Build procedure

```bash
$ docker save redis-03                  \
    | sudo ./docker-squash -t redis-04  \
    | docker load
```


---

# Size?

No improvements...

| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|  01 |  redis  |  `ubuntu`  |   C   | dyn |   347.3
|  02 |  redis  |  `debian`  |   C   | dyn |   305.7
|  03 |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; cmd chaining       |
|  04 |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; docker-squash      |


---

class: center, middle

# Good Enough???

---

# What's the secret?


```
REPOSITORY          TAG        IMAGE ID         VIRTUAL SIZE
---------------     ------     ------------     ------------
google/cadvisor     0.10.1     6a46ed29e869     18.03  MB
google/cadvisor     latest     6a46ed29e869     18.03  MB

swarm               latest     bf8b6923851d      7.19  MB

zettio/weavetools   0.9.0      6c2dd751b59c      5.138 MB
zettio/weavedns     0.9.0      8f3a856eda8f      9.382 MB
zettio/weave        0.9.0      efb52cb2a3b8     11.35  MB

progrium/busybox    latest     8cee90767cfe      4.785 MB
busybox             latest     4986bf8c1536      2.43  MB

```



---

# Seek advices


☛ Minimalism examples:

- Go:

  - [Create the smallest possible Docker container](http://blog.xebia.com/2014/07/04/create-the-smallest-possible-docker-container/)
  - [Small Docker Images For Go Apps](http://www.centurylinklabs.com/small-docker-images-for-go-apps/) (with [golang-builder](https://github.com/CenturyLinkLabs/golang-builder))
  - [Building Docker Images for Static Go Binaries](https://medium.com/@kelseyhightower/optimizing-docker-images-for-static-binaries-b5696e26eb07)

- ELF: [Creating minimal Docker images from dynamically linked ELF binaries](http://blog.oddbit.com/2015/02/05/creating-minimal-docker-images/)

- Python: [Creating super small docker images](http://yasermartinez.com/blog/posts/creating-super-small-docker-images.html)

- Java:

  - [Running Java applications in Docker containers](http://weaveblog.com/2014/12/09/running-java-applications-in-docker-containers/)
  - [Minimal Docker image with Java](https://github.com/jeanblanchard/docker-busybox-java/)

---

# TL;DR

- Use `scratch` or `busybox` as base images.

- Use a compiler that can generate static native ELF files (e.g., C, C++, Go).

- Consider the price/performance ratio...

--

  - ...worth it?

```
  REPOSITORY                   TAG        IMAGE ID         VIRTUAL SIZE
  --------------------------   ------     ------------     ------------
  jeanblanchard/busybox-java   latest     f9b532dbdd9f     162 MB
  jeanblanchard/busybox-java   7          e5ad718ab499     146.5 MB
  jeanblanchard/busybox-java   jdk7       49f89f582b82     147.6 MB
  jeanblanchard/busybox-java   jdk8       778cb8b6fb46     163.8 MB
  errordeveloper/oracle-jdk    latest     589353b8b10d     303.6 MB
  errordeveloper/oracle-jre    latest     183e41fe6d99     159.4 MB
```


---

template: inverse

# Lab #05
## Extract dynamically-linked .so files

---

# Context in this lab

<br/>

```bash
$ cat /etc/os-release
```
```
NAME="Ubuntu"
VERSION="14.04.2 LTS, Trusty Tahr"
...
```

<br/>

```bash
$ uname -a
```
```
Linux localhost 3.13.0-46-generic #77-Ubuntu SMP
Mon Mar 2 18:23:39 UTC 2015
x86_64 x86_64 x86_64 GNU/Linux
```

.footnote[.red[*] Vagrant box: [ubuntu/trusty64](https://atlas.hashicorp.com/ubuntu/boxes/trusty64)]

---


# Investigate required .so files

`ldd` - print shared library dependencies.

```bash
$ ldd  redis-3.0.0/src/redis-server
    linux-vdso.so.1 =>  (0x00007fffde365000)
    libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f307d5aa000)
    libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f307d38c000)
    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f307cfc6000)
    /lib64/ld-linux-x86-64.so.2 (0x00007f307d8b9000)
```

--
<br/>

vDSO (virtual dynamic shared object):

> a way to export **kernel space routines** to **user space** applications, using standard mechanisms for linking and loading i.e. standard Executable and Linkable Format (ELF) format.  --- Quote [Wikipedia](http://en.wikipedia.org/wiki/VDSO)

---

# Pack all required .so files into a tarball...

```bash
$ tar ztvf rootfs.tar.gz

4485167  2015-04-21 22:54  usr/local/bin/redis-server
1071552  2015-02-25 16:56  lib/x86_64-linux-gnu/libm.so.6
 141574  2015-02-25 16:56  lib/x86_64-linux-gnu/libpthread.so.0
1840928  2015-02-25 16:56  lib/x86_64-linux-gnu/libc.so.6
 149120  2015-02-25 16:56  lib64/ld-linux-x86-64.so.2
```

---

# Dockerfile

```dockerfile
FROM scratch

ADD  rootfs.tar.gz  /
COPY redis.conf     /etc/redis/redis.conf


EXPOSE 6379

CMD ["redis-server"]
```

---

# Build procedure

```bash
$ docker build  -t redis-05  .
```


---

# Size?

BIG improvements!!!

| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|  01 |  redis  |  `ubuntu`  |   C   | dyn |   347.3
|  02 |  redis  |  `debian`  |   C   | dyn |   305.7
|  03 |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; cmd chaining       |
|  04 |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; docker-squash      |
|  05 |  redis  |  `scratch` |   C   | dyn |    7.73        | &nbsp;&nbsp; rootfs: .so        |


---

# Test it...

```bash
$ docker run -d --name redis-05 redis-05

$ redis-cli  -h  \
  $(docker inspect -f '{{.NetworkSettings.IPAddress}}' redis-05)

$ redis-benchmark  -h  \
  $(docker inspect -f '{{.NetworkSettings.IPAddress}}' redis-05)
```


---

# Lessons Learned

- Investigate required .so files with `ldd`.

- Pack all dependencies into a `rootfs.tar` or `rootfs.tar.gz` to be put into the `scratch` base image.

---

# About the `scratch`

- Before Docker 1.5.0, it is the root image `511136ea3c5a` in the whole Docker image layer hierarchy.

--

- As of Docker 1.5.0:

  > `FROM scratch` is a no-op in the `Dockerfile`, and will not create an extra layer in your image (so a previously 2-layer image will now be a 1-layer image instead).  &nbsp;&nbsp; --- Quote: [scratch in Docker Hub](https://registry.hub.docker.com/_/scratch/)

  > Goodbye '511136ea3c5a64f264b78b5433614aec<br/>563103b4d4702f3ba7d4d2698e22c158',<br/>
it was nice knowing you.  &nbsp;&nbsp; --- Quote: [Make `FROM scratch` a special cased 'no-base' spec](https://github.com/docker/docker/pull/8827)

---

class: center, middle

# ~~The End?~~

--

## How about other OS?

... For example, CentOS 7.0?

---

# Context, Part 2

<br/>

```bash
$ cat /etc/redhat-release
```
```
CentOS Linux release 7.0.1406 (Core)
```

<br/>

```bash
$ uname -a
```
```
Linux localhost.localdomain 3.10.0-123.el7.x86_64 #1 SMP
Mon Jun 30 12:09:22 UTC 2014
x86_64 x86_64 x86_64 GNU/Linux
```

.footnote[.red[*] Vagrant box: [chef/centos-7.0](https://atlas.hashicorp.com/chef/boxes/centos-7.0)]

---


# Investigate required .so files

`ldd` - print shared library dependencies.

```bash
$ ldd  redis-3.0.0/src/redis-server
    linux-vdso.so.1 =>  (0x00007fffe5d0d000)
    libm.so.6 => /lib64/libm.so.6 (0x00007f0ad8d01000)
    libpthread.so.0 => /lib64/libpthread.so.0 (0x00007f0ad8ae5000)
    libc.so.6 => /lib64/libc.so.6 (0x00007f0ad8723000)
    /lib64/ld-linux-x86-64.so.2 (0x00007f0ad900a000)
```

---

# Pack all required .so files into a tarball...

```bash
$ tar ztvf rootfs.tar.gz

4485167  2015-04-21 22:54  usr/local/bin/redis-server
1141552  2015-03-05 21:50  lib64/libm.so.6
 141616  2015-03-05 21:50  lib64/libpthread.so.0
2107760  2015-03-05 21:50  lib64/libc.so.6
 164336  2015-03-05 21:50  lib64/ld-linux-x86-64.so.2
```

---

# Compare!

- from Ubuntu 14.04.2

```bash
4485167  2015-04-21 22:54  usr/local/bin/redis-server
1071552  2015-02-25 16:56  lib/x86_64-linux-gnu/libm.so.6
 141574  2015-02-25 16:56  lib/x86_64-linux-gnu/libpthread.so.0
1840928  2015-02-25 16:56  lib/x86_64-linux-gnu/libc.so.6
 149120  2015-02-25 16:56  lib64/ld-linux-x86-64.so.2
```


- from CentOS 7.0

```bash
4485167  2015-04-21 22:54  usr/local/bin/redis-server
1141552  2015-03-05 21:50  lib64/libm.so.6
 141616  2015-03-05 21:50  lib64/libpthread.so.0
2107760  2015-03-05 21:50  lib64/libc.so.6
 164336  2015-03-05 21:50  lib64/ld-linux-x86-64.so.2
```


---

# How to: Pin a version?

--

- Basic idea

  - Pin a specific OS version

--

  - ... together with packages and other runtime configurations

--

- Workflow

  - Use CI to drive pinned virtual environments

--

  - Old example: [Make CI easier with Jenkins CI and Vagrant](http://www.larrycaiyu.com/blog/2011/10/21/make-ci-easier-with-jenkins-ci-and-vagrant/)

--

  - Fashion example: CI + Docker!

---

# CI + Docker?

--

`.travis.yml` &nbsp;&nbsp; [![Travis CI - Build Status](https://travis-ci.org/William-Yeh/docker-mini.svg?branch=master)](https://travis-ci.org/William-Yeh/docker-mini)


```yaml
install:
  - curl -sLo - http://j.mp/install-travis-docker | sh -xe

script:
  - echo "==> [lab-05] Clean up rootfs.tar.gz in advance..."
  - rm  lab-05/rootfs.tar.gz  lab-05/redis.conf

  - echo "==> [lab-05] Generating rootfs.tar.gz ..."
  - ./run 'docker build -t rootfs
                  -f lab-05/Dockerfile.rootfs  lab-05
       &&  docker run -v $(pwd)/lab-05:/data  rootfs'

  - echo "==> [lab-05] Inspecting the newly-generated rootfs.tar.gz ..."
  - tar ztvf lab-05/rootfs.tar.gz

  - echo "==> [lab-05] Building the main Docker image..."
  - ./run docker build lab-05
```

.footnote[.red[*] [moul/travis-docker](https://github.com/moul/travis-docker/): Run Docker in Travis CI builds.]

---

# Lessons Learned (revised)

### Basic

- Investigate required .so files with `ldd`.

- Pack all dependencies into a `rootfs.tar` or `rootfs.tar.gz` to be put into the `scratch` base image.

### Advanced

- Use `Dockerfile` to pin specific versions of OS, packages, and other runtime configurations.

- Use CI to automate the whole workflow.

---

class: center, middle

# ~~The End?~~

--

Exceptions?

---

class: center, middle

# The Devil is in the detail...

---

template: inverse

# Lab #11
## Go programs that require DNS lookup


### boom: [github.com/rakyll/boom](https://github.com/rakyll/boom)


---

# About the `boom`

- Source: [github.com/rakyll/boom](https://github.com/rakyll/boom)

- "HTTP(S) load generator, ApacheBench ([ab](http://httpd.apache.org/docs/2.2/programs/ab.html)) replacement, written in Go."

--

<br/>
- "Boom is originally written by Tarek Ziade in Python and is available on [tarekziade/boom](https://github.com/tarekziade/boom). But, due to its dependency requirements and my personal annoyance of maintaining concurrent programs in Python, I decided to rewrite it in Go."

---

# Investigate required .so files

`ldd` - print shared library dependencies.

```bash
$ ldd  dist/boom_linux-amd64
    linux-vdso.so.1 =>  (0x00007fff6a5d7000)
    libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fcad4f1f000)
    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fcad4b5a000)
    /lib64/ld-linux-x86-64.so.2 (0x00007fcad5146000)


$ ldd  dist/boom_static_linux-amd64
    not a dynamic executable
```



.footnote[.red[*] See `compile.sh` for more details about these ELF executables.]

---

# Dockerfile

```dockerfile
FROM scratch

COPY dist/boom_static_linux-amd64  /boom

ENTRYPOINT ["/boom"]
```

---

# Build procedure

```bash
$ docker build  -t boom-11  .
```


---

# Size?

Perfect!


| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|  11 |  boom   |  `scratch` |  Go   | s   |   6.445


---

# Test it...

- HTTP

  ```bash
  $ docker run  boom-11  http://www.whatip.com/

  ```

--

- HTTPS

  ```bash
  $ docker run  boom-11  https://www.google.com/
    ...
    [200] Get https://173.194.72.99/:
  *    x509: failed to load system roots and no roots provided
  ```

  Ouch!

---

# Lessons Learned

- Go is awesome!

- Certificate file (`/etc/ssl/certs/ca-certificates.crt`) for HTTPS connections
  - May need to update certificate database in advance (e.g., `sudo update-ca-certificates` in Debian/Ubuntu).

--

- You may try `Dockerfile.correct-version` in this lab directory.

<br/><br/>
References:

  - [Small Docker Images For Go Apps](http://www.centurylinklabs.com/small-docker-images-for-go-apps/) (with [golang-builder](https://github.com/CenturyLinkLabs/golang-builder))
  - [Building Docker Images for Static Go Binaries](https://medium.com/@kelseyhightower/optimizing-docker-images-for-static-binaries-b5696e26eb07)


---

class: center, middle

# Go is awesome.
# How about our old friend C?

---

template: inverse

# Lab #12
## C programs that require DNS lookup

#### (statically linked)

### wrk: https://github.com/wg/wrk


---

# About the `wrk`

- Source: https://github.com/wg/wrk

- Written in C.

- "Modern HTTP benchmarking tool"

- We use an old version [1.0.0](https://github.com/wg/wrk/tree/1.0.0) here for simplicity.

---

# Investigate required .so files

`ldd` - print shared library dependencies.

```bash
$ ldd  wrk_linux-amd64
    not a dynamic executable
```


.footnote[.red[*] See `compile.sh` for more details about how I hack the `Makefile` to build a static ELF executable.]

---

# Dockerfile

```dockerfile
FROM scratch

COPY wrk_linux-amd64  /wrk

ENTRYPOINT ["/wrk"]
```

---

# Build procedure

```bash
$ docker build  -t wrk-12  .
```


---

# Size?

Perfect!

| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|  11 |  boom   |  `scratch` |  Go   | s   |   6.445
|  12 |  wrk    |  `scratch` |   C   | s   |   1.282

---

# Test it...

- HTTP with domain name

  ```bash
  $ docker run  wrk-12  http://www.whatip.com/

  *unable to resolve www.whatip.com:
      http Servname not supported for ai_socktype
  ```

  Ouch!

--

- HTTP with IP address

  ```bash
  $ docker run  wrk-12  http://80.92.84.167/

  *unable to resolve 80.92.84.167:
      http Servname not supported for ai_socktype
  ```

  Ouch!

---

class: center, middle

# Why?

---

# Warning while compiling...

<br/>

```bash
cc -pthread -static -static-libgcc -o wrk obj/wrk.o ...
```
```
obj/wrk.o: In function `main':

    wrk.c:(.text.startup+0x27b): warning:
*        Using 'getaddrinfo' in statically linked applications
*        requires at runtime the shared libraries
*        from the glibc version used for linking
```

--

<br/>

### What the hxxl is this?

---

# Stack Overflow says...


> **glibc** uses **.red[libnss]** to support a number of different providers for *address resolution services*.

> Unfortunately, you cannot statically link **.red[libnss]**, as exactly what providers it loads depends on the local system's configuration.


.footnote[.red[*] See: [Create statically-linked binary that uses `getaddrinfo`?](http://stackoverflow.com/questions/2725255/create-statically-linked-binary-that-uses-getaddrinfo)]

---

# The GNU C Library: Name Service Switch (NSS)

> The basic idea is to put the implementation of the different services offered to access the databases in separate modules.

> The databases available in the NSS are: `aliases`, `ethers`, `group`, `hosts`, `netgroup`, `networks`, `protocols`, `passwd`, `rpc`, `services`, `shadow`.


.footnote[.red[*] See: [System Databases and Name Service Switch](http://www.gnu.org/software/libc/manual/html_node/Name-Service-Switch.html)]

---

# TL;DR

`wrk` needs the following NSS stuff (under Ubuntu 14.04) .red[*] :

- .so files

  ```
  /lib/x86_64-linux-gnu/libresolv.so.2
  /usr/lib/libdns.so.100
  /lib/x86_64-linux-gnu/libnss_dns.so.2
  /lib/x86_64-linux-gnu/libnss_files.so.2
  /lib/x86_64-linux-gnu/libnss_myhostname.so.2
  ```

- config files

  ```
  /etc/nsswitch.conf
  /etc/services
  ```


.footnote[.red[*] May vary on other Linux distributions and versions.]


---

# Lessons Learned

- C is ~~awesome~~ painful!

- Any more dark corners?

- Isn't worth the effort making it static...

---

template: inverse

# Lab #13
## C programs that require DNS lookup <br/> [... revised]

#### (dynamically linked)

### wrk: https://github.com/wg/wrk

---

class: center, middle

# This time, dynamically-linked C program, with NSS stuff.

---

# Investigate required .so files

`ldd` - print shared library dependencies.

```bash
$ ldd  wrk_linux-amd64
    linux-vdso.so.1 =>  (0x00007fff7d5b8000)
    libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f8be5e6f000)
    libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f8be5c51000)
    libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f8be588b000)
    /lib64/ld-linux-x86-64.so.2 (0x00007f8be617e000)
```


.footnote[.red[*] See `compile.sh` for more details about the ELF executable.]

---

# Pack all required NSS files into a tarball...

```bash
$ tar ztvf rootfs.tar.gz

  47710  2015-04-14 08:14  usr/local/bin/wrk_linux-amd64
 101240  2015-02-25 16:56  lib/x86_64-linux-gnu/libresolv.so.2
1908208  2015-02-18 13:45  usr/lib/libdns.so.100
  22952  2015-02-25 16:56  lib/x86_64-linux-gnu/libnss_dns.so.2
  47712  2015-02-25 16:56  lib/x86_64-linux-gnu/libnss_files.so.2
  14416  2013-06-20 17:34  lib/x86_64-linux-gnu/libnss_myhostname.so.2
    486  2015-03-09 07:19  etc/nsswitch.conf
  19558  2013-12-30 11:08  etc/services
1071552  2015-02-25 16:56  lib/x86_64-linux-gnu/libm.so.6
 141574  2015-02-25 16:56  lib/x86_64-linux-gnu/libpthread.so.0
1840928  2015-02-25 16:56  lib/x86_64-linux-gnu/libc.so.6
 149120  2015-02-25 16:56  lib64/ld-linux-x86-64.so.2
```


.footnote[.red[*] See `build-rootfs.sh` for more details about the tarball generation, extracted under Ubuntu 14.04.]

---

# Dockerfile

```dockerfile
FROM scratch

ADD  rootfs.tar.gz  /

ENTRYPOINT ["usr/local/bin/wrk_linux-amd64"]
```

---

# Build procedure

```bash
$ docker build  -t wrk-13  .
```


---

# Size?

Perfect!

| Lab |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|:---:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
| --- | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; ------------------ |
|  11 |  boom   |  `scratch` |  Go   | s   |   6.445
|  12 |  wrk    |  `scratch` |   C   | s   |   1.282        | &nbsp;&nbsp; fail to execute!   |
|  13 |  wrk    |  `scratch` |   C   | dyn |   8.307        | &nbsp;&nbsp; rootfs: .so & conf |

---

# Test it...

- HTTP

  ```bash
  $ docker run  wrk-13  http://www.whatip.com/

  ```

- HTTPS

  ```bash
  $ docker run  wrk-13  https://www.google.com/
  ```

---

# Lessons Learned

- Even C *claims* to be able to generate statically linked ELF files, dark corners do exist.

--

- Let along dynamically loaded application-level modules, such as [Apache Portable Runtime (APR)](https://apr.apache.org/).

  - See how I fight with APR in Dockerizing Ganglia: [Docker-Ganglia-Monitor-Mini
](https://github.com/William-Yeh/Docker-Ganglia-Monitor-Mini).


---

template: inverse


.percent60[.center[![bg](img/shameless-plug.png)]]

# Shameless Plug

???

Img src: http://pixshark.com/shameless-logo.htm


---

# extract-elf-so

Extract .so files from specified ELF executables, <br/>and pack them in a tarball.

Written in Go.

.footnote[https://github.com/William-Yeh/extract-elf-so]


---

# extract-elf-so

```
Extract .so files from specified ELF executables, and pack them in a tarball.

Usage:
  extract-elf-so  [options]  [(--add <so_file>)...]  <elf_files>...
  extract-elf-so  --help
  extract-elf-so  --version

Options:
  -d <dir>, --dest <dir>          Destination dir in the tarball to place the elf_files;
                                    [default: /usr/local/bin].
  -n <name>, --name <name>        Generated tarball filename (without .gz/.tar.gz);
                                    [default: rootfs].
  -a <so_file>, --add <so_file>   Additional .so files to be appended into the tarball.
  -s <so_dir>, --sodir <so_dir>   Directory in the tarball to place additional .so files;
                                    [default: /usr/lib].
  -z                              Compress the output tarball using gzip.
  --nss-net                       Install networking stuff of NSS;  [default: false].
  --cert                          Install necessary root CA certificates;  [default: false].
```



---


# Base image: scratch + xxSH ?

A few tiny *wrapper scripts* in the minimal image can be convenient...


--

```
REPOSITORY              TAG        VIRTUAL SIZE    LICENSE
---------------         ------     ------------    -------
williamyeh/busybox-sh   latest     1.007 MB        GPLv2
williamyeh/dash         latest     1.352 MB        BSD
busybox                 latest     2.43 MB         GPLv2
progrium/busybox        latest     4.785 MB        GPLv2
alpine                  3.1        5.025 MB        GPLv2
```

--

<br/>
Note:

- BusyBox is GPLv2, so is derived work such as Alpine.

- [`williamyeh/busybox-sh`](https://registry.hub.docker.com/u/williamyeh/busybox-sh/) provides HUSH grammar parser.

- [`williamyeh/dash`](https://registry.hub.docker.com/u/williamyeh/dash/) provides DASH (“the Debian Almquist Shell”).

---

# TODO

- Use [ToyBox](http://en.wikipedia.org/wiki/Toybox) (BSD license) to replace BusyBox (GPLv2).

--

- [`williamyeh/dash`](https://registry.hub.docker.com/u/williamyeh/dash/) + ToyBox!


---

template: inverse

# Conclusion

---


| Lab &nbsp;&nbsp;        |         | Base       | PL    | .red[*] |  Size (MB) | &nbsp;&nbsp; Memo               |
|------------------------:|:--------|:-----------|:-----:|:---:|---------------:|:--------------------------------|
|       --- &nbsp;&nbsp;  | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; -------------------|
|        01 &nbsp;&nbsp;  |  redis  |  `ubuntu`  |   C   | dyn |   347.3
|        02 &nbsp;&nbsp;  |  redis  |  `debian`  |   C   | dyn |   305.7
|        03 &nbsp;&nbsp;  |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; cmd chaining       |
|        04 &nbsp;&nbsp;  |  redis  |  `debian`  |   C   | dyn |   151.4        | &nbsp;&nbsp; docker-squash      |
| .red[☛] 05 &nbsp;&nbsp; |  redis  |  .red[`scratch`] |   .red[C]   | .red[dyn] |    7.73        | &nbsp;&nbsp; .red[rootfs: .so]        |
|       --- &nbsp;&nbsp;  | ------- | ---------- | ----- | --- | -------------- | &nbsp;&nbsp; ------------------ |
| .red[☛] 11 &nbsp;&nbsp; |  boom   |  .red[`scratch`] |  .red[Go]   | .red[s]   |   6.445
|        12 &nbsp;&nbsp;  |  wrk    |  `scratch` |   C   | s   |   1.282        | &nbsp;&nbsp; fail to execute!   |
| .red[☛] 13 &nbsp;&nbsp; |  wrk    |  .red[`scratch`] |   .red[C]   | .red[dyn] |   8.307        | &nbsp;&nbsp; .red[rootfs: .so & conf] |



.footnote[.red[*] "dyn": dynamically linked ELF; "s": statically-linked ELF.]


---

class: center, middle

# The End
