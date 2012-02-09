assert = require('assert')
vows = require('vows')
line = require('line')

equal = assert.equal

if not vows.add
    vows.add = (name, batch) -> vows.describe(name).addBatch(batch).export(module)


timeout = (delay, fn) ->
    setTimeout(fn, delay)
    return

vows.add 'line'
    'simple test':
        topic: []
        'the result array should start out empty': (results) -> equal results.length, 0
        
        'the 10ms result':
            topic: (results) ->
                line =>
                    timeout 10, line.wait =>
                        results.push(0)
                        @success(results)
            
            'should be first': (results) -> equal results[0], 0
            
        'the 100ms result':
            topic: (results) ->
                line.add =>
                    timeout 100, line.wait =>
                        results.push(1)
                        @success(results)
            
            'should be second': (results) -> equal results[1], 1

        'the 50ms result':
            topic: (results) ->
                line =>
                    timeout 50, line.wait =>
                        results.push(2)
                        @success(results)
            
            'should be third': (results) -> equal results[2], 2
            
        'should still be empty': (results) -> equal results.length, 0
        
        'running the q':
            topic: (results) ->
                line.run =>
                    @success(results)
                    
            'should add all the results': (results) -> equal results.length, 3
