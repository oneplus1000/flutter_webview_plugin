import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _kChannel = 'flutter_webview_plugin';

// TODO: more general state for iOS/android
enum WebViewState { shouldStart, startLoad, finishLoad }

// TODO: use an id by webview to be able to manage multiple webview

/// Singleton Class that communicate with a Webview Instance
/// Have to be instanciate after `runApp` called.
class FlutterWebviewPlugin {
  final _channel = const MethodChannel(_kChannel);

  final _onDestroy = new StreamController<Null>.broadcast();
  final _onUrlChanged = new StreamController<String>.broadcast();
  final _onStateChanged = new StreamController<WebViewStateChanged>.broadcast();
  final _onScrollXChanged = new StreamController<ScrollData>.broadcast();
  final _onScrollYChanged = new StreamController<ScrollData>.broadcast();
  final _onScrollXViewWillEndDragging =
      new StreamController<ScrollData>.broadcast();
  final _onScrollYViewWillEndDragging =
      new StreamController<ScrollData>.broadcast();
  final _onHttpError = new StreamController<WebViewHttpError>.broadcast();
  final _onJsCallFlutter = new StreamController<WebViewJsCall>.broadcast();

  static FlutterWebviewPlugin _instance;

  factory FlutterWebviewPlugin() => _instance ??= new FlutterWebviewPlugin._();

