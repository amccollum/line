var line, _context, _running;

_context = null;

_running = null;

line = (function() {

  function line(parent) {
    if (this.constructor !== line) return line.add.apply(this, arguments);
    this.parent = parent;
    this.blocks = [];
    this.results = [];
    this.successCallback = null;
    this.errorCallback = null;
    this.stopped = false;
    this.waiting = 0;
  }

  line.prototype.add = function(block) {
    this.blocks.push(block);
  };

  line.prototype.wait = function(fn) {
    var _this = this;
    this.waiting++;
    return function() {
      var args;
      args = Array.prototype.slice.call(arguments);
      if (!_this.stopped && args[0]) _this.stop.apply(_this, args);
      args.shift();
      if (!_this.stopped) {
        _this.results.push(args);
        if (fn) fn.apply(_this, args);
        if (!--_this.waiting) return _this.next(args);
      }
    };
  };

  line.prototype.stop = function() {
    var args, errorCallback, parent;
    this.stopped = true;
    args = Array.prototype.slice.call(arguments);
    errorCallback = this.errorCallback;
    parent = this.parent;
    while (!errorCallback && parent) {
      errorCallback = parent.errorCallback;
      parent = parent.parent;
    }
    if (errorCallback) return errorCallback.apply(this, args);
  };

  line.prototype.next = function(args) {
    var result, waitCallback;
    if (this.blocks.length) {
      _running = this;
      waitCallback = this.wait();
      try {
        result = this.blocks.shift().apply(this, args);
        waitCallback(null, result);
      } catch (e) {
        waitCallback(e);
      }
    } else if (this.successCallback) {
      this.successCallback.apply(this, args);
    }
  };

  line.prototype.run = function(fn) {
    var waitCallback;
    var _this = this;
    _context = null;
    if (this.parent) waitCallback = this.parent.wait();
    this.successCallback = function() {
      if (this.parent) waitCallback();
      if (fn) return fn.apply(this, arguments);
    };
    process.nextTick(function() {
      return _this.next();
    });
  };

  return line;

})();

line.add = function(block) {
  if (!_context) _context = new line(_running);
  _context.add(block);
};

line.error = function(fn) {
  if (!_context) _context = new line(_running);
  _context.errorCallback = fn;
};

line.run = function(fn) {
  if (!_context) _context = new line(_running);
  _context.run(fn);
};

line.wait = function(fn) {
  return _running.wait(fn);
};

line.stop = function() {
  return _running.stop.apply(_running, arguments);
};

module.exports = line;
