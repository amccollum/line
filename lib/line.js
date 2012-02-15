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
      _this.results.push(args);
      if (args[0] && !_this.stopped) _this.stop.apply(_this, args);
      if (!--_this.waiting && !_this.stopped) {
        args.shift();
        if (fn) fn.apply(_this, args);
        return _this.next(args);
      }
    };
  };

  line.prototype.stop = function() {
    var args, errorCallback, parent;
    args = Array.prototype.slice.call(arguments);
    if (!args.length) {
      this.stopped = true;
      return;
    }
    errorCallback = this.errorCallback;
    parent = this.parent;
    while (!errorCallback && parent) {
      errorCallback = parent.errorCallback;
      parent = parent.parent;
    }
    if (errorCallback) {
      return this.stopped = !errorCallback.apply(this, args);
    } else {
      return this.stopped = true;
    }
  };

  line.prototype.next = function(args) {
    var fn, result;
    this.stopped = false;
    if (this.blocks.length) {
      _running = this;
      fn = this.wait();
      try {
        result = this.blocks.shift().apply(this, args);
        fn(null, result);
      } catch (e) {
        fn(e);
      }
    } else if (this.successCallback) {
      this.successCallback.apply(this, args);
    }
  };

  line.prototype.run = function(fn) {
    var _this = this;
    _context = null;
    if (fn) this.successCallback = fn;
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
