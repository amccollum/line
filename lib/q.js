
(function(q) {
  var _context, _running;
  _context = null;
  _running = null;
  q.add = function(block) {
    if (!_context) _context = new q.Context(_running);
    _context.add(block);
  };
  q.error = function(fn) {
    if (!_context) _context = new q.Context(_running);
    _context.error = fn;
  };
  q.end = function(fn) {
    if (!_context) _context = new q.Context(_running);
    _context.end(fn);
  };
  q.wait = function(fn) {
    return _running.wait(fn);
  };
  q.kill = function() {
    return _running.kill.apply(_running, arguments);
  };
  return q.Context = (function() {

    function Context(parent) {
      this.parent = parent;
      this.callback = null;
      this.error = null;
      this.errored = false;
      this.blocks = [];
      this.results = [];
      this.waiting = 0;
    }

    Context.prototype.add = function(block) {
      this.blocks.push(block);
    };

    Context.prototype.kill = function() {
      var args, error, parent;
      args = Array.prototype.slice.call(arguments);
      error = this.error;
      parent = this.parent;
      while (!error && parent) {
        error = parent.error;
        parent = parent.parent;
      }
      if (error) {
        return this.errored = !error.apply(this, args);
      } else {
        return this.errored = true;
      }
    };

    Context.prototype.wait = function(fn) {
      var _this = this;
      this.waiting++;
      return function() {
        var args;
        args = Array.prototype.slice.call(arguments);
        _this.results.push(args);
        if (fn) fn.apply(_this, args);
        if (args[0] && !_this.errored) _this.kill.apply(_this, args);
        if (!--_this.waiting && !_this.errored) {
          args.shift();
          return _this.next(args);
        }
      };
    };

    Context.prototype.next = function(args) {
      var fn, result;
      if (this.blocks.length) {
        _running = this;
        fn = this.wait();
        result = this.blocks.shift().apply(this, args);
        fn(result);
      } else if (this.callback) {
        this.callback.apply(this, args);
      }
    };

    Context.prototype.end = function(fn) {
      _context = null;
      this.callback = fn;
      this.next();
    };

    return Context;

  })();
})(typeof exports !== "undefined" && exports !== null ? exports : (this['q'] = {}));
