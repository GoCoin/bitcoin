FROM myvbo/cloudserver-48.154
MAINTAINER Scott Spangenberg
RUN sudo apt-get update

# The next line is only required if we want a GUI for bitcoin-qt as well as bitcoind
RUN sudo apt-get install -y libqt4-dev libprotobuf-dev protobuf-compiler
ADD . /home/myvbo/cloudwallets/bitcoin
WORKDIR /home/myvbo/cloudwallets/bitcoin
# create the make and config files appropriate for this environment
RUN ./autogen.sh
#RUN ./configure --enable-hardening --enable-tests=no SSL_CFLAGS=-I/usr/include/openssl LDFLAGS="-static -L/usr/local/BerkeleyDB.4.8/lib -L/usr/lib/x86_64-linux-gnu/ -L/usr/local/boost_1_53_0/lib" CPPFLAGS="-I/usr/local/boost_1_53_0/include -I/usr/local/BerkeleyDB.4.8/include"
#RUN find ./src -type f -exec touch {} ";"
#RUN make install
#RUN mv bitcoind bitcoind_static
RUN ./configure --enable-hardening --enable-tests=yes SSL_CFLAGS=-I/usr/include/openssl LDFLAGS="-L/usr/local/BerkeleyDB.4.8/lib -L/usr/lib/x86_64-linux-gnu/ -L/usr/local/boost_1_53_0/lib" CPPFLAGS="-I/usr/local/boost_1_53_0/include -I/usr/local/BerkeleyDB.4.8/include"
RUN find ./src -type f -exec touch {} ";"
#RUN make clean
RUN make install
RUN make check
