/* global console */
/* global backend */

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
    acceptInput: function(input) {
      console.log('send input for backend acceptance: ' + input);
    },
    acceptSelected: function() {
      console.log('tell backend to accept selected item');
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

  var $input,
      $entries,
      $scrollbar,
      availableScroll,
      currentMode,
      keyUpHandlers = {},
      keyDownHandlers = {};

  keyUpHandlers.Enter = function() { backend.acceptSelected(); };
  keyUpHandlers.Escape = function() { backend.dismiss(); };

  ['P', 'N'].forEach(function(k) {
    keyUpHandlers['Control-' + k] = function() { };
  });

  keyDownHandlers.Tab = function() {
    $input.val(backend.complete()).change();
  };
  keyDownHandlers['Control-P'] = function() {
    $input.val(backend.historyPrev()).change();
  };
  keyDownHandlers['Control-N'] = function() {
    $input.val(backend.historyNext()).change();
  };
  keyDownHandlers['Control-J'] = function() { backend.next(); };
  keyDownHandlers['Control-K'] = function() { backend.prev(); };
  keyDownHandlers['Control-Y'] = function() { backend.acceptInput(); };
  keyDownHandlers['Control-U'] = function() { $input.val('').change(); };
  keyDownHandlers['Control-W'] = function() { sendCtrlBs($input); };

  return {
    init: function() {
      $(function() {
        $entries = $('#entries');
        $input = $('#input');
        $scrollbar = $('#scrollbar');

        function swallow(event, callback) {
          event.preventDefault();
          event.stopPropagation();
          callback();
          return false;
        }

        $input.focus().on({
          'keydown': function(e) {
            var handler = keyDownHandlers[key(e)];
            if (handler) return swallow(e, handler);
          },

          'keyup': function(e) {
            (keyUpHandlers[key(e)] || defaultHandler)();
          },

          'change': function() {
            backend.filter($input.val());
          },

          'blur': function() {
            setTimeout(function() { $input.focus(); }, 0);
          },
        });

        $input.val($input.val()).change();

        $(window).on('resize', window.frontend.adjustScroll);
        $entries.on('scroll', window.frontend.adjustScroll);
      });
    },

    setItems: function(items) {
      var entries = items.map(function(item) {
        /* jshint camelcase: false */
        var $li = $(document.createElement('li'));

        item.merged_spans.forEach(function(span) {
          $li.append($(document.createElement('span')).text(span.nohl));
          $li.append($(document.createElement('span')).addClass('hl')
            .text(span.hl));
        });

        if (item.selected) {
          $li.addClass('selected');
        }

        return $li;
      });

      $entries.html(entries);

      if (entries.length) {
        $input.parent().removeClass('not-found');
      } else {
        $input.parent().addClass('not-found');
      }

      this.adjustScroll();
    },

    switchPrompt: function(newPrompt) {
      $('#prompt').text(newPrompt);
    },

    reportMode: function(newMode) {
      if (currentMode) {
        $input.removeClass(currentMode + '-mode');
      }

      $input.addClass(newMode + '-mode');

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
      $entries.find('li.selected').removeClass('selected');
      this.ensureVisible(
        $entries.find('li:nth-child(' + (index + 1) + ')').addClass('selected')
      );
    },

    ensureVisible: function($item) {
      var top = $item.offset().top - $entries.offset().top,
          eh = $entries.height(),
          bottom = top + $item.outerHeight() - eh,
          current = $entries.scrollTop(),
          scroll = current + (bottom >= 0 ? bottom : (top < 0 ? top : 0));

      $entries.scrollTop(scroll);
    },

    adjustScroll: function() {
      var height = $entries.height(), scroll = $entries.scrollTop();

      availableScroll = Array.prototype.slice.call(
        $entries.find('> li').map(function(i, el) {
          return $(el).outerHeight();
        })
      ).reduce(function(a, b) { return a + b; }, 0);

      if (availableScroll > 0 && availableScroll > height) {
        var thumbHeight = 100 * height / availableScroll,
            top = 100 * scroll / availableScroll;

        $scrollbar.find('.thumb').show().css({
          height: thumbHeight + '%',
          top: top + '%',
        });
      } else {
        $scrollbar.find('.thumb').hide().css({ height: 0, top: 0 });
      }
    },
  };

  function defaultHandler() {
    backend.enter($input.val());
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
    console.log(evt);

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
