FROM ubuntu:14.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install \
      ca-certificates \
      curl \
      g++ \
      gawk \
      gcc \
      git \
      grep \
      libbz2-dev \
      libgflags-dev \
      libsnappy-dev \
      make \
      python-httplib2 \
      scons \
      zlib1g-dev

# Install Go
RUN \
  mkdir -p /goroot && \
  curl https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar xvzf - -C /goroot --strip-components=1

ENV GOROOT /goroot
ENV GOPATH /gopath
ENV PATH $GOROOT/bin:$GOPATH/bin:$PATH
ENV BUILD_DIR /tmp/mongobuild
ENV GIT_BRANCH v3.0-fb
ENV ROCKSDB_VERSION rocksdb-3.11.2
ENV MONGO_TOOLS_VERSION r3.0.4
ENV MONGO_VERSION 3.0.4
ENV MONGO_ARCH mongodb-linux-x86_64-

#RUN mkdir -p -v ${BUILD_DIR}/${MONGO_ARCH}${MONGO_VERSION}/bin

RUN curl --location https://github.com/facebook/rocksdb/archive/${ROCKSDB_VERSION}.tar.gz | tar xz
WORKDIR rocksdb-${ROCKSDB_VERSION}
RUN make -j16 release
RUN make -j16 install

WORKDIR ${BUILD_DIR}
RUN git clone --branch ${GIT_BRANCH} https://github.com/mongodb-partners/mongo
WORKDIR ${BUILD_DIR}/mongo
RUN git clone --branch ${MONGO_TOOLS_VERSION} https://github.com/mongodb/mongo-tools.git src/mongo-tools-repo
WORKDIR src/mongo-tools-repo/
RUN ./build.sh &&  mv bin/ ../mongo-tools/

WORKDIR ${BUILD_DIR}/mongo
RUN scons \
      --rocksdb=rocksdb \
      --c++11 \
      -j16 \
      --release \
      --use-new-tools \
      dist

#WORKDIR ${BUILD_DIR}
#RUN tar -pczf ${MONGO_ARCH}${MONGO_VERSION}.tgz ${MONGO_ARCH}${MONGO_VERSION}
#WORKDIR ${BUILD_DIR}/mongo/buildscripts
#RUN python packager.py --tarball=${BUILD_DIR}/${MONGO_ARCH}${MONGO_VERSION}.tgz -d ubuntu1404 -s ${MONGO_VERSION} -m ${GIT_BRANCH}
