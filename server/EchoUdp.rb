require 'socket'
require 'pp'

class UDPEcho
  def initialize(listenAddr = ['0.0.0.0', 0])
    @server = UDPSocket.new
    @server.bind(*listenAddr)
    @listenThread = nil
  end

  def getListenAddr()
    port, host = Socket.unpack_sockaddr_in(@server.getsockname)
    return host, port
  end

  def start()
    @listenThread = Thread.new do
      pp getListenAddr().to_s + ' IS LISTENING...'

      loop {
        begin
          request, addr = @server.recvfrom_nonblock(2048)
          peerName = [addr[3], addr[1]]
          pp 'FROM ' + peerName.to_s
          pp request + ' RECEIVED'
          @server.send(request, 0, addr[3], addr[1])
          pp 'TO ' + peerName.to_s
          pp request + ' SENT'
        rescue IO::WaitReadable
          IO.select([@server])
          retry
        end
      }
    end
  end

  def stop()
    @listenThread.stop()
    @server.stop()
  end
end
