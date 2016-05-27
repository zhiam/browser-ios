'use strict';
var fs = require('fs');

function run_cmd(cmd, args, callBack ) {
    var spawn = require('child_process').spawn;
    var child = spawn(cmd, args);
    var resp = "";

    child.stdout.on('data', function (buffer) { resp += buffer.toString() });
    child.stdout.on('end', function() { callBack (resp) });
}

run_cmd("find", ['.', '-name', 'list.txt'], function(text) {
    text.split('\n').forEach((item) => {
        add_ddg(item);
    })
});

function add_ddg(file) {
    fs.readFile(file, 'utf8', function(err, contents) {
        if ((contents + '').indexOf('duck') > -1) {
            return;
        }
        console.log(file)
        fs.appendFile(file, 'duckduckgo', (err) => {});
    })
}