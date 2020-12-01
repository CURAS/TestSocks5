require 'socket'
require 'pp'
require './server/Parser'
require './server/Relay'

server = TCPServer.open('0.0.0.0', 1800)
loop {
  Thread.start(server.accept) do |client|
    begin
      methodPayload = client.recv(2048)
      methods, err = Socks5Parse.parseMethodPayload(methodPayload)
      if err and err.start_with?("Error") then
        raise err
      elsif err
        pp err
      end

      methodPayloadResponse, err = Socks5Parse.makeMethodPayload(methods)
      if err then
        raise err
      end
      client.send(methodPayloadResponse, 0)

      requestPayload = client.recv(2048)
      request, err = Socks5Parse.parseRequestPayload(requestPayload)
      if err then
        raise err
      end

      udpSocket = nil
      remoteAddr = [request[2], request[3]]
      pp "Request" + remoteAddr.to_s

      responseAtyp = nil
      responseAddr = []
      case request[0]
      when 0x01 # TCP Client
        responseAtyp = request[1]
        responseAddr = remoteAddr
      when 0x03 # UDP
        _, listenAddr = Socket.unpack_sockaddr_in(client.getsockname())
        udpSocket = UDPSocket.new()
        udpSocket.bind(listenAddr, 0)
        port, host = Socket.unpack_sockaddr_in(udpSocket.getsockname())
        responseAtyp = 0x01
        responseAddr = [host, port]
      else
        raise 'Error: Unsupported Command'
      end
      
      responsePayload = Socks5Parse.makeResponsePayload(0x00, responseAtyp, *responseAddr)
      if err then
        raise err
      end
      client.send(responsePayload, 0)

      relay = Relay.new(remoteAddr, client, udpSocket)
      if request[0] == 0x01 # TCP
        relay.runTCP()
      else                  # UDP
        relay.runUDP()
      end
    rescue => err
      pp err
    end
    client.close()
  end
}