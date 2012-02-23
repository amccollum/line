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

    'nested lines':
        topic: []
        'with nested lines':
            topic: (results) ->
                line =>
                    process.nextTick line.wait =>
                        results.push(0)
                        
                    line =>
                        process.nextTick line.wait =>
                            results.push(2)

                    line =>
                        process.nextTick line.wait =>
                            results.push(3)

                    line.run()

                    process.nextTick line.wait =>
                        results.push(1)

                line =>
                    process.nextTick line.wait =>
                        results.push(4)
                
                line.run =>
                    @success(results)
            
            'should have all the results in the right order': (results) ->
                equal results[0], 0
                equal results[1], 1
                equal results[2], 2
                equal results[3], 3
                equal results[4], 4

    'arguments to wait()':
        topic: ->
            success = @success
            
            line ->
                echo 1, line.wait('a')
                echo 2, line.wait()
                echo 3, line.wait(true)
                echo 4, line.wait('b')
                echo 5, line.wait('c')
                echo 6, line.wait()
                
            line (result) -> @results['test'] = result

            line.run -> success(@results)
        
        'should be added correctly': (results) ->
            equal results['a'], 1
            equal results[2], 2
            equal results[3], 3
            equal results['b'], 4
            equal results['c'], 5
            equal results[4], 6
            equal results['test'], 3

    'nested lines':
        topic: ->
            success = @success
            
            result = []
            line ->
                result.push(0)
                
                line -> echo 1, line.wait()
                line (one) -> echo 2, line.wait()
                line (two) -> echo 3, line.wait()
                line.run (three) =>
                    result.push(2)
                    return three
                    
                result.push(1)
                return
                    
            line (three) ->
                result.push(three)
                
            line ->
                result.push(4)
                
            line.run ->
                success(result)
                
        'should make their parents wait ': (result) ->
            equal result[4], 4
            
        'should be able to pass on results': (result) ->
            equal result[0], 0
            equal result[1], 1
            equal result[2], 2
            equal result[3], 3

