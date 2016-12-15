FROM ubuntu:latest
MAINTAINER = Albert Etsebeth - umbrualbert@gmail.com

# install depedencies from standard repos
RUN apt-get update && apt-get install -y tcpdump net-tools build-essential wget libncurses5-dev libpcap-dev libdnet-dev

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
EXPOSE 5060/udp
EXPOSE 8888/udp
EXPOSE 5061/udp
EXPOSE 5062/udp
EXPOSE 5063/udp
EXPOSE 5064/udp
EXPOSE 5064/udp
EXPOSE 5065/udp
EXPOSE 5066/udp
EXPOSE 5067/udp
EXPOSE 5068/udp
EXPOSE 5069/udp

# data
VOLUME /data

# clean up
RUN rm -r v3.4.1.tar.gz sipp-3.4.1/
