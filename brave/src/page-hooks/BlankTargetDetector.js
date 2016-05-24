/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// based on article http://www.icab.de/blog/2009/08/05/webkit-on-the-iphone-part-2

(function() {
  var links = document.getElementsByTagName('a');
  for (var i = 0; links && i < links.length; i++) {
    var link = links[i];
    var target = link.getAttribute('target');
    if (target && target == '_blank') {
        return true;
    }
  }
  return false;
})()
