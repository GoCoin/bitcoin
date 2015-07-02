FROM myvbo/cloudserver-48.154:latest
MAINTAINER Scott Spangenberg

# To build the docker container:
# git clone git@github.com:Ziftr/bitcoin.git bitcoin
# git branch NewRPC
# cp bitcoin.dock bitcoin/Dockerfile && time docker build --rm=true -t myvbo/bitcoin-qt-server:latest bitcoin
# To run the Docker container:
# docker run --rm -t -i --entrypoint="/bin/bash" myvbo/bitcoin-qt-server:test
# To propagate the binaries for building a minimized server from directory bitcoin_server
# docker run --rm -t -i --entrypoint="/bin/bash" -v ~/myvbo/qtwalletbase/bitcoin_server:/home/myvbo/cloudwallets/serverbinaries myvbo/bitcoin-qt-server:test
# cp bitcoind test_bitcoin /home/myvbo/cloudwallets/serverbinaries
# cp -r data /home/myvbo/cloudwallets/serverbinaries/data

# Install these GNU utilities to get scanelf so we can confirm hardening of the executable
RUN apt-get -y install pax-utils

ADD . /home/myvbo/cloudwallets/bitcoin
WORKDIR /home/myvbo/cloudwallets/bitcoin
# create the make and config files appropriate for this environment
RUN find . -type f -exec touch {} ";"
RUN ./autogen.sh
# commands to build dynamically linked bitcoind (unit tests ARE possible)
RUN ./configure --enable-hardening --enable-tests=yes --without-gui SSL_CFLAGS=-I/usr/include/openssl LDFLAGS="-Wl,--no-as-needed -ldl -L/usr/local/BerkeleyDB.4.8/lib -L/usr/local/boost_1_54_0/lib  -L/usr/lib/x86_64-linux-gnu" CPPFLAGS="-I/usr/local/boost_1_54_0/include -I/usr/local/BerkeleyDB.4.8/include  -ffunction-sections -fdata-sections -fPIC"
RUN find ./src -type f -exec touch {} ";"
RUN make install
RUN make check

# Confirm hardening of the executables using scanelf
RUN scanelf -e src/bitcoind |grep -E "(TYPE|ET_DYN)"
RUN echo "The lines above must contain TYPE and ET_DYN for position-independent execution."
RUN scanelf -e src/bitcoind |grep -E "(STK/REL/PTL|RW- R-- RW-)"
RUN echo "The lines above must contain STK/REL/PTL and RW- R-- RW- to prevent execution of code on the stack"
RUN scanelf -e src/bitcoin-cli |grep -E "(TYPE|ET_DYN)"
RUN echo "The lines above must contain TYPE and ET_DYN for position-independent execution."
RUN scanelf -e src/bitcoin-cli |grep -E "(STK/REL/PTL|RW- R-- RW-)"
RUN echo "The lines above must contain STK/REL/PTL and RW- R-- RW- to prevent execution of code on the stack"

# Cleanup
RUN cp src/bitcoind bitcoind
RUN cp src/test/test_bitcoin test_bitcoin
RUN cp -r src/test/data data
# Enable the next line to remove debug info from the executables
RUN strip bitcoind
RUN strip test_bitcoin

# Test
RUN src/test/test_bitcoin
# Don't test bitcoin-qt if we aren't building bitcoin-qt
#RUN src/qt/test/test_bitcoin-qt

ENTRYPOINT ["/home/myvbo/cloudwallets/bitcoin/bitcoind"]
CMD ["-conf=/coin/bitcoin/bitcoin.conf", "-datadir=/coin/bitcoin"]
EXPOSE 3000
