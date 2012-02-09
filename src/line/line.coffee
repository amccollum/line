_context = null
_running = null

class line
    constructor: (parent) ->
        if @constructor != line
            return line.add.apply(this, arguments)
        
        @parent = parent
        @blocks = []
        @results = []
        @successCallback = null
        @errorCallback = null

        @stopped = false
        @waiting = 0
    
    add: (block) ->
        @blocks.push(block)
        return
    
    wait: (fn) ->
        @waiting++
    
        return =>
            args = Array.prototype.slice.call(arguments)
            @results.push(args)
        
            fn.apply(this, args) if fn

            if args[0] and not @stopped
                @stop.apply(this, args)
        
            if not --@waiting and not @stopped
                args.shift()
                @next(args)

    stop: ->
        args = Array.prototype.slice.call(arguments)
        
        if not args.length
            @stopped = true
            return
            
        errorCallback = @errorCallback
        parent = @parent
        
        while not errorCallback and parent
            errorCallback = parent.errorCallback
            parent = parent.parent
    
        if errorCallback
            @stopped = not errorCallback.apply(this, args)
        else
            @stopped = true
    
    next: (args) ->
        @stopped = false
        
        if @blocks.length
            _running = this
        
            fn = @wait()
            
            try
                result = @blocks.shift().apply(this, args)
                fn(null, result)
                
            catch e
                fn(e)
                
        else if @successCallback
            @successCallback.apply(this, args)
    
        return
    
    run: (fn) ->
        _context = null
        @successCallback = fn if fn
        process.nextTick => @next()
        return
        
line.add = (block) ->
    _context = new line(_running) if not _context
    _context.add(block)
    return

line.catch = (fn) ->
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
