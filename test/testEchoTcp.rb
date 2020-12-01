require '../server/EchoTcp'

listenIP, listenPort = ARGV
listenPort = listenPort.to_i

tcpEcho = TCPEcho.new([listenIP, listenPort])
tcpEcho.start()
sleep(3600)
tcpEcho.stop()
