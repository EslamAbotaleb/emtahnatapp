import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/foundation.dart' show kReleaseMode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // if (kDebugMode) {
  //   FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);//disable false
  // }else{
  //   FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  // }
// enableInDevMode
  if (!kReleaseMode)
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
// Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runZoned(() {
    runApp(EmtahnatApp());
  }, onError: (error) {
    // print(error);
    print("It's not so bad but good in this also not so big.");
    print("Problem still exists: $error");
    // FirebaseCrashlytics.instance.recordFlutterError;
  });

  // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
// runApp(
//   EmtahnatApp()
//   );
}

class EmtahnatApp extends StatefulWidget {
  @override
  _EmtahnatAppState createState() => _EmtahnatAppState();
}

class _EmtahnatAppState extends State<EmtahnatApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // FirebaseCrashlytics.instance.crash();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: MaterialApp(
            debugShowCheckedModeBanner: false, home: WebViewExample()));
  }
}

class WebViewExample extends StatefulWidget {
  @override
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  @override
  void initState() {
    super.initState();

    SystemChannels.textInput.invokeMethod('TextInput.hide');

    disableCapture();
    configureCallbacks();
    subscribeToTopic();
    // if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  void configureCallbacks() {
    _firebaseMessaging.configure(onMessage: (message) async {
      print('onMessage:$message');
    }, onResume: (message) async {
      print('onResume : $message');
    }, onLaunch: (message) async {
      print('onResume: $message');
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => WebViewExample()));
    });
  }

  var fcmToken;
  void subscribeToTopic() {
    _firebaseMessaging.getToken().then((token) {
      print(token);
      fcmToken = token;
    
      _firebaseMessaging.subscribeToTopic(token);
      // _firebaseMessaging.subscribeToTopic('all');
      
     
     
    });
  }
// Future<bool> callOnFcmApiSendPushNotifications(List <String> userToken) async {

//   final postUrl = 'https://fcm.googleapis.com/fcm/send';
//   final data = {
//     "registration_ids" : userToken,
//     "collapse_key" : "type_a",
//     "notification" : {
//       "title": 'NewTextTitle',
//       "body" : 'NewTextBody',
//     }
//   };

//   final headers = {
//     'content-type': 'application/json',
//     'Authorization': constant.firebaseTokenAPIFCM // 'key=YOUR_SERVER_KEY'
//   };

//   final response = await http.post(postUrl,
//       body: json.encode(data),
//       encoding: Encoding.getByName('utf-8'),
//       headers: headers);

//   if (response.statusCode == 200) {
//     // on success do sth
//     print('test ok push CFM');
//     return true;
//   } else {
//     print(' CFM error');
//     // on failure do sth
//     return false;
//   }
// }


  void getDeviceToken() async {
    String deviceToken = await _firebaseMessaging.getToken();
    print(deviceToken);
  }

  Future<void> disableCapture() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emtehanat',
          style: TextStyle(color: Colors.black),
        ),
        // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        actions: <Widget>[
          NavigationControls(_controller.future),
          // SampleMenu(_controller.future),
        ],
        backgroundColor: Colors.white,
      ),
      // We're using a Builder here so we have a context that is below the Scaffold
      // to allow calling Scaffold.of(context) so we can show a snackbar.
      //https://www.emtehanat.net/ar/register
      //https://www.emtehanat.net/ar/login/student/ post /
      //https://www.emtehanat.net
      body: SafeArea(
        child: Builder(builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: WebView(
              // initialUrl: 'https://www.emtehanat.net/ar/login',

              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller.complete(webViewController);
                
                //  Map<String, String> headers = {"Authorization": "Bearer " + 'jwt'};
                //https://www.emtehanat.net/ar/login/student/ ?fcm_token==

                var endpointUrl = 'https://emtehanat.net/ar/login';
                Map<String, String> queryParams = {'fcm_token': '${fcmToken}'};

                String queryString = Uri(queryParameters: queryParams).query;

                var requestUrl = endpointUrl + '?' + queryString;

                webViewController.loadUrl(requestUrl);
              },
              // TODO(iskakaushik): Remove this when collection literals makes it to stable.
              // ignore: prefer_collection_literals
              javascriptChannels: <JavascriptChannel>[
                _toasterJavascriptChannel(context),
              ].toSet(),
              navigationDelegate: (NavigationRequest request) {
                if (request.url.startsWith('https://www.youtube.com/')) {
                  print('blocking navigation to $request}');
                  return NavigationDecision.navigate;
                }
               else  if (request.url.startsWith('https://emtehanat.net/ar/exams/searching')) {
                  print("yesthisissearchitemwillgogogoogog");
                   
                  return NavigationDecision.navigate;
                } 
                print('allowing navigation to $request');
                return NavigationDecision.navigate;












                
              },
              onPageStarted: (String url) {
               
                if (url == 'https://emtehanat.net/ar/exams/searching') {
                  print("yeysysysyysysysyysysyysysysys");

                } else {
                  print("nonononoonononononono");


                }
                // print('Page started loading: $url');
              },
              onPageFinished: (String url) {
                print('Page finished loading: $url');
              },
              gestureNavigationEnabled: true,
            ),
          );
        }),
      ),
      // floatingActionButton: favoriteButton(),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          // ignore: deprecated_member_use
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }
}

