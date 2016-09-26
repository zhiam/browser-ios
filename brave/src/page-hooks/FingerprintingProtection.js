/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

function reportBlock (msg) {
    if (Window.prototype.hasOwnProperty('__bravejs___fingerprinting')) {
        __bravejs___fingerprinting(msg)
    }
}

/**
* Monitor the reads from a canvas instance
* @param item special item objects
*/
function trapInstanceMethod (item) {
    item.obj[item.propName] = (function (orig) {
      return function () {
        var msg = {
          obj: item.objName,
          prop: item.propName,
        }

        // Block the read from occuring; send info to background page instead
        console.log('blocking canvas read', msg)
        reportBlock(msg)
      }
    }(item.obj[item.propName]))
}

var methods = []
var canvasMethods = ['getImageData', 'getLineDash', 'measureText']
canvasMethods.forEach(function (method) {
    var item = {
    type: 'Canvas',
    objName: 'CanvasRenderingContext2D.prototype',
    propName: method,
    obj: window.CanvasRenderingContext2D.prototype
    }

    methods.push(item)
})

var canvasElementMethods = ['toDataURL', 'toBlob']
canvasElementMethods.forEach(function (method) {
    var item = {
    type: 'Canvas',
    objName: 'HTMLCanvasElement.prototype',
    propName: method,
    obj: window.HTMLCanvasElement.prototype
    }
    methods.push(item)
})

var webglMethods = ['getSupportedExtensions', 'getParameter', 'getContextAttributes',
    'getShaderPrecisionFormat', 'getExtension']
webglMethods.forEach(function (method) {
    var item = {
    type: 'WebGL',
    objName: 'WebGLRenderingContext.prototype',
    propName: method,
    obj: window.WebGLRenderingContext.prototype
    }
    methods.push(item)
})

var audioBufferMethods = ['copyFromChannel', 'getChannelData']
audioBufferMethods.forEach(function (method) {
    var item = {
    type: 'AudioContext',
    objName: 'AudioBuffer.prototype',
    propName: method,
    obj: window.AudioBuffer.prototype
    }
    methods.push(item)
})

var analyserMethods = ['getFloatFrequencyData', 'getByteFrequencyData',
    'getFloatTimeDomainData', 'getByteTimeDomainData']
analyserMethods.forEach(function (method) {
    var item = {
    type: 'AudioContext',
    objName: 'AnalyserNode.prototype',
    propName: method,
    obj: window.AnalyserNode.prototype
    }
    methods.push(item)
})

methods.forEach(trapInstanceMethod)


/**
 * Stubs iframe methods that can be used for canvas fingerprinting.
 * @param {HTMLIFrameElement} frame
 */
function trapIFrameMethods (frame) {
    console.log('trapIFrameMethods')
    var items = [{
            type: 'Canvas',
            objName: 'contentDocument',
            propName: 'createElement',
            obj: frame.contentDocument
        }, {
            type: 'Canvas',
            objName: 'contentDocument',
            propName: 'createElementNS',
            obj: frame.contentDocument
        }]
    items.forEach(function (item) {
        var orig = item.obj[item.propName]
        item.obj[item.propName] = function () {
            var args = arguments
            var lastArg = args[args.length - 1]
            if (lastArg && lastArg.toLowerCase() === 'canvas') {
                // Prevent fingerprinting using contentDocument.createElement('canvas'),
                // which evades trapInstanceMethod when the iframe is sandboxed
                reportBlock({ obj: item.objName, propName: item.propName })
            } else {
                // Otherwise apply the original method
                return orig.apply(this, args)
            }
        }
    })
}

Array.from(document.querySelectorAll('iframe')).forEach(trapIFrameMethods)




