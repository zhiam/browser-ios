/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* eslint no-unused-vars: [2, {"varsIgnorePattern": "replaceDivWithNewContent"}] */

function _brave_replaceDivWithNewContent(replacerObject) {
  var divId = replacerObject.divId;
  var width = replacerObject.width;
  var height = replacerObject.height;
  var replacementUrl = replacerObject.replacementUrl;
  
  var selector = '[id="' + divId + '"]';
  var node = document.querySelector(selector);
  if (node) {
    // generate a random segment
    // @todo - replace with renko targeting
    var segments = ['IAB2', 'IAB17', 'IAB14', 'IAB21', 'IAB20']
    var segment = segments[Math.floor(Math.random() * 4)]
    var time_in_segment = new Date().getSeconds()
    var segment_expiration_time = 0 // no expiration
    
    // ref param for referrer when possible
    var srcUrl = replacementUrl + '?width=' + width + '&height=' + height + '&seg=' + segment + ':' + time_in_segment + ':' + segment_expiration_time
    
    console.log('------tag name: ' + node.tagName);
    var xhttp = new XMLHttpRequest()
    xhttp.onreadystatechange = function() {
      if (xhttp.readyState == 4 && xhttp.status == 200) {
        var src = '<html><body style="width: ' + width + 'px; height: ' + height +
        '; padding: 0; margin: 0; overflow: hidden;">' + xhttp.responseText + '</body></html>'
        var sandbox = 'allow-scripts allow-popups allow-popups-to-escape-sandbox'
        if (node.tagName === 'IFRAME') {
          node.srcdoc = src
          node.sandbox = sandbox
        } else {
          while (node.firstChild) {
            node.removeChild(node.firstChild)
          }
          var iframe = document.createElement('iframe')
          iframe.style.padding = 0
          iframe.style.border = 0
          iframe.style.margin = 0
          iframe.style.width = width + 'px'
          iframe.style.height = height + 'px'
          iframe.srcdoc = src
          iframe.sandbox = sandbox
          node.appendChild(iframe)
        }
      }
    }
    xhttp.open("GET", srcUrl, true)
    xhttp.send()
  } else {
    console.log('-------selector null: ' + selector);
  }
}
