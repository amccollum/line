((q) ->
    _context = null
    _running = null

    q.add = (block) ->
        _context = new q.Context(_running) if not _context
        _context.add(block)
        return
    
    q.error = (fn) ->
        _context = new q.Context(_running) if not _context
        _context.error = fn
        return
    
    q.end = (fn) ->
        _context = new q.Context(_running) if not _context
        _context.end(fn)
        return
    
    q.wait = (fn) -> _running.wait(fn)

    q.kill = () -> _running.kill.apply(_running, arguments)

    class q.Context
        constructor: (@parent) ->
            @callback = null
            @error = null
            @errored = false
            @blocks = []
            @results = []
            @waiting = 0
        
        add: (block) ->
            @blocks.push(block)
            return
        
        kill: ->
            args = Array.prototype.slice.call(arguments)
            error = @error
            parent = @parent
            
            while not error and parent
                error = parent.error
                parent = parent.parent
        
            if error
                @errored = not error.apply(this, args)
            else
                @errored = true
        
        wait: (fn) ->
            @waiting++
        
            return =>
                args = Array.prototype.slice.call(arguments)
                @results.push(args)
            
                fn.apply(this, args) if fn
    
                if args[0] and not @errored
                    @kill.apply(this, args)
            
                if not --@waiting and not @errored
                    args.shift()
                    @next(args)

        next: (args) ->
            if @blocks.length
                _running = this
            
                fn = @wait()
                result = @blocks.shift().apply(this, args)
                fn(result)
                    
            else if @callback
                @callback.apply(this, args)
        
            return
        
        end: (fn) ->
            _context = null
            @callback = fn
            @next()
            return
            
)(exports ? (@['q'] = {}))