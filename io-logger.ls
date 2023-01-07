require! 'dcs': {Actor, DcsTcpClient}
require! './config': {dcs-port}
require! 'dcs/lib': {ensure-array, make-tests}
require! './io-list': {io-list}
require! 'dcs/services/couch-dcs/couch-nano': {CouchNano}
require! './passwords': {db_user, db_url, db_user_dcs_password, db_name}
require! 'colors': {
    bg-green, bg-red, bg-yellow, bg-blue
    green, yellow, blue
}
require! 'dcs/drivers/io-proxy': {IoProxy}
require! 'prelude-ls': {abs}
require! 'fs'

cache-folder = "./db_cache"
dont_save_startup_values = true

startup_date = Date.now!

class IoLogger extends Actor 
    (@params) -> 
        super 'IoLogger'

    action: ->
        db = new CouchNano @params
            ..on do
                connected: ~>>
                    @log.log bg-green "Connected to database."
                    for f in fs.readdirSync cache-folder when f.ends-with '.json'
                        file = "#{cache-folder}/#{f}"
                        try 
                            doc = fs.readFileSync file, "utf-8" |> JSON.parse
                            @log.info "Saving a previously failed variable:", doc.name
                            await db.put doc 
                            fs.unlinkSync file
                            fs.createWriteStream "#{cache-folder}/log.txt", {flags: 'a'}
                                ..write "#{new Date! .toISOString()}: #{doc.name}\n"
                                ..end!
                            @log.info "...saved the failed variable: #{doc.name}"
                        catch
                            @log.err "Can not save #{file}, err: ", e 

                error: (err) ~>
                    @log.log (bg-red "Problem while connecting database: "), err

                disconnected: (err) ~>
                    @log.info "Disconnected from db."

        <~ db.connect 
        db.start-heartbeat!

        @log.info "Starting watching io"
        cache_index = 0
        log_index = 0

        for let route, handle of io-list
            for let address, props of handle
                if typeof! props is \String
                    variable = props 
                    props = {}
                else 
                    variable = Object.keys props .0
                    props = props[variable]

                if (typeof! props.log isnt \Boolean) or props.log isnt false

                    io = new IoProxy {route, address}

                    io.on-change (value, timestamp) ~>>
                        coeff = props.unit or 1
                        value *= coeff 

                        if dont_save_startup_values and (startup_date > timestamp)
                            @log.warn "Skipping saving startup value for #{variable}, value: #{value}"
                            return 

                        # Log changes
                        # -------------------------------
                        # if log.when filter is present, ignore the "disregard" value.
                        disregard_value = if props.log?.when? then -1 else (props.disregard or 0)

                        if (not io.last_logged_value?) or abs(value - (io.last_logged_value or 0)) > disregard_value
                            if (props.log isnt false)
                                log-filter = props.log?.when or (is it)
                                if log-filter(value)
                                    doc = {
                                        type: 'variable'
                                        name: variable
                                        value
                                        timestamp
                                        log_index: log_index++, 
                                        prev_value: io.last_logged_value
                                    }
                                    try 
                                        res = await db.put doc

                                        @log.info "Saved #{variable}: #{value}"
                                        io.last_logged_value = value
                                    catch err 
                                        @log.error "Error saving io value: ", err 
                                        fs.writeFileSync "#{cache-folder}/#{++cache_index}.json", JSON.stringify(doc)
                                                                    
                    io.start!

new IoLogger do
    url: db_url # "https://example.com/"
    database: db_name
    user: db_user
    subscribe: <[ my1 ]> 

new DcsTcpClient port: 4013 .login do
    user: "io_logger" 
    password: "8rGrxAdhURP1bAbtyfG9ptGDharKxMg8"
