const String miniAppBridgeJs = '''
(function() {
  if (window.opoobo && window.opoobo._bridgeReady) return;

  var _token = null;
  var _moduleName = '';
  var _moduleVersion = '';
  var _theme = 'light';
  var _userProfile = {};

  window.opoobo = {
    _bridgeReady: true,

    // ── Identity (sync) ──────────────────────────────
    get accessToken() { return _token; },
    get moduleName() { return _moduleName; },
    get moduleVersion() { return _moduleVersion; },

    // ── Sync APIs ────────────────────────────────────
    getUserProfile: function() { return Object.assign({}, _userProfile); },
    getTheme: function() { return _theme; },
    getModuleInfo: function() {
      return { name: _moduleName, version: _moduleVersion };
    },
    getPlatform: function() {
      return { os: 'unknown', appVersion: '1.0.0', locale: navigator.language };
    },

    // ── Async APIs (read-only) ──────────────────────
    getWalletBalance: function() {
      return _bridgeCall('getWalletBalance');
    },
    getSavedAddresses: function() {
      return _bridgeCall('getSavedAddresses');
    },
    getPaymentMethods: function() {
      return _bridgeCall('getPaymentMethods');
    },

    // ── Actions ──────────────────────────────────────
    requestBack: function() {
      _postMessage({ action: 'requestBack' });
    },
    showToast: function(message) {
      _postMessage({ action: 'showToast', data: { message: message } });
    },
    trackEvent: function(name, props) {
      _postMessage({ action: 'trackEvent', data: { name: name, props: props || {} } });
    },

    // ── Config (set by Flutter) ──────────────────────
    _setToken: function(token) { _token = token; },
    _setModuleInfo: function(name, version) { _moduleName = name; _moduleVersion = version; },
    _setTheme: function(theme) { _theme = theme; },
    _setUserProfile: function(profile) { _userProfile = profile || {}; },
  };

  function _postMessage(msg) {
    if (window.ReactNativeWebView) {
      window.ReactNativeWebView.postMessage(JSON.stringify(msg));
    } else if (window.flutter_inappwebview) {
      window.flutter_inappwebview.postMessage(JSON.stringify(msg));
    }
  }

  function _bridgeCall(method) {
    return new Promise(function(resolve, reject) {
      var callId = method + '_' + Date.now();
      var handler = function(event) {
        if (event.data && event.data.callId === callId) {
          window.removeEventListener('message', handler);
          if (event.data.error) reject(event.data.error);
          else resolve(event.data.result);
        }
      };
      window.addEventListener('message', handler);
      _postMessage({ action: method, callId: callId });
      setTimeout(function() {
        window.removeEventListener('message', handler);
        reject('Bridge call timed out');
      }, 10000);
    });
  }

  // Dispatch ready event
  setTimeout(function() {
    window.dispatchEvent(new CustomEvent('opoobo:ready', {
      detail: { moduleName: _moduleName }
    }));
    window.dispatchEvent(new CustomEvent('opoobo:tokenReady', {
      detail: { accessToken: _token, moduleName: _moduleName }
    }));
  }, 0);
})();
''';
