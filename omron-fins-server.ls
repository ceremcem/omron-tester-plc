require! 'dcs': {Actor, DcsTcpClient, sleep}
require! 'dcs/drivers/omron/fins': {OmronFinsDriver}
require! '../config': {dcs-port}
require! 'dcs/lib': {ensure-array, make-tests}


parse-omron-addr = (addr) -> 
    bit-area-name =
        D: \DM
        C: \CB
        W: \WB 
        H: \HB 
        A: \AB 
    [orig, area, offset, bit] = addr.match /^([a-zA-Z]+)(\d+)[.:]*(\d*)$/
    area .= to-upper-case!
    if /^\d+$/.test(bit)
        area = bit-area-name[area] or area 
        formatted = "#{area}#{offset}:#{bit}"
    else 
        formatted = "#{area}#{offset}"

    return {formatted}

make-tests 'omron-parse-address', tests =
    1: ->
        expect parse-omron-addr("d1")
        .to-equal {formatted: "D1"}

    2: ->
        expect parse-omron-addr("d100.1")
        .to-equal {formatted: "DM100:1"}

    3: ->
        expect parse-omron-addr("c100")
        .to-equal {formatted: "C100"}

    4: ->
        expect parse-omron-addr("c100.2")
        .to-equal {formatted: "CB100:2"}

    5: ->
        expect parse-omron-addr("c100:2")
        .to-equal {formatted: "CB100:2"}

    6: ->
        expect parse-omron-addr("CB100:2")
        .to-equal {formatted: "CB100:2"}

    7: ->
        expect parse-omron-addr("CB100.2")
        .to-equal {formatted: "CB100:2"}


class OmronFinsActor extends Actor 
    (opts) -> 
        @driver = new OmronFinsDriver (opts)
        super opts.name

        # Addresses to be watched
        # Formatted_address: 
        #     last_request: The server timestamp for this address' latest request. Used for heartbeat
        #     value: Read data
        #     last_update: Last update timestamp
        @watch = {}
        @timeout = 5 * 60_000ms 
        @on-topic "#{@name}.watch", (msg) ~>>
            # msg.data data format: 
            [_addr, length] = msg.data

            @log.info "Received watch:", msg.data
            addr = parse-omron-addr(_addr).formatted
            @watch{}[addr]
                ..last_request = Date.now!
                ..route = "#{@name}.#{addr}.update"
                ..activated = no 
                ..timeout = @timeout
            @send-response msg, {err: @watch[addr].last_error, res: @watch[addr]}
            await sleep 1000ms # let the client register for the `res.route`
            @watch[addr].activated = yes 

        @on-topic "#{@name}.read", (msg) ~>>
            # msg.data data format: 
            [_addr, length] = msg.data

            @log.info "Received read:", msg.data
            addr = parse-omron-addr(_addr).formatted
            try 
                res = await @driver.exec 'read', addr, length
                value = if length is 1 
                    res.values.0
                else 
                    res.values
                @send-response msg, {err: null, res: value}
            catch 
                @log.error "Error writing #{addr}:", e 
                @send-response msg, {err: e}

        @on-topic "#{@name}.write", (msg) ~>>
            @log.info "Received write:", msg.data
            #return unless +data?
            try 
                [_addr, value] = msg.data
                addr = parse-omron-addr(_addr).formatted
                res = await @driver.exec 'write', addr, value
                @send-response msg, {err: null, res}
            catch 
                @log.error "Error in write:", e 
                @send-response msg, {err: e} 

        @on-topic "#{@name}.heartbeat", (msg) ~> 
            @send-response msg, {err: not @driver.connected, res: "ok"}


    action: ->>
        # Send all listeners that we have restarted.
        @on-every-login ~> 
            @log.info "Relogin, sending .restart signal"
            @send "#{@name}.restart", null

        @driver.on 'connected', ~> 
            @log.info "Driver reconnected, sending .started signal"
            @send "#{@name}.started", null

        @driver.on 'disconnected', ~> 
            for addr, v of @watch
                v.last_error = "Disconnected from target"
            @send "#{@name}.stopped", {err: "Target device is disconnected."}

        # Watch for changes
        while true
            for addr, v of @watch
                unless v.activated 
                    continue
                /* TODO: Timeout the subscribers
                if Date.now! - v.last_request > @timeout
                    delete @watch[addr]
                    @send v.route, {err: null, deleted: yes}
                    continue
                */
                try
                    res = await @driver.exec 'read', addr, 1
                    value = res.values.0
                    v.last_read = Date.now!
                    if (value isnt v.value) or v.last_error?
                        #@log.log "Value changed for #{addr}: #{v.value} -> #{value}"
                        v.value = value 
                        @send v.route, {v.value, v.last_read}
                    v.last_error = null
                catch 
                    @log.error "Something went wrong while reading #{addr}:", e 
                    unless v.last_error 
                        @send v.route, {err: e}
                    v.last_error = e 
                    v.last_read = null

            await sleep 200ms

new OmronFinsActor {name: \my1, host: '192.168.250.9'}

new DcsTcpClient port: dcs-port .login {user: "monitor", password: "test"}
