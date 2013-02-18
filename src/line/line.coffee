((name, definition) ->
    if typeof module == 'object' and module.exports then module.exports = definition()
    else if typeof define == 'function' and define.amd then define(name, definition)
    else @[name] = definition()
    return
)('line', ->
    
    events = require('events')
    line = {}

    line.active = null    
    
    class line.Line extends events.EventEmitter
        constructor: (parent, listeners) -> # fns...
            blocks = Array.prototype.slice.call(arguments)
            
            if typeof parent == null or parent instanceof line.Line
                blocks.shift()
            else
                listeners = parent
                parent = null
                
            if typeof listeners == 'object'
                blocks.shift()
            else
                listeners = {}
            
            # See whether the blocks were passed as an array
            if blocks.length and typeof blocks[0] isnt 'function'
                blocks = blocks[0]
            
            @parent = parent
            @blocks = []
            @waiting = 0
            @stopped = false
            @results = {}
            @id = 0
            
            for event, listener of listeners
                @on event, listener

            @add(blocks)
            
            if @parent
                done = @parent.wait()
                @once 'end', ->
                    args = Array.prototype.slice.call(arguments)
                    args.unshift(null)
                    done.apply(this, args)
        
        add: (blocks) ->
            if typeof blocks is 'function'
                blocks = Array.prototype.slice.call(arguments)
            
            for block in blocks
                @blocks.push(block)
                
                # See if we need to restart the line
                if @blocks.length == 1
                    setTimeout((=> @next(); return), 0)
            
            return @
            
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
                
                # Check the special case of boolean true/false
                if args.length == 1 and typeof args[0] is 'boolean'
                    args.unshift(null)
            
                if args[0]
                    # Emit the error
                    @_bubble('error', args)
            
                else
                    # Shift off the first arg
                    args.shift()

                    @_bubble('result', args)

                    if name != null
                        @results[name] = args

                    try
                        line.active = @
                        fn.apply(@, args) if fn
                        line.active = null
                    
                    catch e
                        @_bubble('error', [e])
                
                    # The line may wait or be stopped in fn
                    @next() if not @waiting and not @stopped 

        next: ->
            @stopped = false
            
            args = @results[@resultId or @id]
            @resultId = null

            if not @blocks.length
                @emit.apply(@, ['end'].concat(args))
                
            else
                block = @blocks.shift()
                done = @wait()
            
                try
                    line.active = @
                    result = block.apply(@, args)
                    line.active = null

                    done(null, result)
                
                catch e
                    done(e)
            
            return
    
        fail: ->
            args = Array.prototype.slice.call(arguments)
            @_bubble('error', args)
            return
            
        stop: ->
            @stopped = true
            args = Array.prototype.slice.call(arguments)
            @_bubble('stop', args)
            return

        _bubble: (event, args) ->
            args = [event].concat(args)
            
            if not @_events or not @_events[event]
                cur = @
                while (cur = cur.parent)
                    if cur._events and cur._events[event]
                        if cur.emit.apply(cur, args) != true
                            return
            
            @emit.apply(@, args)


    # Deprecated API
    _context = null
    line.add = () ->
        _context = new line.Line(line.active) if not _context
        _context.add.apply(_context, arguments)
        return

    line.error = (listener) ->
        _context = new line.Line(line.active) if not _context
        _context.on 'error', listener
        return

    line.run = () ->
        _context = new line.Line(line.active) if not _context
        _context.add.apply(_context, arguments)
        _context = null
        return

    line.wait = (fn) -> line.active.wait(fn)
    line.fail = -> line.active.fail.apply(line.active, arguments)
    line.stop = -> line.active.stop.apply(line.active, arguments)

    return line
)
