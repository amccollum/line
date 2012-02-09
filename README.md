line
===
Line is designed to work with CoffeeScript.

Here's an example:

```js
    line ->
        taskWithCallback line.wait()
        
    line (firstTaskResult) ->
        anotherTask firstTaskResult, line.wait()
    
    line ->
        finalTask line.wait()
        
    line.catch (err) ->
        console.log('Oh no! One of the tasks had an error!')
        throw err 

    line.run ->
        console.log('All three tasks should be completed')
        
```
