line
===
Line is flow control designed to work with CoffeeScript.

Here's an example:

```CoffeeScript
Line = require('line').Line

data2 = null

l = new Line
	error: (err) -> console.log('Oh no! One of the callbacks had an error:', err)
		
	-> fs.readdir 'my_dir', @wait()
    
	(files) ->
		# Callback results can be named, or observed
	    fs.readFile "my_dir/#{files[0]}", 'utf8', @wait('data1')
	    fs.readFile "my_dir/#{files[1]}", 'utf8', @wait (data) -> data2 = data
	    fs.stat "my_dir/#{files[2]}", @wait()

	# By default, the result of the last wait() call will be passed on
	(stats) ->
	    console.log('Contents of the first file:', @results.data1)
	    console.log('Contents of the second file:', data2)
	    console.log('Result of fs.stat for the third file:', stats)
    
    # If there is no wait() call, the callback will complete immediately

# Blocks can also be added later
l.add -> console.log('All the tasks completed without errors.')
```
