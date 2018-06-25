var page = require('webpage').create();
var system = require('system');

var fs = require('fs');
var stream = fs.open("./crosswords_website", 'r');
var line = stream.readLine();
stream.close();
console.log(line);


page.open(line, function () {

    var nextpuzzle = page.evaluate(function () {
        return document.querySelectorAll(".content_next a")[1].getAttribute("href");
    });

    nextpuzzle = "http://www.tuili8.com" + nextpuzzle;

    fs.write("./crosswords_website", nextpuzzle, "w");

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