  FlutterWebviewPlugin._() {
    _channel.setMethodCallHandler(_handleMessages);
  }

  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onDestroy':
        _onDestroy.add(null);
        break;
      case 'onUrlChanged':
        _onUrlChanged.add(call.arguments['url']);
        break;
      case 'onScrollXChanged':
        final pos = ScrollData();
        pos.position = call.arguments['xDirection'];
        pos.isTouch = call.arguments['isTouch'];
        _onScrollXChanged.add(pos);
        break;
      case 'onScrollYChanged':
        final pos = ScrollData();
        pos.position = call.arguments['yDirection'];
        pos.isTouch = call.arguments['isTouch'];
        _onScrollYChanged.add(pos);
        break;
      case 'onState':
        _onStateChanged.add(
          new WebViewStateChanged.fromMap(
              new Map<String, dynamic>.from(call.arguments)),
        );
        break;
      case 'onHttpError':
        _onHttpError.add(
            WebViewHttpError(call.arguments['code'], call.arguments['url']));
        break;
      case 'scrollXViewWillEndDragging':
        var pos = ScrollData();
        pos.position = call.arguments['xDirection'];
        pos.isTouch = call.arguments['isTouch'];
        _onScrollXViewWillEndDragging.add(pos);
        break;
      case 'scrollYViewWillEndDragging':
        var pos = ScrollData();
        pos.position = call.arguments['yDirection'];
        pos.isTouch = call.arguments['isTouch'];
        _onScrollYViewWillEndDragging.add(pos);
        break;
      case 'onJsCallFlutter':
        _jsCallFlutterFuncHandle(call);
        break;
    }
  }

  Future<void> _jsCallFlutterFuncHandle(MethodCall call) async {
    final Map map = call.arguments;
    final String funcname = map['funcname'];
    final jscall = WebViewJsCall();
    jscall.funcname = funcname;
    if (map['argsType'] is List) {
      for (var item in map['argsType']) {
        if (item is String) {
          jscall.argsType.add(item);
        }
      }
    }
    if (map['argsVal'] is List) {
      for (var item in map['argsVal']) {
        if (item is String) {
          jscall.argsVal.add(item);
        }
      }
    }

    if (map['argsCount'] is double) {
      jscall.argsCount = map['argsCount'].round(); //ยังไงมันก็เป็น int
    }

    _onJsCallFlutter.add(jscall);
  }

  /// Listening the OnDestroy LifeCycle Event for Android
  Stream<Null> get onDestroy => _onDestroy.stream;

  /// Listening url changed
  Stream<String> get onUrlChanged => _onUrlChanged.stream;

  /// Listening the onState Event for iOS WebView and Android
  /// content is Map for type: {shouldStart(iOS)|startLoad|finishLoad}
  /// more detail than other events
  Stream<WebViewStateChanged> get onStateChanged => _onStateChanged.stream;

  /// Listening web view y position scroll change
  Stream<ScrollData> get onScrollYChanged => _onScrollYChanged.stream;

  /// Listening web view x position scroll change
  Stream<ScrollData> get onScrollXChanged => _onScrollXChanged.stream;

  Stream<ScrollData> get onScrollXViewWillEndDragging =>
      _onScrollXViewWillEndDragging.stream;
  Stream<ScrollData> get onScrollYViewWillEndDragging =>
      _onScrollYViewWillEndDragging.stream;

  Stream<WebViewHttpError> get onHttpError => _onHttpError.stream;

  Stream<WebViewJsCall> get onJsCallFlutter => _onJsCallFlutter.stream;

  /// Start the Webview with [url]
  /// - [headers] specify additional HTTP headers
  /// - [withJavascript] enable Javascript or not for the Webview
  ///     iOS WebView: Not implemented yet
  /// - [clearCache] clear the cache of the Webview
  /// - [clearCookies] clear all cookies of the Webview
  /// - [hidden] not show
  /// - [rect]: show in rect, fullscreen if null
  /// - [enableAppScheme]: false will enable all schemes, true only for httt/https/about
  ///     android: Not implemented yet
  /// - [userAgent]: set the User-Agent of WebView
  /// - [withZoom]: enable zoom on webview
  /// - [withLocalStorage] enable localStorage API on Webview
  ///     Currently Android only.
  ///     It is always enabled in UIWebView of iOS and  can not be disabled.
  /// - [withLocalUrl]: allow url as a local path
  ///     Allow local files on iOs > 9.0
  /// - [scrollBar]: enable or disable scrollbar
  Future<Null> launch(
    String url, {
    Map<String, String> headers,
    bool withJavascript,
    bool clearCache,
    bool clearCookies,
    bool hidden,
    bool enableAppScheme,
    Rect rect,
    String userAgent,
    bool withZoom,
    bool withLocalStorage,
    bool withLocalUrl,
    bool scrollBar,
    int viewpageCount,
  }) async {
    final args = <String, dynamic>{
      'url': url,
      'withJavascript': withJavascript ?? true,
      'clearCache': clearCache ?? false,
      'hidden': hidden ?? false,
      'clearCookies': clearCookies ?? false,
      'enableAppScheme': enableAppScheme ?? true,
      'userAgent': userAgent,
      'withZoom': withZoom ?? false,
      'withLocalStorage': withLocalStorage ?? true,
      'withLocalUrl': withLocalUrl ?? false,
      'scrollBar': scrollBar ?? true,
      'viewpageCount': viewpageCount ?? 0,
    };

    if (headers != null) {
      args['headers'] = headers;
    }

    if (rect != null) {
      args['rect'] = {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height
      };
    }
    await _channel.invokeMethod('launch', args);
  }

  /// Execute Javascript inside webview
  Future<String> evalJavascript(String code) async {
    final res = await _channel.invokeMethod('eval', {'code': code});
    return res;
  }

  /// Close the Webview
  /// Will trigger the [onDestroy] event
  Future close() => _channel.invokeMethod('close');

  /// Reloads the WebView.
  /// This is only available on Android for now.
  Future reload() => _channel.invokeMethod('reload');

  /// Navigates back on the Webview.
  /// This is only available on Android for now.
  Future goBack() => _channel.invokeMethod('back');

  /// Navigates forward on the Webview.
  /// This is only available on Android for now.
  Future goForward() => _channel.invokeMethod('forward');

  // Hides the webview
  Future hide() => _channel.invokeMethod('hide');

  // Shows the webview
  Future show() => _channel.invokeMethod('show');

  // Reload webview with a new url
  Future reloadUrl(String url) async {
    final args = <String, String>{'url': url};
    await _channel.invokeMethod('reloadUrl', args);
  }

  Future<bool> touchInfo() async {
    bool result = await _channel.invokeMethod('touchInfo');
    return result;
  }

  Future setContentOffset(double x, double y) async {
    final args = <String, double>{
      'x': x,
      'y': y,
    };
    await _channel.invokeMethod('setContentOffset', args);
  }

  // Stops current loading process
  Future stopLoading() => _channel.invokeMethod("stopLoading");

  /// adds the plugin as ActivityResultListener
  /// Only needed and used on Android
  Future registerAcitivityResultListener() =>
      _channel.invokeMethod('registerAcitivityResultListener');

  /// removes the plugin as ActivityResultListener
  /// Only needed and used on Android
  Future removeAcitivityResultListener() =>
      _channel.invokeMethod('removeAcitivityResultListener');

  /// Close all Streams
  void dispose() {
    _onDestroy.close();
    _onUrlChanged.close();
    _onStateChanged.close();
    _onScrollXChanged.close();
    _onScrollYChanged.close();
    _onHttpError.close();
    _instance = null;
  }

  Future<Map<String, String>> getCookies() async {
    final cookiesString = await evalJavascript('document.cookie');
    final cookies = <String, String>{};

    if (cookiesString?.isNotEmpty == true) {
      cookiesString.split(';').forEach((String cookie) {
        final splited = cookie.split('=');
        cookies[splited[0]] = splited[1];
      });
    }

    return cookies;
  }

  /// resize webview
  Future<Null> resize(Rect rect) async {
    final args = {};
    args['rect'] = {
      'left': rect.left,
      'top': rect.top,
      'width': rect.width,
      'height': rect.height
    };
    await _channel.invokeMethod('resize', args);
  }
}

class WebViewStateChanged {
  final WebViewState type;
  final String url;
  final int navigationType;

  WebViewStateChanged(this.type, this.url, this.navigationType);

  factory WebViewStateChanged.fromMap(Map<String, dynamic> map) {
    WebViewState t;
    switch (map['type']) {
      case 'shouldStart':
        t = WebViewState.shouldStart;
        break;
      case 'startLoad':
        t = WebViewState.startLoad;
        break;
      case 'finishLoad':
        t = WebViewState.finishLoad;
        break;
    }
    return new WebViewStateChanged(t, map['url'], map['navigationType']);
  }
}

class WebViewHttpError {
  final String url;
  final String code;
  WebViewHttpError(this.code, this.url);
}

class WebViewJsCall {
  String funcname;
  int argsCount;
  List<String> argsType = [];
  List<String> argsVal = [];
}

class ScrollData {
  double position;
  bool isTouch;
}
