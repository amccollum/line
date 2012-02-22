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
            @waiting--
            return if @stopped

            args = Array.prototype.slice.call(arguments)
        
            if args[0]
                @fail.apply(this, args)
            
            else
                # Shift off the error arg
                args.shift()

                if name != null
                    @results[name] = args
            
                try
                    _running = this
                    fn.apply(this, args) if fn
                    _running = null
                    
                catch e
                    @fail(e)
                
                # The line may be stopped in fn
                @next() if not @waiting and not @stopped 

    fail: (err) ->
        args = Array.prototype.slice.call(arguments)
        @stopped = true
        
        if err instanceof Error
            console.log(err.stack)
        else
            console.log(args)

        error = @error
        parent = @parent
        
        while not error and parent
            error = parent.error
            parent = parent.parent
    
        if error
            error.apply(this, args)
    
    end: (fn) ->
        @stopped = true
        @blocks = @blocks.slice(-1)
        @next(fn)
        
        return
    
    next: (fn) ->
        args = @results[@resultId or @id]
        @resultId = null

        if @blocks.length
            block = @blocks.shift()
            done = @wait(fn)
            
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
line.end = (fn) -> _running.end(fn)
line.fail = -> _running.fail.apply(_running, arguments)

module.exports = line
