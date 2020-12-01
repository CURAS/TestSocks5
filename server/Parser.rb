module Socks5Parse
  def parseMethodPayload(payload)
    # Method Request
    ver, nmethods, *methods = payload.unpack('C*')
    if ver != 5
      return nil, 'Error: Wrong Version'
    end
    if nmethods != methods.size
      return methods, 'Warning: Wrong Method List Size[' + 'read:' + nmethods.to_s + ' , real:' + methods.size.to_s + ']'
    end

    return [methods]
  end

  def makeMethodPayload(methods)
    # Method Response
    if not methods.include?(0x00)
      return nil, 'Error: No Supported Method'
    end
    res = [0x05, 0x00].pack('CC')

    return res
  end

  def parseRequestPayload(payload)
    # Request
    ver, cmd, atyp, payload = payload.unpack('CCxCa*')
    if ver != 5
      return nil, 'Error: Wrong Version'
    end
    if not [0x01, 0x02, 0x03].include?(cmd)
      return nil, 'Error: Wrong Command'
    end
    case atyp
    when 0x01
      hostBytes, payload = payload.unpack('a4a*')
      hostBytes = hostBytes.unpack('C4')
      host = hostBytes.join('.')
    when 0x03
      hostLen, payload = payload.unpack('Ca*')
      host, payload = payload.unpack('a' + hostLen.to_s + 'a*')
    when 0x04
      hostBytes, payload = payload.unpack('a16a*')
      hostWords = hostBytes.unpack('S8')
      host = hostWords.map{|word| word.to_s(16)}.join(':').upcase
    else
      return nil, 'Error: Wrong Host'
    end
    port = payload.unpack('n')[0]
    res = [cmd, atyp, host, port]

    return [res]
  end

  def makeResponsePayload(rep, atyp, host, port)
    # Response
    res = [0x05, rep, atyp].pack('CCxC')
    case atyp
    when 0x01
      hostBytes = host.split('.').map(&:to_i)
      res = res + hostBytes.pack('C4')
    when 0x03
      res = res + host.length.to_s + host
    when 0x04
      hostBytes = host.split(':').map{|word| word.to_i(16)}
      res = res + hostBytes.pack('S8')
    else
      return nil, 'Error: Wrong Host'
    end
    res = res + [port].pack('n')

    return res
  end

  module_function :parseMethodPayload, :makeMethodPayload, :parseRequestPayload, :makeResponsePayload
end