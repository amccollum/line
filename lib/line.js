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
    this.error = null;
    this.stopped = false;
    this.waiting = 0;
  }

  line.prototype.add = function(block) {
    this.blocks.push(block);
  };

  line.prototype.wait = function(name, fn) {
    var _this = this;
    this.waiting++;
    if (name === void 0 || typeof name === 'function') {
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
        if (name !== null) _this.results[name] = args;
        if (fn) fn.apply(_this, args);
        if (!--_this.waiting) return _this.next();
      }
    };
  };

  line.prototype.stop = function() {
    var args, error, parent;
    args = Array.prototype.slice.call(arguments);
    this.stopped = true;
    error = this.error;
    parent = this.parent;
    while (!error && parent) {
      error = parent.error;
      parent = parent.parent;
    }
    if (error) return error.apply(this, args);
  };

  line.prototype.next = function(fn) {
    var args, block, done, result;
    args = this.results[this.resultId || this.id];
    this.resultId = null;
    if (this.blocks.length) {
      block = this.blocks.shift();
      done = this.wait(null, fn);
      try {
        _running = this;
        result = block.apply(this, args);
        _running = null;
        done(null, result);
      } catch (e) {
        done(e);
      }
    }
  };

  line.prototype.run = function(fn) {
    var _this = this;
    _context = null;
    if (fn) this.add(fn);
    if (this.parent) this.add(this.parent.wait(null));
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
  _context.error = fn;
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
