require '../server/EchoUdp'

listenIP, listenPort = ARGV
listenPort = listenPort.to_i

udpEcho = UDPEcho.new([listenIP, listenPort])
udpEcho.start()
sleep(3600)
udpEcho.stop()
