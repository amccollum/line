q
===
Q is designed to work with CoffeeScript/

Here's an example:

```js
    q.add ->
        taskWithCallback q.wait()
        
    q.add (firstTaskResult) ->
        anotherTask firstTaskResult, q.wait()
    
    q.add ->
        finalTask q.wait()
        
    q.run ->
        console.log('All three tasks should be completed')
        
    q.error (err) ->
        console.log('Oh no! One of the tasks had an error!')
        throw err 
```
