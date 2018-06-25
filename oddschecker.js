var page = require('webpage').create();
var odds_page = "http://www.oddsportal.com/soccer/world/world-cup-2018/"

page.open(odds_page, function() {

  phantom.exit();
});
