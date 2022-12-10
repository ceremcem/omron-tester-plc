require! 'dcs': {Actor, TCPProxyClient}
require! 'dcs/connectors/omron': {HostlinkSerialConnector}
require! '../config': {dcs-port}

new HostlinkSerialConnector do
    transport:
        baudrate: 9600baud
        port: '/dev/ttyUSB0'
    subscribe: "public.**"

new TCPProxyClient port: dcs-port .login {user: "monitor", password: "test"}
