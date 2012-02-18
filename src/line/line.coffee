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
        @error = null

        @stopped = false
        @waiting = 0
    
    add: (block) ->
        @blocks.push(block)
        return
    
    wait: (name, fn) ->
        @waiting++
    
        if name == undefined or typeof name == 'function'
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
                if name != null
                    @results[name] = args
                    
                fn.apply(this, args) if fn
                @next() if not --@waiting

    stop: ->
        args = Array.prototype.slice.call(arguments)
        @stopped = true
            
        error = @error
        parent = @parent
        
        while not error and parent
            error = parent.error
            parent = parent.parent
    
        if error
            error.apply(this, args)
    
    next: (fn) ->
        args = @results[@resultId or @id]
        @resultId = null

        if @blocks.length
            block = @blocks.shift()
            done = @wait(null, fn)
            
            try
                _running = this
                result = block.apply(this, args)
                _running = null

                done(null, result)
                
            catch e
                done(e)
    
        return
    
    run: (fn) ->
        _context = null
        
        @add(fn) if fn
        @add(@parent.wait(null)) if @parent
        
        process.nextTick => @next()
        return
        
line.add = (fn) ->
    _context = new line(_running) if not _context
    _context.add(fn)
    return

line.error = (fn) ->
    _context = new line(_running) if not _context
    _context.error = fn
    return

line.run = (fn) ->
    _context = new line(_running) if not _context
    _context.run(fn)
    return

line.wait = (fn) -> _running.wait(fn)

line.stop = -> _running.stop.apply(_running, arguments)

module.exports = line
