FROM myvbo/cloudserver-51.154:latest
MAINTAINER Scott Spangenberg

# To build the docker container:
# git clone git@github.com:Ziftr/dogecoin.git dogecoin
# git branch NewRPC
# cp dogecoin.dock dogecoin/Dockerfile && time docker build --rm=true -t myvbo/dogecoin-qt-server:latest dogecoin
# To run the Docker container:
# docker run --rm -t -i --entrypoint="/bin/bash" myvbo/dogecoin-qt-server
# To propagate the binaries for building a minimized server from directory dogecoin_server
# docker run --rm -t -i --entrypoint="/bin/bash" -v ~/myvbo/qtwalletbase/dogecoin_server:/home/myvbo/cloudwallets/serverbinaries myvbo/dogecoin-qt-server
# cp dogecoind test_dogecoin /home/myvbo/cloudwallets/serverbinaries
# cp -r data /home/myvbo/cloudwallets/serverbinaries/data

# Install these GNU utilities to get scanelf so we can confirm hardening of the executable
RUN apt-get -y install pax-utils

ADD . /home/myvbo/cloudwallets/dogecoin
WORKDIR /home/myvbo/cloudwallets/dogecoin
# create the make and config files appropriate for this environment
RUN find . -type f -exec touch {} ";"
RUN ./autogen.sh
RUN ./configure --enable-hardening --enable-tests=yes --without-gui SSL_CFLAGS=-I/usr/include/openssl LDFLAGS="-L/usr/local/BerkeleyDB.5.1/lib -L/usr/lib/x86_64-linux-gnu" CPPFLAGS="-I/usr/local/BerkeleyDB.5.1/include"
#RUN make clean
RUN make
RUN make check

# Confirm hardening of the executables using scanelf
RUN scanelf -e src/dogecoind |grep -E "(TYPE|ET_DYN)"
RUN echo "The lines above must contain TYPE and ET_DYN for position-independent execution."
RUN scanelf -e src/dogecoind |grep -E "(STK/REL/PTL|RW- R-- RW-)"
RUN echo "The lines above must contain STK/REL/PTL and RW- R-- RW- to prevent execution of code on the stack"

# Cleanup
RUN cp src/dogecoind dogecoind
RUN cp src/test/test_dogecoin test_dogecoin
RUN cp -r src/test/data data
# Enable the next line to remove debug info from the executables
RUN strip dogecoind
RUN strip test_dogecoin

# Test
RUN ./test_dogecoin
# Don't test dogecoin-qt if we aren't building dogecoin-qt
#RUN src/qt/test/test_dogecoin-qt

ENTRYPOINT ["/home/myvbo/cloudwallets/dogecoin/dogecoind", "-datadir=/coin/dogecoin"]
CMD ["-conf=/coin/dogecoin/bitcoin.conf"]
EXPOSE 3000
