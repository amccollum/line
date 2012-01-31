fs = require('fs')
{spawn, exec} = require('child_process')

package = JSON.parse(fs.readFileSync('package.json', 'utf8'))

execCmds = (cmds) ->
    exec cmds.join(' && '), (err, stdout, stderr) ->
        output = (stdout + stderr).trim()
        console.log(output + '\n') if (output)
        throw err if err

task 'build', 'Build the library', ->
    execCmds [
        'coffee --bare --output ./lib ./src/q/*.coffee',
    ]

task 'test', 'Build and run the test suite', ->
    execCmds [
        'coffee --bare --output ./test ./src/test/*.coffee',
        'npm install --dev',
        'ln -sfn node_modules/ender-vows node_modules/vows',
        'ln -sfn node_modules test/node_modules',

        'ln -sfn . node_modules/q',
        'node_modules/.bin/vows ./test/*.js'
        'unlink node_modules/q',
    ]