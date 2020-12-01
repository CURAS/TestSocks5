require 'socket'
require 'pp'

class Relay
  def initialize(remoteAddr, client, udpSocket)
    @remoteAddr = remoteAddr
    @client = client
    @udpSocket = udpSocket
  end

  def runTCP()
    @remote = TCPSocket.open(*@remoteAddr)
    loop {
      readable, _, _ = IO.select([@client, @remote])
      if readable.include?(@client)
        msg = @client.recv(2048)
        if msg.empty?
          break
        end
        @remote.send(msg, 0)
      end
      if readable.include?(@remote)
        msg = @remote.recv(2048)
        if msg.empty?
          break
        end
        @client.send(msg, 0)
      end
    }
    @remote.close()
  end

  def runUDP()
    @localAddr = nil
    loop {
      readable, _, _ = IO.select([@client, @udpSocket])
      if readable.include?(@client)
        msg = @client.recv(2048)
        if msg.empty?
          break
        end
      end
      if readable.include?(@udpSocket)
        msg, addr = @udpSocket.recvfrom_nonblock(2048)
        if @localAddr == nil
          @localAddr = [addr[3], addr[1]]
        end
        if addr[3] == @localAddr[0] and addr[1] == @localAddr[1]
          @udpSocket.send(msg, 0, *@remoteAddr)
        elsif addr[3] == @remoteAddr[0] and addr[1] == @remoteAddr[1]
          @udpSocket.send(msg, 0, *@localAddr)
        end
      end
    }
  end
end