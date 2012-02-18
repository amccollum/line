var line, _context, _running;

_context = null;

_running = null;

line = (function() {

  function line(parent) {
    if (this.constructor !== line) return line.add.apply(this, arguments);
    this.id = 0;
    this.parent = parent;
    this.blocks = [];
    this.results = {};
    this.successCallback = null;
    this.errorCallback = null;
    this.stopped = false;
    this.waiting = 0;
  }

  line.prototype.add = function(block) {
    this.blocks.push(block);
  };

  line.prototype.wait = function(name, fn) {
    var _this = this;
    this.waiting++;
    if (!name || typeof name === 'function') {
      fn = name;
      name = ++this.id;
    } else if (name === true) {
      name = ++this.id;
      this.resultId = name;
    }
    return function() {
      var args;
      args = Array.prototype.slice.call(arguments);
      if (!_this.stopped && args[0]) _this.stop.apply(_this, args);
      args.shift();
      if (!_this.stopped) {
        _this.results[name] = args;
        if (fn) fn.apply(_this, args);
        if (!--_this.waiting) return _this.next();
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

  line.prototype.next = function() {
    var args, result, waitCallback;
    args = this.results[this.resultId || this.id];
    this.resultId = null;
    if (this.blocks.length) {
      waitCallback = this.wait();
      try {
        _running = this;
        result = this.blocks.shift().apply(this, args);
        _running = null;
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

line.add = function(fn) {
  if (!_context) _context = new line(_running);
  _context.add(fn);
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
