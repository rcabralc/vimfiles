(function(global) {
  "use strict";

  var $ = global.jQuery;

  applyPolyfills();

  global.backend = (function(console) {
    // Stub backend implementation.

    return {
      filter: function(input) {
        console.log('send input to backend for filtering: ' + input);
      },
      enter: function(input) {
        console.log('send input to backend as entered: ' + input);
      },
      acceptInput: function() {
        console.log('tell backend to accept current input');
      },
      acceptSelected: function() {
        console.log('tell backend to accept selected item');
      },
      getSelected: function() {
        console.log('get selected value from backend');
        return '';
      },
      complete: function() {
        console.log('get completion from backend');
        return '';
      },
      historyPrev: function() {
        console.log('get previous entry from history');
        return '';
      },
      historyNext: function() {
        console.log('get next entry from history');
        return '';
      },
      prev: function() {
        console.log('tell backend to select previous item');
      },
      next: function() {
        console.log('tell backend to select next item');
      },
      dismiss: function() {
        console.log('tell backend to quit');
      },
      log: function(msg) {
        console.log('logged to backend: ' + msg);
      },
      wordDelimiters: function() {
        return [' '];
      }
    };
  })(global.console);

  global.frontend = (function() {
    return {
      setInput: function(input) {
        global.input.overwrite(input);
      },

      setItems: function(items) {
        global.entries.set(items);

        if (items.length) {
          global.input.markFound();
        } else {
          global.input.markNotFound();
        }
      },

      switchPrompt: function(newPrompt) {
        $('#prompt-box .prompt').text(newPrompt);
      },

      reportMode: function(newMode) {
        global.input.setMode(newMode);
      },

      overLimit: function() {
        $('#prompt-box').addClass('over-limit');
      },

      underLimit: function() {
        $('#prompt-box').removeClass('over-limit');
      },

      updateCounters: function(selected, total) {
        $('#prompt-box .counters').text(selected + '/' + total);
      },

      select: function(index) {
        global.entries.select(index);
      },
    };
  })();

  global.input = (function() {
    var self,
        _$el,
        currentMode,
        // This order is important: iterated from right to left, no ambiguity
        // should happen.  For example: '!=' must be tested before '!',
        // otherwise '!' could inavertendly match '!='.  In summary, an item
        // should not start with any item on right of it.
        patternTypes = ['@', '!', '=', '!='];

    $(window).on('focus', function() { $el().focus(); });

    return (self = {
      setup: function(callback) { callback($el()); },
      set: function(value) { $el().val(value).change(); },
      get: function() { return $el().val(); },
      overwrite: function(value) { $el().val(value).focus(); },
      markFound: function() {
        $el().closest('#prompt-box').removeClass('not-found');
      },
      markNotFound: function() {
        $el().closest('#prompt-box').addClass('not-found');
      },
      clear: function() { self.set(''); },
      eraseWord: function() {
        var delimiters = backend().wordDelimiters().split(''),
            pos = cursor(),
            backpos = lookBackward(pos, delimiters);
        if (backpos == pos && pos > 0) {
          backpos = lookBackward(pos - 1, delimiters);
        }
        replace('', backpos, pos);
      },
      alternatePattern: function() {
        var w = wordUnderCursor(), word = w.value, i, pat;

        for (i = patternTypes.length - 1; i >= 0; i--) {
          pat = patternTypes[i];
          if (word.startsWith(pat)) {
            word = word.slice(pat.length);
            if (i == patternTypes.length - 1) {
              pat = '';
            } else {
              pat = patternTypes[i + 1];
            }
            word = pat + word;
            replace(word, w.start, w.end);
            return;
          }
        }

        word = patternTypes[0] + word;
        replace(word, w.start, w.end);
      },
      setMode: function(newMode) {
        if (currentMode) {
          $el().removeClass(currentMode + '-mode');
        }

        $el().addClass(newMode + '-mode');
        currentMode = newMode;
      }
    });

    function $el() {
      return (_$el = _$el || $('#prompt-box .input'));
    }

    function cursor() {
      var field = $el().get(0);
      return field.selectionDirection == 'backward' ?
        field.selectionStart : field.selectionEnd;
    }

    function replace(str, start, end) {
      var $field = $el(), field = $field.get(0), value = $field.val();
      $field.val(value.slice(0, start) + str + value.slice(end + 1));
      field.selectionStart = start + str.length;
      field.selectionEnd = field.selectionStart;
    }

    function wordUnderCursor(delimiters) {
      var value = $el().val(),
          pos = cursor(),
          start, end;

      delimiters = delimiters || [' '];
      start = lookBackward(pos, delimiters);
      end = lookForward(start, delimiters);

      return { start: start, end: end, value: value.slice(start, end + 1) };
    }

    function lookBackward(pos, delimiters) {
      var start = pos, value = $el().val();
      while (start > 0) {
        if (delimiters.includes(value[start - 1])) break;
        start -= 1;
      }
      while (delimiters.includes(value[start])) start += 1;
      return start;
    }

    function lookForward(pos, delimiters) {
      var end = pos, value = $el().val();
      while (end < value.length - 1) {
        if (delimiters.includes(value[end])) break;
        end += 1;
      }
      while (delimiters.includes(value[end])) end -= 1;
      return end;
    }
  })();

  global.entries = (function() {
    var _$box, _$el, _$sb;

    return {
      setup: function(callback) {
        $(window).on('resize', adjustHeight);
        adjustHeight();

        if (callback) {
          callback($el());
        }
      },

      set: function(items) {
        var entries = items.map(function(item) {
          var $li = $(document.createElement('li'));

          item.partitions.forEach(function(patition) {
            $li.append($(document.createElement('span'))
                       .text(patition.unmatched));
            $li.append($(document.createElement('span'))
                       .addClass('hl').text(patition.matched));
          });

          if (item.selected) {
            $li.addClass('selected');
          }

          return $li;
        });

        $el().html(entries);
        adjustScroll();
      },

      select: function(index) {
        var $e = $el();
        $e.find('li.selected').removeClass('selected');
        ensureVisible(
          $e.find('li:nth-child(' + (index + 1) + ')').addClass('selected')
        );
      },
    };

    function $box() {
      return (_$box = _$box || $('#entries-box'));
    }

    function $el() {
      return (_$el = _$el || (function() {
        return $('#entries').on('scroll', adjustScroll);
      })());
    }

    function $sb() {
      return (_$sb = _$sb || $('#scrollbar'));
    }

    function ensureVisible($item) {
      var top = $item.offset().top - $el().offset().top,
          eh = $box().height(),
          bottom = top + $item.outerHeight() - eh,
          current = $el().scrollTop(),
          scroll = current + (bottom >= 0 ? bottom : (top < 0 ? top : 0));

      $el().scrollTop(scroll);
    }

    function adjustHeight() {
      var height = $(window).height() - $box().offset().top;
      $box().height(height);
      $sb().outerHeight(height);
      adjustScroll();
    }

    function adjustScroll() {
      var visibleHeight = $box().height(), scroll = $el().scrollTop(),
          totalHeight = getTotalHeight();

      if (totalHeight > visibleHeight) {
        var thumbHeight = 100 * visibleHeight / totalHeight,
            top = 100 * scroll / totalHeight;

        $sb().find('.thumb').show().css({
          height: thumbHeight + '%',
          top: top + '%',
        });
      } else {
        $sb().find('.thumb').hide().css({ height: 0, top: 0 });
      }
    }

    function getTotalHeight() {
      return Array.prototype.slice.call(
        $el().find('> li').map(function(i, el) {
          return $(el).outerHeight();
        })
      ).reduce(function(a, b) { return a + b; }, 0);
    }
  })();

  $(function() {
    var keyUpHandlers = {},
        keyDownHandlers = {};

    keyUpHandlers.Enter = function() { backend().acceptSelected(); };
    keyUpHandlers.Escape = function() { backend().dismiss(); };
    keyUpHandlers['Control-Enter'] = function() { backend().acceptInput(); };

    ['P', 'N'].forEach(function(k) {
      keyUpHandlers['Control-' + k] = function() { };
    });

    keyDownHandlers.Tab = function() {
      global.input.set(backend().complete());
    };
    keyDownHandlers['Control-P'] = function() {
      global.input.set(backend().historyPrev());
    };
    keyDownHandlers['Control-N'] = function() {
      global.input.set(backend().historyNext());
    };
    keyDownHandlers['Control-J'] = function() { backend().next(); };
    keyDownHandlers['Control-K'] = function() { backend().prev(); };
    keyDownHandlers['Control-U'] = global.input.clear;
    keyDownHandlers['Control-W'] = global.input.eraseWord;
    keyDownHandlers['Control-Y'] = function() {
      global.input.set(backend().getSelected());
    };
    keyDownHandlers['Control-R'] = global.input.alternatePattern;

    global.input.setup(function($input) {
      $input.focus().on({
        'keydown': function(e) {
          var handler = keyDownHandlers[key(e)];
          if (handler) return swallow(e, handler);
        },

        'keyup': function(e) {
          (keyUpHandlers[key(e)] || defaultHandler)();
        },

        'change': function() {
          backend().filter($input.val());
        },

        'blur': function(e) {
          e.preventDefault();
          e.stopPropagation();
          return false;
        },
      }).val($input.val());
    });

    global.entries.setup();

    function defaultHandler() {
      backend().enter(global.input.get());
    }

    function swallow(event, callback) {
      event.preventDefault();
      event.stopPropagation();
      callback();
      return false;
    }

    function key(event) {
      var mod = '';

      if (event.ctrlKey) mod += 'Control-';
      if (event.altKey) mod += 'Alt-';
      if (event.shiftKey) mod += 'Shift-';
      if (event.metaKey) mod += 'Meta-';

      return mod + keyName(event.keyCode);
    }

    function keyName(code) {
      switch (code) {
        case 8:  return 'Backspace';
        case 9:  return 'Tab';
        case 13: return 'Enter';
        case 16: return 'Shift';
        case 17: return 'Control';
        case 18: return 'Alt';
        case 27: return 'Escape';
        case 81: return 'Meta';
        default: return String.fromCharCode(code).toUpperCase();
      }
    }
  });

  function backend() {
    return global.backend;
  }

  function applyPolyfills() {
    if (!String.prototype.startsWith) {
      String.prototype.startsWith = function(searchString, position) {
        position = position || 0;
        return this.lastIndexOf(searchString, position) === position;
      };
    }

    if (!Array.prototype.includes) {
      Array.prototype.includes = function(searchElement, fromIndex) {
        var O = Object(this);
        var len = parseInt(O.length) || 0;
        if (len === 0) {
          return false;
        }
        var n = parseInt(fromIndex) || 0;
        var k;
        if (n >= 0) {
          k = n;
        } else {
          k = len + n;
          if (k < 0) {k = 0;}
        }
        var currentElement;
        while (k < len) {
          currentElement = O[k];
          if (searchElement === currentElement ||
              (searchElement !== searchElement && currentElement !== currentElement)) {
            return true;
          }
          k++;
        }
        return false;
      };
    }
  }
})(window);
