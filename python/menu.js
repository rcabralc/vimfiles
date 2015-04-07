/* global console */
/* global backend */

if (!String.prototype.startsWith) {
  String.prototype.startsWith = function(searchString, position) {
    "use strict";
    position = position || 0;
    return this.lastIndexOf(searchString, position) === position;
  };
}

window.backend = (function() {
  // Stub backend implementation.
  "use strict";

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
    copySelected: function() {
      console.log('tell backend to copy selected item');
    },
    complete: function() {
      console.log('tell backend to complete current input');
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
  };
})();

window.frontend = (function() {
  "use strict";

  var _$input,
      _$entries,
      _$scrollbar,
      availableScroll,
      currentMode,
      keyUpHandlers = {},
      keyDownHandlers = {},
      // This order is important: iterated from right to left, no ambiguity
      // should happen.  For example: '!=' must be tested before '!', otherwise
      // '!' could inavertendly match '!='.  In summary, an item should not
      // start with any item on right of it.
      patternTypes = ['!', '=', '!=', '@'];

  keyUpHandlers.Enter = function() { backend.acceptSelected(); };
  keyUpHandlers.Escape = function() { backend.dismiss(); };
  keyUpHandlers['Control-Enter'] = function() { backend.acceptInput(); };

  ['P', 'N'].forEach(function(k) {
    keyUpHandlers['Control-' + k] = function() { };
  });

  keyDownHandlers.Tab = function() {
    $input().val(backend.complete()).change();
  };
  keyDownHandlers['Control-P'] = function() {
    $input().val(backend.historyPrev()).change();
  };
  keyDownHandlers['Control-N'] = function() {
    $input().val(backend.historyNext()).change();
  };
  keyDownHandlers['Control-J'] = function() { backend.next(); };
  keyDownHandlers['Control-K'] = function() { backend.prev(); };
  keyDownHandlers['Control-U'] = function() { $input().val('').change(); };
  keyDownHandlers['Control-W'] = function() { sendCtrlBs($input()); };
  keyDownHandlers['Control-Y'] = function() { backend.copySelected(); };
  keyDownHandlers['Control-R'] = function() { alternatePattern(); };

  $(function() {
    $input().focus().on({
      'keydown': function(e) {
        var handler = keyDownHandlers[key(e)];
        if (handler) return swallow(e, handler);
      },

      'keyup': function(e) {
        (keyUpHandlers[key(e)] || defaultHandler)();
      },

      'change': function() {
        backend.filter($input().val());
      },

      'blur': function(e) {
        e.preventDefault();
        e.stopPropagation();
        return false;
      },
    }).val($input().val());

    $(window).on('resize', window.frontend.adjustScroll);
    $entries().on('scroll', window.frontend.adjustScroll);
  });

  return {
    setInput: function(input) {
      $input().val(input).focus();
    },

    setItems: function(items) {
      var entries = items.map(function(item) {
        /* jshint camelcase: false */
        var $li = $(document.createElement('li'));

        item.matches.forEach(function(span) {
          $li.append($(document.createElement('span')).text(span.unmatched));
          $li.append($(document.createElement('span')).addClass('hl')
            .text(span.matched));
        });

        if (item.selected) {
          $li.addClass('selected');
        }

        return $li;
      });

      $entries().html(entries);
      // $entries().prepend('<li>' + window.backend.id() + '</li>');

      if (entries.length) {
        $input().parent().removeClass('not-found');
      } else {
        $input().parent().addClass('not-found');
      }

      this.adjustScroll();
    },

    switchPrompt: function(newPrompt) {
      $('#prompt').text(newPrompt);
    },

    reportMode: function(newMode) {
      if (currentMode) {
        $input().removeClass(currentMode + '-mode');
      }

      $input().addClass(newMode + '-mode');
      currentMode = newMode;
    },

    overLimit: function() {
      $('#prompt').addClass('over-limit');
    },

    underLimit: function() {
      $('#prompt').removeClass();
    },

    updateCounters: function(selected, total) {
      $('#counters').text(selected + '/' + total);
    },

    select: function(index) {
      $entries().find('li.selected').removeClass('selected');
      this.ensureVisible(
        $entries().find('li:nth-child(' + (index + 1) + ')').addClass('selected')
      );
    },

    ensureVisible: function($item) {
      var top = $item.offset().top - $entries().offset().top,
          eh = $entries().height(),
          bottom = top + $item.outerHeight() - eh,
          current = $entries().scrollTop(),
          scroll = current + (bottom >= 0 ? bottom : (top < 0 ? top : 0));

      $entries().scrollTop(scroll);
    },

    adjustScroll: function() {
      var height = $entries().height(), scroll = $entries().scrollTop();

      availableScroll = Array.prototype.slice.call(
        $entries().find('> li').map(function(i, el) {
          return $(el).outerHeight();
        })
      ).reduce(function(a, b) { return a + b; }, 0);

      if (availableScroll > 0 && availableScroll > height) {
        var thumbHeight = 100 * height / availableScroll,
            top = 100 * scroll / availableScroll;

        $scrollbar().find('.thumb').show().css({
          height: thumbHeight + '%',
          top: top + '%',
        });
      } else {
        $scrollbar().find('.thumb').hide().css({ height: 0, top: 0 });
      }
    },
  };

  function $input() {
    return (_$input = _$input || $('#input'));
  }

  function $entries() {
    return (_$entries = _$entries || $('#entries'));
  }

  function $scrollbar() {
    return (_$scrollbar = _$scrollbar || $('#scrollbar'));
  }

  function swallow(event, callback) {
    event.preventDefault();
    event.stopPropagation();
    callback();
    return false;
  }

  function defaultHandler() {
    backend.enter($input().val());
  }

  function alternatePattern() {
    var $field = $input(),
        field = $field.get(0),
        value = $field.val(),
        pos = field.selectionDirection == 'backward' ?
          field.selectionStart : field.selectionEnd,
        lpos = pos, rpos,
        str, i, pat;

    while (lpos > 0) {
      if (value[lpos - 1] == ' ') break;
      lpos -= 1;
    }
    while (value[lpos] == ' ') lpos += 1;

    rpos = lpos;
    while (rpos < value.length - 1) {
      if (value[rpos] == ' ') break;
      rpos += 1;
    }
    while (value[rpos] == ' ') rpos -= 1;

    str = value.slice(lpos, rpos + 1);
    for (i = patternTypes.length - 1; i >= 0; i--) {
      pat = patternTypes[i];
      if (str.startsWith(pat)) {
        str = str.slice(pat.length);
        if (i == patternTypes.length - 1) {
          pat = '';
        } else {
          pat = patternTypes[i + 1];
        }
        str = pat + str;
        replace(lpos, rpos, str);
        return;
      }
    }

    str = patternTypes[0] + str;
    replace(lpos, rpos, str);

    function replace(lpos, rpos, str) {
      $field.val(value.slice(0, lpos) + str + value.slice(rpos + 1));
      field.selectionStart = lpos + str.length;
      field.selectionEnd = field.selectionStart;
    }
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

  function keyCode(name) {
    switch (name) {
      case 'Backspace': return 8;
      case 'Tab':       return 9;
      case 'Enter':     return 13;
      case 'Shift':     return 16;
      case 'Control':   return 17;
      case 'Alt':       return 18;
      case 'Escape':    return 27;
      case 'Meta':      return 81;
      default:          return name.toUpperCase().charCodeAt(0);
    }
  }

  function keyIdentifier(key) {
    switch (key) {
      case 'Enter':
      case 'Control':
      case 'Alt':
      case 'Shift':
      case 'Meta':
      case 'AltGraph':
        return key;
      default:
        return "U+" + ("000000" + keyCode(key).toString(16)).slice(-6);
    }
  }

  function sendCtrlBs($node) {
    $node.eq(0).focus();
    sendKeyEvent('Control',   'keydown',  $node);
    sendKeyEvent('Backspace', 'keydown',  $node);
    sendKeyEvent('Backspace', 'keypress', $node);
    sendKeyEvent('Backspace', 'keyup',    $node);
    sendKeyEvent('Control',   'keyup',    $node);
  }

  function sendKeyEvent(key, type, $node) {
    /* global KeyboardEvent */

    var evt, node = $node[0];

    evt = document.createEvent('KeyboardEvent');
    evt.initKeyboardEvent(
      type, // event type : keydown, keyup, keypress
      true, // bubbles
      true, // cancelable
      window, // window object
      keyIdentifier(key), // key identifier
      KeyboardEvent.DOM_KEY_LOCATION_STANDARD, // location, 0
      isCtrl(key),
      isAlt(key),
      isShift(key),
      isMeta(key),
      false // altGraph
    );

    node.dispatchEvent(evt);
  }

  function isCtrl(name) {
    return /Control-/.test(name);
  }

  function isAlt(name) {
    return /Alt-/.test(name);
  }

  function isShift(name) {
    return /Shift-/.test(name);
  }

  function isMeta(name) {
    return /Meta-/.test(name);
  }
})();
