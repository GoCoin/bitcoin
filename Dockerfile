FROM myvbo/cloudserver-48.154
MAINTAINER Scott Spangenberg
RUN sudo apt-get update

# The next line is only required if we want a GUI for bitcoin-qt as well as bitcoind
ADD . /home/myvbo/cloudwallets/bitcoin
WORKDIR /home/myvbo/cloudwallets/bitcoin
# create the make and config files appropriate for this environment
RUN find ./src -type f -exec touch {} ";"
RUN ./autogen.sh
RUN find ./src -type f -exec touch {} ";"
# commands to build statically linked bitcoind (unit tests ARE NOT possible)
#RUN ./configure --enable-hardening --enable-tests=no SSL_CFLAGS=-I/usr/include/openssl LDFLAGS="-static -L/usr/local/BerkeleyDB.4.8/lib -L/usr/lib/x86_64-linux-gnu/ -L/usr/local/boost_1_53_0/lib" CPPFLAGS="-I/usr/local/boost_1_53_0/include -I/usr/local/BerkeleyDB.4.8/include"
#RUN find ./src -type f -exec touch {} ";"
#RUN make install
#RUN mv bitcoind bitcoind_static
# commands to build dynamically linked bitcoind (unit tests ARE possible)
RUN ./configure --enable-hardening --enable-tests=yes SSL_CFLAGS=-I/usr/include/openssl LDFLAGS="-L/usr/local/BerkeleyDB.4.8/lib -L/usr/lib/x86_64-linux-gnu/ -L/usr/local/boost_1_53_0/lib" CPPFLAGS="-I/usr/local/boost_1_53_0/include -I/usr/local/BerkeleyDB.4.8/include"
RUN find ./src -type f -exec touch {} ";"
#RUN make clean
RUN make install
RUN make check

# CLEAN UP THE EXECUTABLE CODE
# move to root directory and strip out debug info
RUN cp src/bitcoind bitcoind
# Enable the next line to remove debug info from the executable
RUN strip bitcoind

# CLEAN UP THE SOURCE CODE
# copy default config file so we don't lose it when we clean up the source code
#RUN cp contrib/debian/examples/bitcoin.conf bitcoin.conf
# clean source
#RUN rm -r src
#RUN find . -name \*.o -exec rm {} ";"

ENTRYPOINT ["/home/myvbo/cloudwallets/bitcoin/src/bitcoind"]
CMD ["-conf=/coin/bitcoin/bitcoin.conf", "-datadir=/coin/bitcoin"]
EXPOSE 3000
