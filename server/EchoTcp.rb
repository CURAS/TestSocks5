require 'socket'
require 'pp'

class TCPEcho
  def initialize(listenAddr = ['0.0.0.0', 0])
    @server = TCPServer.new(*listenAddr)
    @listenThread = nil
    @clientThreads = []
  end

  def getListenAddr()
    port, host = Socket.unpack_sockaddr_in(@server.getsockname)
    return host, port
  end

  def start()
    @listenThread = Thread.new do
      pp getListenAddr().to_s + ' IS LISTENING...'

      loop {
        @clientThreads << Thread.start(@server.accept) do |client|
          echoProc(client)
        end
      }
    end
  end

  def stop()
    @listenThread.stop()
    @server.stop()
    @clientThreads.each do |clientThread|
      clientThread.stop()
    end
  end

  def echoProc(client)
    port, host = Socket.unpack_sockaddr_in(client.getpeername)
    peerName = [host, port]
    pp peerName.to_s + ' CONNECTED'

    loop {
      request = client.recv(2048)
      if request.empty?
        break
      end
      pp request + ' RECEIVED'
      
      client.send(request, 0)
      pp request + ' SENT'
    }

    client.close
    pp peerName.to_s + ' CLOSED'
  end
end
