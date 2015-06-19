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

#ADD mongodb.conf /etc/mongodb.conf
#ADD entrypoint /usr/bin/mongo-entrypoint

ENV \
  BUILD_DIR=/tmp/mongobuild \
  ROCKSDB_VERSION=rocksdb-3.11.2 \
  ROCKSDB_PATH=$BUILD_DIR/rocksdb-install \
  MONGO_TOOLS_VERSION="r3.0.4" \
  MONGO_VERSION="3.0.4"  \
  MONGO_BUILD=mongodb-linux-x86_64-${MONGO_VERSION} \
  MONGO_BUILD_DIR=${BUILD_DIR}/${MONGO_BUILD} \
  MONGO_TARBALL=${MONGO_BUILD}.tgz
RUN mkdir -p $BUILD_DIR

RUN curl --location https://github.com/facebook/rocksdb/archive/$ROCKSDB_VERSION.tar.gz | tar xz --directory $BUILD_DIR
WORKDIR $BUILD_DIR/rocksdb-${ROCKSDB_VERSION}
RUN make -j16 release
RUN INSTALL_PATH=${ROCKSDB_PATH} make -j16 install

WORKDIR $BUILD_DIR
RUN git clone --branch v3.0-fb https://github.com/mongodb-partners/mongo
WORKDIR $BUILD_DIR/mongo
RUN scons \
      --extrapath=${ROCKSDB_PATH} \
      --rocksdb=rocksdb --c++11 \
      --disable-minimum-compiler-version-enforcement \
      -j16 \
      --prefix ${MONGO_BUILD_DIR} \
      --variant-dir \
      --release \
      mongod mongo

RUN mkdir -p /var/lib/mongodb && \
    chown 42003 /var/lib/mongodb

VOLUME /var/lib/mongodb
USER 42003
EXPOSE 27017
CMD ["/usr/bin/mongo-entrypoint"]
