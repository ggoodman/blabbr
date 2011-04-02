require.paths.unshift('./vendor');

require.paths.unshift('./browserify');

var coffee = require('coffee-script');
exports.app = app = require('./app');

require('./controllers/auth');

if (!module.parent) {
  var port = process.env.C9_PORT || 80;
  app.listen(port);
  console.log("Express server listening on port %d", port);
}