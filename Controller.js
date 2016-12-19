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
      buttons: '#editor > ul',
      exportBtn: '#editor > .menu > #exportCodeBtn',
      importBtn: '#editor > .menu > #importCodeBtn'
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
        textArea: function (element, controller) {
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
              var emojiClasses = controller.emojiClasses.getClasses();

              var code = element.innerHTML

              console.log(code);

              code = code.replace(new RegExp('&nbsp;&nbsp;&nbsp;&nbsp;', 'g'), "\t")
              code = code.replace(new RegExp('&nbsp;', 'g'), ' ')
              code = code.replace(new RegExp('<br>', 'g'), '\n')

              code = code.replace(new RegExp('&amp;', 'g'), '&').replace(new RegExp('&lt;', 'g'), '<').replace(new RegExp('&gt;', 'g'), '>').replace(new RegExp('&quot;', 'g'), '"');

              ObjectForEach(emojiClasses, function (value) {
                console.log('<img class="emoji ' + value + '">')
                code = code.replace(new RegExp('<img class="emoji ' + value + '">', 'g'), String.fromCodePoint(parseInt(value.split('_')[1], 16)))
              })

              console.log(code);

              return code
            },
            importCode: function (code) {
              var emojiClasses = controller.emojiClasses.getClasses();

              console.log(code)

              code = code.replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;')
              code = code.replace(/ /g, '&nbsp;')
              code = code.replace(/(?:\r\n|\r|\n)/g, '<br>')

              //code = code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

              ObjectForEach(emojiClasses, function (value) {
                code = code.replace(new RegExp(String.fromCodePoint(parseInt(value.split('_')[1], 16)), 'g'), "<img class='emoji " + value + "'>")
              })


              console.log(code)

              element.innerHTML = ''
              element.focus()
              pasteHtmlAtCaret(code)
            }
          }
        },
        buttons: function (element, controller) {
          var textAreaCtrl, documentCreateElement, emojiClasses

          textAreaCtrl = controller.editor.textArea
          emojiClasses = controller.emojiClasses.getClasses()
          documentCreateElement = document.createElement.bind(document)

          window.exportCode = textAreaCtrl.exportCode

          ObjectForEach(emojiClasses, function (emojiClass, emojiDescription) {
            var li = documentCreateElement('li')
            li.classList.add('emoji', emojiClass, 'tooltip')
            li.title = emojiDescription;

            //TODO: hover

            li.addEventListener('mousedown', function (e) {
              textAreaCtrl.focus()
              pasteHtmlAtCaret("<img class='emoji " + emojiClass + "'>")
              e.preventDefault()
            })

            element.appendChild(li)
          })
        },
        exportBtn: function(element, controller){
          var textAreaCtrl, downloadElement
          textAreaCtrl = controller.editor.textArea
          element.addEventListener('click', function () {
            downloadElement= document.createElement('a');
            downloadElement.setAttribute('href', 'data:text/text;charset=utf-8,' + encodeURI(textAreaCtrl.exportCode()));
            downloadElement.setAttribute('download', "Code.moj");
            downloadElement.click();
            //removeChild(downloadElement) ???
          })
        },
        importBtn: function(element, controller) {
          var textAreaCtrl = controller.editor.textArea

          element.addEventListener('change', function () {
            var file = element.files[0];
            if (file) {
              var reader = new FileReader();
              reader.readAsText(file, "UTF-8");
              reader.onload = function (evt) {
                textAreaCtrl.importCode(evt.target.result);
              }
              reader.onerror = function () {
                alert("Erro ao ler arquivo");
              }
            }

            element.value = "";
          })
        }
      }
    }
  }
)