assert = require('assert')
vows = require('vows')
line = require('line')

equal = assert.equal

if not vows.add
    vows.add = (name, batch) -> vows.describe(name).addBatch(batch).export(module)


timeout = (delay, fn) ->
    setTimeout(fn, delay)
    return
    
echo = (val, fn) ->
    process.nextTick ->
        fn(null, val)


vows.add 'line'
    'nested lines':
        topic: () ->
            results = []
            l = new line.Line null,
                =>
                    timeout 10, l.wait => results.push(0)
                    
                    l2 = new line.Line l,
                        => timeout 30, l2.wait => results.push(2)
                        => timeout 10, l2.wait => results.push(3)

                    timeout 20, l.wait => results.push(1)

                =>
                    timeout 10, l.wait =>
                        results.push(4)
            
                => @success(results)
                
            return
        
        'should have all the results in the right order': (results) ->
            equal results[0], 0
            equal results[1], 1
            equal results[2], 2
            equal results[3], 3
            equal results[4], 4

    'arguments to wait()':
        topic: ->
            success = @success
            
            new line.Line null,
                ->
                    echo 1, @wait('a')
                    echo 2, @wait()
                    echo 3, @wait(true)
                    echo 4, @wait('b')
                    echo 5, @wait('c')
                    echo 6, @wait()
                
                (result) -> @results['test'] = result

                -> success(@results)
        
            return
        
        'should be added correctly': (results) ->
            equal results['a'], 1
            equal results[2], 2
            equal results[3], 3
            equal results['b'], 4
            equal results['c'], 5
            equal results[4], 6
            equal results['test'], 3

    'stopping a line':
        topic: ->
            success = @success
            results = []
            
            new line.Line null,
                -> timeout 10, @wait -> results.push(1)
                -> timeout 10, @wait -> results.push(2)
                -> @stop()
                -> timeout 10, @wait -> results.push(3)
                -> success(results)
        
            return
        
        'should prevent the rest of the blocks from running': (results) ->
            equal results.length, 2
            equal results[0], 1
            equal results[1], 2

    'true/false callbacks':
        topic: ->
            results = []
            success = @success
            
            trueFn = (cb) -> process.nextTick -> cb(true)
            falseFn = (cb) -> process.nextTick -> cb(false)
            
            new line.Line null,
                -> trueFn @wait (result) -> results.push(result)
                -> falseFn @wait (result) -> results.push(result)
                -> success(results)
        
            return
        
        'should not trigger errors': (results) ->
            equal results[0], true
            equal results[1], false

    'more nested lines':
        topic: ->
            success = @success
            results = []
            
            new line.Line null,
                ->
                    results.push(0)
                
                    new line.Line @,
                        -> echo 1, @wait()
                        (one) -> echo 2, @wait()
                        (two) -> echo 3, @wait()
                        (three) ->
                            results.push(2)
                            return three
                    
                    results.push(1)
                    return
                    
                (three) -> results.push(three)
                -> results.push(4)
                -> success(results)
            
            return
            
        'should make their parents wait ': (result) ->
            equal result[0], 0
            equal result[1], 1
            equal result[2], 2
            equal result[4], 4
            
        'should be able to pass on results': (result) ->
            equal result[3], 3

    'old api':
        topic: ->
            success = @success
            results = []
            
            line.add ->
                results.push(0)
            
                line.add -> echo 1, @wait()
                line.add (one) -> echo 2, @wait()
                line.add (two) -> echo 3, @wait()
                line.run (three) ->
                    results.push(2)
                    return three
                
                
                results.push(1)
                return
                
            line.add (three) -> results.push(three)
            line.add -> results.push(4)
            line.run -> success(results)
            
            return
            
        'should get the same results ': (result) ->
            equal result[0], 0
            equal result[1], 1
            equal result[2], 2
            equal result[3], 3
            equal result[4], 4
