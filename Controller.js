'use strict';

(function (window, utilFactory, selectors, controllerFactory) {
  var util = utilFactory(window)
  var $ = util.querySelector
  var ObjectForEach = util.ObjectForEach

  function setUp () {
    var controllers = controllerFactory(window, util)
    var elements = {}

    ObjectForEach(selectors, function(elem, key, selectors, traversedKeys) {
      elements[traversedKeys] = $(selectors[key])
    })

    ObjectForEach(
      controllers,
      function(controllerSetUp, key, controller, traversedKeys) {
        controller[key] = controllerSetUp(
          elements[traversedKeys],
          controllers,
          selectors
        )
      }
    )
  }

  switch (document.readyState) {
    case "loading":
      window.document.addEventListener('DOMContentLoaded', setUp)
      break;
    case "interactive":
    case "complete":
      setUp()
  }
})(
  // Window Object
  typeof window === 'object' ? window : this,
  // Utilities functions factory
  function utilFactory (window) {
    var document = window.document
    var ObjectKeys = Object.keys

    function ObjectForEach (obj, func, _traversedKeys) {
      var keys, length, key, elem, i, traversedKeys

      if (typeof _traversedKeys !== 'string') {
        traversedKeys = ''
      } else {
        traversedKeys = _traversedKeys + '.'
      }

      keys = ObjectKeys(obj)
      length = keys.length
      i = -1

      while(++i < length) {
        key = keys[i]
        elem = obj[key]

        if (typeof elem === 'object' && elem !== null) {
          ObjectForEach(elem, func, traversedKeys + key)
        } else {
          func(elem, key, obj, traversedKeys + key)
        }
      }
    }

    function querySelector (scope, selector, all) {
      if (typeof scope === 'object') {
        if (scope === null ||
          !(scope instanceof window.Document) ||
          !(scope instanceof window.Element)
        ) {
          scope = document
        }
      } else {
        if (typeof scope === 'string') selector = scope
        scope = document
      }

      return all
        ? scope.querySelectorAll(selector)
        : scope.querySelector(selector)
    }

    function pasteHtmlAtCaret(html) {
      var sel, range;
      if (window.getSelection) {
        // IE9 and non-IE
        sel = window.getSelection();
        if (sel.getRangeAt && sel.rangeCount) {
          range = sel.getRangeAt(0);
          range.deleteContents();

          // Range.createContextualFragment() would be useful here but is
          // non-standard and not supported in all browsers (IE9, for one)
          var el = document.createElement("div");
          el.innerHTML = html;
          var frag = document.createDocumentFragment(), node, lastNode;
          while ( (node = el.firstChild) ) {
            lastNode = frag.appendChild(node);
          }
          range.insertNode(frag);

          // Preserve the selection
          if (lastNode) {
            range = range.cloneRange();
            range.setStartAfter(lastNode);
            range.collapse(true);
            sel.removeAllRanges();
            sel.addRange(range);
          }
        }
      } else if (document.selection && document.selection.type != "Control") {
        // IE < 9
        document.selection.createRange().pasteHTML(html);
      }
    }

    return {
      ObjectForEach: ObjectForEach,
      querySelector: querySelector,
      pasteHtmlAtCaret: pasteHtmlAtCaret
    }
  },
  /**
   * Element's selectors
   *
   * A collection of selectors, which will be replaced by their referenced
   * elements.
   */
  {
    editor: {
      textArea: '#editor > .textArea',
      buttons: '#editor > ul'
    },
    emojiClasses: '#emojiClasses'
  },
  /**
   * Controller factory
   *
   * This is where all page element controllers reside
   */
  function controllerFactor (window, util) {
    var document = window.document
    var ObjectForEach = util.ObjectForEach
    var pasteHtmlAtCaret = util.pasteHtmlAtCaret

    return {
      emojiClasses: function (element) {
        var emojiClasses = JSON.parse(element.dataset.class)

        return {
          getClasses: function () {
            return emojiClasses
          }
        }
      },
      editor: {
        textArea: function (element) {
          var textAreaLastRange = null

          element.focus()

          element.addEventListener('focusout', function () {
            var selection = window.getSelection()
            textAreaLastRange = selection.rangeCount > 0
              ? selection.getRangeAt(0)
              : null;
          })

          element.addEventListener('focus', function () {
            var selection

            if (textAreaLastRange) {
              selection = window.getSelection()
              selection.removeAllRanges()
              selection.addRange(textAreaLastRange)
            }
          })

          return {
            focus: HTMLElement.prototype.focus.bind(element),
            appendChild: Node.prototype.appendChild.bind(element),
            exportCode: function () {
              var code = ''
              var emojiClass

              element.childNodes.forEach(function (node) {
                console.log(node)
                if (node instanceof window.Text) {
                  code += node.nodeValue
                } else if (node instanceof HTMLElement) {
                  console.log(node.tagName)
                  switch (node.tagName) {
                    case 'BR':
                      code += '\n'
                      break;
                    case 'IMG':
                      emojiClass = node.classList[1].replace('emoji_', '')
                      code += String.fromCharCode(parseInt(emojiClass, 16))
                  }
                }
              })

              return code
            }
            // TODO: appendText
          }
        },
        buttons: function (element, controller) {
          var textAreaCtrl, documentCreateElement, emojiClasses

          textAreaCtrl = controller.editor.textArea
          emojiClasses = controller.emojiClasses.getClasses()
          documentCreateElement = document.createElement.bind(document)

          window.exportCode = textAreaCtrl.exportCode

          ObjectForEach(emojiClasses, function (emojiClass) {
            var li = documentCreateElement('li')
            li.classList.add('emoji', emojiClass)

            //TODO: hover

            li.addEventListener('mousedown', function (e) {
              textAreaCtrl.focus()
              pasteHtmlAtCaret("<img class='emoji " + emojiClass + "'></img>")
              e.preventDefault()
            })

            element.appendChild(li)
          })
        }
      }
    }
  }
)