require! 'dcs': {Actor, sleep, TCPProxyClient}
require! 'dcs/drivers/omron': {OmronProtocolActor, HostlinkProtocol}
require! '../config': {dcs-port}
require! 'net'


server = net.create-server (socket) ->
    transport = socket
    protocol = new HostlinkProtocol transport
    connector = new OmronProtocolActor protocol

    /* calculate which topic to subscribe by using protocol.

       eg:

            err, res <~ protocol.read 'D100', 1
            device-id = res
            connector.subscribe "omron.#{device-id}.**"

    */
    connector.subscribe 'public.**'

    transport.on \end, ~>
        connector.log.log "transport is ended, killing itself."
        connector.kill!

server.listen 2000, '0.0.0.0', ~>
    console.log "Hostlink Server started listening on port: 2000"

new TCPProxyClient port: dcs-port .login {user: "monitor", password: "test"}
