var instance = require('webpage').create();
var page = require('webpage').create();
var system = require('system');

var fs = require('fs');
var file_h = fs.open('crosswords_website', 'r');
var line = file_h.readLine();
file_h.close();

page.open(line, function () {
            //Heres the actual difference from your code...
    var nextpuzzle = page.evaluate(function () {
        return document.querySelectorAll(".content_next a")[1].getAttribute("href");
    });

    nextpuzzle = "http://www.tuili8.com" + nextpuzzle;

    file_h = fs.open('crosswords_website', 'w');
    file_h.writeLine(nextpuzzle);
    file_h.close();

    var bb = page.evaluate(function () {
        return document.querySelector(".c").getBoundingClientRect();
    });
    page.clipRect = {
                top:    bb.top,
                left:   bb.left,
                width:  bb.width,
                height: bb.height
    };
    page.render('capture.png');

    phantom.exit();
});

/*
instance.open(system.args[1], function() {
instance.render('guardian-today.png');
phantom.exit();
});
*/
