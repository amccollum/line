line
===
Line is designed to work with CoffeeScript.

Here's an example:

```CoffeeScript
line ->
    fs.readdir 'my_dir', line.wait()
    
line (files) ->
    fs.readFile "my_dir/#{files[0]}", 'utf8', line.wait('f1')
    fs.readFile "my_dir/#{files[1]}", 'utf8', line.wait('f2')
    fs.stat "my_dir/#{files[2]}", line.wait()

line (stats) ->
    console.log('Contents of the first file:', @results.f1)
    console.log('Contents of the second file:', @results.f2)
    console.log('Result of fs.stat for the third file:', stats)
    
    # If there is no line.wait() call, the callback will complete immediately
    
line.error (err) ->
    console.log('Oh no! One of the callbacks showed an error!')

line.run ->
    console.log('All the tasks completed without errors.')
        
```
