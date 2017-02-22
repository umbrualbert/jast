# jast - Just another SIP Tester using sipp3.4.1

#Usage
docker run --net=host -dit -e ARGS="-i 192.168.69.72 -mi 192.168.69.72 -mp 16384 -sf /scens/17minutes_G711.xml -inf /scens/2numbers.csv 192.168.69.200:5060 -r 2" --name "sips-client-192.168.69.72-16384" umbrualbert/jast-fixed --cpu 4
docker run --net=host -dit -e ARGS="-i 192.168.100.72 -mi 192.168.100.72 -mp 16384 -rtp_echo -sf /scens/uas.xml " --name "192.168.100.72-16384" umbrualbert/jast-fixed



docker run --net=host -dit -e ARGS="-i 10.10.100.72 -mi 10.10.100.72 -mp 20012 -sf /scens/17minutes_G711.xml -inf /scens/2numbers.csv 192.168.65.2:5061" --name "aweness" umbrualbert/jast-fixed


Load at 10 CPS @ 50% & 50%
docker run --cpu-shares=50 --net=host -dit -e ARGS="-i 192.168.100.72 -p 5060 -mi 192.168.100.72 -mp 16384 -rtp_echo -sf /scens/uas.xml " --name "SIPp" umbrualbert/jast-fixed
docker run --cpu-shares=50 --net=host -dit -e ARGS="-i 192.168.69.72 -mi 192.168.69.72 -mp 19384 -sf /scens/uac.xml 192.168.69.200:5060 -r 100" --name "SIPp-client-192.168.69.72-16384" umbrualbert/jast-fixed


docker run --cpu-shares=50 --net=host -dit -e ARGS="-i 192.168.100.72 -p 5060 -mi 192.168.100.72 -mp 16384 -rtp_echo -sf /scens/uas.xml " --name "SIPp Server 192.168.100.72-16384" umbrualbert/jast-fixed
docker run --cpu-shares=50 --net=host -dit -e ARGS="-i 192.168.69.72 -mi 192.168.69.72 -mp 16384 -sf /scens/17minutes_G711.xml -inf /scens/2numbers.csv 192.168.69.200:5060 -r 2" --name "SIPp-client-192.168.69.72-16384" umbrualbert/jast-fixed

port 5061
docker run --cpu-shares=50 --net=host -dit -e ARGS="-i 192.168.100.72 -p 5061 -mi 192.168.100.72 -mp 17384 -rtp_echo -sf /scens/uas.xml " --name "SIPp Server 192.168.100.72-16384" umbrualbert/jast-fixed
docker run --cpu-shares=50 --net=host -dit -e ARGS="-i 192.168.69.72 -mi 192.168.69.72 -mp 16384 -sf /scens/17minutes_G711.xml -inf /scens/2numbers.csv 192.168.69.200:5061 -r 2" --name "SIPp-client-192.168.69.72-16384" umbrualbert/jast-fixed



docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)

#Services
sudo systemctl start sipp01-scenario-Adv.service
/etc/systemd/system/