enum MenuOptions {
  showUserAgent,
  listCookies,
  clearCookies,
  addToCache,
  listCache,
  clearCache,
  navigationDelegate,
}

class SampleMenu extends StatelessWidget {
  SampleMenu(this.controller);
  final flutterWebviewPlugin = new WebView();

  final Future<WebViewController> controller;
  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        return PopupMenuButton<MenuOptions>(
          onSelected: (MenuOptions value) {
            switch (value) {
              case MenuOptions.showUserAgent:
                _onShowUserAgent(controller.data, context);
                break;
              case MenuOptions.listCookies:
                _onListCookies(controller.data, context);
                break;
              case MenuOptions.clearCookies:
                _onClearCookies(context);
                break;
              case MenuOptions.addToCache:
                _onAddToCache(controller.data, context);
                break;
              case MenuOptions.listCache:
                _onListCache(controller.data, context);
                break;
              case MenuOptions.clearCache:
                _onClearCache(controller.data, context);
                break;
              case MenuOptions.navigationDelegate:
                // _onNavigationDelegateExample(controller.data, context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.showUserAgent,
              child: const Text('Show user agent'),
              enabled: controller.hasData,
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCookies,
              child: Text('List cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCookies,
              child: Text('Clear cookies'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.addToCache,
              child: Text('Add to cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCache,
              child: Text('List cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCache,
              child: Text('Clear cache'),
            ),
            const PopupMenuItem<MenuOptions>(
              value: MenuOptions.navigationDelegate,
              child: Text('Navigation Delegate example'),
            ),
          ],
        );
      },
    );
  }

  void _onShowUserAgent(
      WebViewController controller, BuildContext context) async {
    // Send a message with the user agent string to the Toaster JavaScript channel we registered
    // with the WebView.
    await controller.evaluateJavascript(
        'Toaster.postMessage("User Agent: " + navigator.userAgent);');
  }

  void _onListCookies(
      WebViewController controller, BuildContext context) async {
    final String cookies =
        await controller.evaluateJavascript('document.cookie');
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Cookies:'),
          _getCookieList(cookies),
        ],
      ),
    ));
  }

  void _onAddToCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript(
        'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Added a test entry to cache.'),
    ));
  }

  void _onListCache(WebViewController controller, BuildContext context) async {
    await controller.evaluateJavascript('caches.keys()'
        '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
        '.then((caches) => Toaster.postMessage(caches))');
  }

  void _onClearCache(WebViewController controller, BuildContext context) async {
    await controller.clearCache();
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text("Cache cleared."),
    ));
  }

  void _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = 'There were cookies. Now, they are gone!';
    if (!hadCookies) {
      message = 'There are no cookies.';
    }
    // ignore: deprecated_member_use
    Scaffold.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  // void _onNavigationDelegateExample(
  //     WebViewController controller, BuildContext context) async {
  //   final String contentBase64 =
  //       base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
  //   await controller.loadUrl('data:text/html;base64,$contentBase64');
  // }

  Widget _getCookieList(String cookies) {
    if (cookies == null || cookies == '""') {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets =
        cookieList.map((String cookie) => Text(cookie));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }
}

class NavigationControls extends StatefulWidget {
  const NavigationControls(this._webViewControllerFuture)
      : assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  _NavigationControlsState createState() => _NavigationControlsState();
}

class _NavigationControlsState extends State<NavigationControls> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: widget._webViewControllerFuture,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
        final bool webViewReady =
            snapshot.connectionState == ConnectionState.done;
        final WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            // IconButton(
            //   icon: const Icon(Icons.arrow_back , color: Colors.black,),
            //   onPressed: !webViewReady
            //       ? null
            //       : () async {
            //           if (await controller.canGoBack()) {
            //             await controller.goBack();
            //           } else {
            //             // ignore: deprecated_member_use
            //             Scaffold.of(context).showSnackBar(
            //               const SnackBar(content: Text("No back history item")),
            //             );
            //             return;
            //           }
            //         },
            // ),
            // IconButton(
            //   icon: const Icon(Icons.arrow_forward , color: Colors.black,),
            //   onPressed: !webViewReady
            //       ? null
            //       : () async {
            //           if (await controller.canGoForward()) {
            //             await controller.goForward();
            //           } else {
            //             // ignore: deprecated_member_use
            //             Scaffold.of(context).showSnackBar(
            //               const SnackBar(
            //                   content: Text("No forward history item")),
            //             );
            //             return;
            //           }
            //         },
            // ),
            IconButton(
              icon: const Icon(
                Icons.replay,
                color: Colors.black,
              ),
              onPressed: !webViewReady
                  ? null
                  : () {
                      controller.reload();
                    },
            ),
          ],
        );
      },
    );
  }
}
