_context = null
_running = null

class line
    constructor: (parent) ->
        if @constructor != line
            return line.add.apply(this, arguments)
        
        @id = 0
        @parent = parent
        @blocks = []
        @results = {}
        @successCallback = null
        @errorCallback = null

        @stopped = false
        @waiting = 0
    
    add: (block) ->
        @blocks.push(block)
        return
    
    wait: (name, fn) ->
        @waiting++
    
        if not name or typeof name == 'function'
            fn = name
            name = ++@id
            
        else if name == true
            name = ++@id
            @resultId = name
    
        return =>
            args = Array.prototype.slice.call(arguments)
        
            if not @stopped and args[0]
                @stop.apply(this, args)
            
            # Shift off the error arg
            args.shift()
            
            if not @stopped
                @results[name] = args
                fn.apply(this, args) if fn
                @next() if not --@waiting

    stop: ->
        @stopped = true
        args = Array.prototype.slice.call(arguments)
            
        errorCallback = @errorCallback
        parent = @parent
        
        while not errorCallback and parent
            errorCallback = parent.errorCallback
            parent = parent.parent
    
        if errorCallback
            errorCallback.apply(this, args)
    
    next: ->
        args = @results[@resultId or @id]
        @resultId = null

        if @blocks.length
            waitCallback = @wait()
            
            try
                _running = this
                result = @blocks.shift().apply(this, args)
                _running = null

                waitCallback(null, result)
                
            catch e
                waitCallback(e)
                
        else if @successCallback
            @successCallback.apply(this, args)
    
        return
    
    run: (fn) ->
        _context = null
        
        if @parent
            waitCallback = @parent.wait()
        
        @successCallback = ->
            if @parent
                waitCallback()
                
            fn.apply(this, arguments) if fn
            
        process.nextTick => @next()
        return
        
line.add = (fn) ->
    _context = new line(_running) if not _context
    _context.add(fn)
    return

line.error = (fn) ->
    _context = new line(_running) if not _context
    _context.errorCallback = fn
    return

line.run = (fn) ->
    _context = new line(_running) if not _context
    _context.run(fn)
    return

line.wait = (fn) -> _running.wait(fn)

line.stop = -> _running.stop.apply(_running, arguments)

module.exports = line
