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
      scons \
      zlib1g-dev

ENV \
  BUILD_DIR=/tmp/mongobuild \
  GIT_BRANCH="v3.0-fb" \
  ROCKSDB_VERSION=rocksdb-3.11.2 \
  MONGO_TOOLS_VERSION="r3.0.4" \
  MONGO_VERSION="3.0.4"  \
  MONGO_BUILD=mongodb-linux-x86_64-${MONGO_VERSION} \
  MONGO_BUILD_DIR=${BUILD_DIR}/${MONGO_BUILD} \
  MONGO_TARBALL=${MONGO_BUILD}.tgz
RUN mkdir -p ${BUILD_DIR}

RUN curl --location https://github.com/facebook/rocksdb/archive/${ROCKSDB_VERSION}.tar.gz | tar xz --directory ${BUILD_DIR}
WORKDIR ${BUILD_DIR}/rocksdb-${ROCKSDB_VERSION}
RUN make -j16 release
RUN make -j16 install

WORKDIR ${BUILD_DIR}
RUN git clone --branch ${GIT_BRANCH} https://github.com/mongodb-partners/mongo
WORKDIR ${BUILD_DIR}/mongo
RUN scons \
      --rocksdb=rocksdb \
      --c++11 \
      -j16 \      
      --variant-dir \
      --release \
      mongod mongo
RUN tar -pczf ${MONGO_TARBALL} ${MONGO_BUILD}
RUN python buildscripts/packager.py --tarball=${MONGO_TARBALL} -d ubuntu1404 -s ${MONGO_VERSION} -m ${GIT_BRANCH}
