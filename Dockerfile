FROM ubuntu:latest
MAINTAINER = Albert Etsebeth - umbrualbert@gmail.com

# install depedencies from standard repos
RUN apt-get update && apt-get install -y vim tcpdump net-tools build-essential wget libncurses5-dev libpcap-dev libdnet-dev

# install sipp
RUN wget https://github.com/SIPp/sipp/archive/v3.4.1.tar.gz && tar -xf v3.4.1.tar.gz && cd sipp-3.4.1 && ./configure --with-pcap && make && make install

# copy scenarios
COPY scens/* /scens/

# copy run script
COPY run_sipp.sh /
RUN chmod +x /run_sipp.sh

# command to run sipp
CMD ["/bin/bash", "/run_sipp.sh"]

# expose udp port 5060 & 8888
EXPOSE 5060-5069/udp
EXPOSE 8888/udp
EXPOSE 16384-20000/udp

# data
#VOLUME /data

# clean up
RUN rm -r v3.4.1.tar.gz sipp-3.4.1/
