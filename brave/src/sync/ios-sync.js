
console.log = (function (old_function) {
    return function (text) {
        old_function(text);
        document.write("<div style='font-size:25'>"+ text +"</div>");
    };
} (console.log.bind(console)));



if (!self.chrome || !self.chrome.ipc) {
    var initCb = () => {}
    // Saved crypto seed; byteArray
    var seed = new Uint8Array([243, 203, 185, 143, 101, 184, 134, 109, 69, 166, 218, 58, 63, 155, 158, 17, 31, 184, 175, 52, 73, 80, 190, 47, 45, 12, 59, 64, 130, 13, 146, 248])
    // Saved deviceId; byteArray
    var deviceId = null

    self.chrome = {}
    const ipc = {}
    ipc.on = (message, cb) => {
        if (message === 'got-init-data') {
            if (cb) {
                initCb = cb
            }
            initCb(null, seed, deviceId, braveSyncConfig)
        }
    }
    ipc.send = (message, arg1, arg2) => {
        if (message === 'save-init-data') {
            seed = arg1
            deviceId = arg2
            ipc.on('got-init-data')
        }
    }
    self.chrome.ipc = ipc

    chrome.ipcRenderer = chrome.ipc
}



