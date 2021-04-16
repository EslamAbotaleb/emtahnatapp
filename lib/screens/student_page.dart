// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'dart:async';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart' show kReleaseMode;

// class StudentPage extends StatefulWidget {
//   final String url;
//   const StudentPage({this.url, Key key});
//   @override
//   _StudentPageState createState() => _StudentPageState();
// }

// class _StudentPageState extends State<StudentPage> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     // FirebaseCrashlytics.instance.crash();
//   }

//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//         onTap: () {
//           FocusScopeNode currentFocus = FocusScope.of(context);
//           if (!currentFocus.hasPrimaryFocus) {
//             currentFocus.unfocus();
//           }
//         },
//         child: MaterialApp(
//             debugShowCheckedModeBanner: false, home: WebViewExample(widget.url)));
//   }
// }

// class WebViewExample extends StatefulWidget {
//     final String url;
//   const WebViewExample(this.url,{Key key});
//   @override
//   _WebViewExampleState createState() => _WebViewExampleState();
// }

// class _WebViewExampleState extends State<WebViewExample> {
//   final Completer<WebViewController> _controller =
//       Completer<WebViewController>();
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

// //  _buildFcmMessage() {
// //        _firebaseMessaging.configure(
// //           onMessage: (Map<String, dynamic> message) async {
// //             print("onMessage: $message");

// //         },
// //         onLaunch: (Map<String, dynamic> message) async {
// //             print("onLaunch: $message");
// //             // TODO optional
// //         },
// //         onResume: (Map<String, dynamic> message) async {
// //             print("onResume: $message");
// //             // TODO optional
// //         },
// //       );
// //  }
//   /// Get the token, save it to the database for current user
//   _saveDeviceToken() async {
//     // Get the current user
//     String uid = 'eslam';
//     FirebaseAuth _auth = FirebaseAuth.instance;

//     // User user =  _auth.currentUser;

//     // Get the token for this device
//     String fcmToken = await _firebaseMessaging.getToken();

//     // Save it to Firestore
//     if (fcmToken != null) {
//       var tokens =
//           _db.collection('users').doc(uid).collection('tokens').doc(fcmToken);

//       await tokens.set({
//         'token': fcmToken,
//         // 'createdAt': FieldValue.serverTimestamp(), // optional
//         'platform': Platform.operatingSystem // optional
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     SystemChannels.textInput.invokeMethod('TextInput.hide');

//     // disableCapture();
//     configureCallbacks();
//     subscribeToTopic();
//   }

//   void configureCallbacks() {
//     _firebaseMessaging.configure(onMessage: (message) async {
//       print('onMessage:$message');
//     }, onResume: (message) async {
//       print('onResume : $message');
//     }, onLaunch: (message) async {
//       print('onResume: $message');
//       Navigator.push(
//           context, MaterialPageRoute(builder: (context) => WebViewExample(widget.url)));
//     });
//   }

//   var fcmToken;
//   void subscribeToTopic() {
//     _firebaseMessaging.getToken().then((token) {
//       print(token);
//       fcmToken = token;
//       _saveDeviceToken();

//       // _firebaseMessaging.subscribeToTopic(token);
//     });
//   }

//   void getDeviceToken() async {
//     String deviceToken = await _firebaseMessaging.getToken();
//     print(deviceToken);
//   }

//   Future<void> disableCapture() async {
//     await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
//   }

//   Future<Null> refreshList() async {
//     await Future.delayed(Duration(seconds: 2));
//     WebViewExample(widget.url);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Emtehanat',
//           style: TextStyle(color: Colors.black),
//         ),
//         // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
//         actions: <Widget>[
//           NavigationControls(_controller.future),
//           // SampleMenu(_controller.future),
//         ],
//         backgroundColor: Colors.white,
//       ),
//       // We're using a Builder here so we have a context that is below the Scaffold
//       // to allow calling Scaffold.of(context) so we can show a snackbar.
//       //https://www.emtehanat.net/ar/register
//       //https://www.emtehanat.net/ar/login/student/ post /
//       //https://www.emtehanat.net
//       body: SafeArea(
//         child: Builder(builder: (BuildContext context) {
//           return Padding(
//             padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
//             child: WebView(
//               // initialUrl: 'https://www.emtehanat.net/ar/login',
//               javascriptMode: JavascriptMode.unrestricted,
//               onWebViewCreated: (WebViewController webViewController) async {
//                 _controller.complete(webViewController);

//                 //  Map<String, String> headers = {"Authorization": "Bearer " + 'jwt'};
//                 //https://www.emtehanat.net/ar/login/student/?fcm_token==

//                 // var endpointUrl = 'https://www.emtehanat.net/ar/login';
//                 // Map<String, String> queryParams = {'fcm_token': '${fcmToken}'};

//                 // String queryString = Uri(queryParameters: queryParams).query;

//                 // var requestUrl = endpointUrl + '?' + queryString;
//                 // print("requestUrlrequestUrlrequestUrlrequestUrl${requestUrl}");
//                 webViewController.loadUrl(widget.url);
//               },
//               // ignore: prefer_collection_literals
//               javascriptChannels: <JavascriptChannel>[
//                 _toasterJavascriptChannel(context),
//               ].toSet(),
//               navigationDelegate: (NavigationRequest request) {
//                 if (request.url.startsWith('https://www.youtube.com/')) {
//                   print('blocking navigation to $request}');
//                   return NavigationDecision.navigate;
//                 } else if (request.url
//                     .startsWith('https://emtehanat.net/ar/exams/searching')) {
//                   return NavigationDecision.navigate;
//                 }
//                 print('allowing navigation to $request');
//                 return NavigationDecision.navigate;
//               },
//               onPageStarted: (String url) {
//                 // if (url == 'https://emtehanat.net/ar/exams/searching') {
//                 //   disableCapture();
//                 // } else {
//                 // }
//                 // print('Page started loading: $url');
//               },
//               onPageFinished: (String url) {
//                 print('Page finished loading: $url');
//               },
//               gestureNavigationEnabled: true,
//             ),
//           );
//         }),
//       ),
//       // floatingActionButton: favoriteButton(),
//     );
//   }

//   JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
//     return JavascriptChannel(
//         name: 'Toaster',
//         onMessageReceived: (JavascriptMessage message) {
//           // ignore: deprecated_member_use
//           Scaffold.of(context).showSnackBar(
//             SnackBar(content: Text(message.message)),
//           );
//         });
//   }
// }

// enum MenuOptions {
//   showUserAgent,
//   listCookies,
//   clearCookies,
//   addToCache,
//   listCache,
//   clearCache,
//   navigationDelegate,
// }

// class SampleMenu extends StatelessWidget {
//   SampleMenu(this.controller);
//   final flutterWebviewPlugin = new WebView();

//   final Future<WebViewController> controller;
//   final CookieManager cookieManager = CookieManager();

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<WebViewController>(
//       future: controller,
//       builder:
//           (BuildContext context, AsyncSnapshot<WebViewController> controller) {
//         return PopupMenuButton<MenuOptions>(
//           onSelected: (MenuOptions value) {
//             switch (value) {
//               case MenuOptions.showUserAgent:
//                 _onShowUserAgent(controller.data, context);
//                 break;
//               case MenuOptions.listCookies:
//                 _onListCookies(controller.data, context);
//                 break;
//               case MenuOptions.clearCookies:
//                 _onClearCookies(context);
//                 break;
//               case MenuOptions.addToCache:
//                 _onAddToCache(controller.data, context);
//                 break;
//               case MenuOptions.listCache:
//                 _onListCache(controller.data, context);
//                 break;
//               case MenuOptions.clearCache:
//                 _onClearCache(controller.data, context);
//                 break;
//               case MenuOptions.navigationDelegate:
//                 // _onNavigationDelegateExample(controller.data, context);
//                 break;
//             }
//           },
//           itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
//             PopupMenuItem<MenuOptions>(
//               value: MenuOptions.showUserAgent,
//               child: const Text('Show user agent'),
//               enabled: controller.hasData,
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.listCookies,
//               child: Text('List cookies'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.clearCookies,
//               child: Text('Clear cookies'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.addToCache,
//               child: Text('Add to cache'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.listCache,
//               child: Text('List cache'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.clearCache,
//               child: Text('Clear cache'),
//             ),
//             const PopupMenuItem<MenuOptions>(
//               value: MenuOptions.navigationDelegate,
//               child: Text('Navigation Delegate example'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _onShowUserAgent(
//       WebViewController controller, BuildContext context) async {
//     // Send a message with the user agent string to the Toaster JavaScript channel we registered
//     // with the WebView.
//     await controller.evaluateJavascript(
//         'Toaster.postMessage("User Agent: " + navigator.userAgent);');
//   }

//   void _onListCookies(
//       WebViewController controller, BuildContext context) async {
//     final String cookies =
//         await controller.evaluateJavascript('document.cookie');
//     // ignore: deprecated_member_use
//     Scaffold.of(context).showSnackBar(SnackBar(
//       content: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         mainAxisSize: MainAxisSize.min,
//         children: <Widget>[
//           const Text('Cookies:'),
//           _getCookieList(cookies),
//         ],
//       ),
//     ));
//   }

//   void _onAddToCache(WebViewController controller, BuildContext context) async {
//     await controller.evaluateJavascript(
//         'caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
//     // ignore: deprecated_member_use
//     Scaffold.of(context).showSnackBar(const SnackBar(
//       content: Text('Added a test entry to cache.'),
//     ));
//   }

//   void _onListCache(WebViewController controller, BuildContext context) async {
//     await controller.evaluateJavascript('caches.keys()'
//         '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
//         '.then((caches) => Toaster.postMessage(caches))');
//   }

//   void _onClearCache(WebViewController controller, BuildContext context) async {
//     await controller.clearCache();
//     // ignore: deprecated_member_use
//     Scaffold.of(context).showSnackBar(const SnackBar(
//       content: Text("Cache cleared."),
//     ));
//   }

//   void _onClearCookies(BuildContext context) async {
//     final bool hadCookies = await cookieManager.clearCookies();
//     String message = 'There were cookies. Now, they are gone!';
//     if (!hadCookies) {
//       message = 'There are no cookies.';
//     }
//     // ignore: deprecated_member_use
//     Scaffold.of(context).showSnackBar(SnackBar(
//       content: Text(message),
//     ));
//   }

//   // void _onNavigationDelegateExample(
//   //     WebViewController controller, BuildContext context) async {
//   //   final String contentBase64 =
//   //       base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
//   //   await controller.loadUrl('data:text/html;base64,$contentBase64');
//   // }

//   Widget _getCookieList(String cookies) {
//     if (cookies == null || cookies == '""') {
//       return Container();
//     }
//     final List<String> cookieList = cookies.split(';');
//     final Iterable<Text> cookieWidgets =
//         cookieList.map((String cookie) => Text(cookie));
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       mainAxisSize: MainAxisSize.min,
//       children: cookieWidgets.toList(),
//     );
//   }
// }

// class NavigationControls extends StatefulWidget {
//   const NavigationControls(this._webViewControllerFuture)
//       : assert(_webViewControllerFuture != null);

//   final Future<WebViewController> _webViewControllerFuture;

//   @override
//   _NavigationControlsState createState() => _NavigationControlsState();
// }

// class _NavigationControlsState extends State<NavigationControls> {
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<WebViewController>(
//       future: widget._webViewControllerFuture,
//       builder:
//           (BuildContext context, AsyncSnapshot<WebViewController> snapshot) {
//         final bool webViewReady =
//             snapshot.connectionState == ConnectionState.done;
//         final WebViewController controller = snapshot.data;
//         return Row(
//           children: <Widget>[
//             // IconButton(
//             //   icon: const Icon(Icons.arrow_back , color: Colors.black,),
//             //   onPressed: !webViewReady
//             //       ? null
//             //       : () async {
//             //           if (await controller.canGoBack()) {
//             //             await controller.goBack();
//             //           } else {
//             //             // ignore: deprecated_member_use
//             //             Scaffold.of(context).showSnackBar(
//             //               const SnackBar(content: Text("No back history item")),
//             //             );
//             //             return;
//             //           }
//             //         },
//             // ),
//             // IconButton(
//             //   icon: const Icon(Icons.arrow_forward , color: Colors.black,),
//             //   onPressed: !webViewReady
//             //       ? null
//             //       : () async {
//             //           if (await controller.canGoForward()) {
//             //             await controller.goForward();
//             //           } else {
//             //             // ignore: deprecated_member_use
//             //             Scaffold.of(context).showSnackBar(
//             //               const SnackBar(
//             //                   content: Text("No forward history item")),
//             //             );
//             //             return;
//             //           }
//             //         },
//             // ),
//             IconButton(
//               icon: const Icon(
//                 Icons.replay,
//                 color: Colors.black,
//               ),
//               onPressed: !webViewReady
//                   ? null
//                   : () {
//                       controller.reload();
//                     },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info/device_info.dart';
import 'package:emtahnatapp/screens/student_page.dart';
import 'package:emtahnatapp/screens/teacher_page.dart';
import 'package:emtahnatapp/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

const myTask = "syncWithTheBackEnd";

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    switch (task) {
      case myTask:
        print("this method was called from native!");
        break;
      case Workmanager.iOSBackgroundTask:
        print("iOS background fetch delegate ran");
        break;
    }

    //Return true when the task executed successfully or not
    return Future.value(true);
  });
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Workmanager.initialize(callbackDispatcher);
  Workmanager.registerOneOffTask(
    "1",
    myTask, //This is the value that will be returned in the callbackDispatcher
    initialDelay: Duration(minutes: 5),
    // constraints: WorkManagerConstraintConfig(
    //   requiresCharging: true,
    //   networkType: NetworkType.connected,
    // ),
  );
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  if (!kReleaseMode)
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
// Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runZoned(() {
    runApp(LoginPage());
  }, onError: (error) {
    // print(error);
    print("It's not so bad but good in this also not so big.");
    print("Problem still exists: $error");
    // FirebaseCrashlytics.instance.recordFlutterError;
  });
  // runApp(new EmtahnatApp());
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  // AppLifecycleState _notification;
  final GlobalKey webViewKey = GlobalKey();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  InAppWebViewController webViewController;
  StreamController<bool> _showLockScreenStream = StreamController();
  StreamSubscription _showLockScreenSubs;
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey();
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  DateTime backButtonTime;
  void _showLockScreenDialog() {
    _navigatorKey.currentState
        .pushReplacement(new MaterialPageRoute(builder: (BuildContext context) {
      return TestPage();
    }));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showLockScreenSubs = _showLockScreenStream.stream.listen((bool show) {
      if (mounted && show) {
        _showLockScreenDialog();
      }
    });

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // disableCapture();
    // configureCallbacks();
    // subscribeToTopic();
    // _getDeviceId();
  }

  // void configureCallbacks() {
  //   _firebaseMessaging.configure(onMessage: (message) async {
  //     print('onMessage:$message');
  //   }, onResume: (message) async {
  //     print('onResume : $message');
  //   }, onLaunch: (message) async {
  //     print('onResume: $message');
  //     Navigator.push(
  //         context, MaterialPageRoute(builder: (context) => LoginPage()));
  //   });
  // }

  // var fcmToken;
  // var deviceId;
  // void subscribeToTopic() {
  //   _firebaseMessaging.getToken().then((token) {
  //     print(token);
  //     fcmToken = token;
  //     _saveDeviceToken();

  //     // _firebaseMessaging.subscribeToTopic(token);
  //   });
  // }

  // void getDeviceToken() async {
  //   String deviceToken = await _firebaseMessaging.getToken();
  //   print(deviceToken);
  //   deviceId = deviceToken;
  // }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _showLockScreenSubs?.cancel();

    //  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  Key key = UniqueKey();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print("resume");

      _showLockScreenStream.add(true);

      // Navigator.popUntil(context, (route) =>route.settings.name == "TestPage");
      //     Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => TestPage()),
      // );
    }
    // switch (state) {
    //   case AppLifecycleState.resumed:
    //     print("app in resumed");

    //     return;
    //   case AppLifecycleState.inactive:
    //     print("app in inactive");

    //     return;
    //   case AppLifecycleState.paused:
    //     print("app in paused");
    //     return;
    //   case AppLifecycleState.detached:
    //     print("app in detached");

    //   // SystemNavigator.pop();

    // }
  }

  // _getDeviceId() async {
  //   deviceId = "";
  //   deviceId = await _getId();
  // }

  _saveDeviceToken() async {
    // Get the current user
    String uid = 'eslam';
    FirebaseAuth _auth = FirebaseAuth.instance;

    // User user =  _auth.currentUser;

    // Get the token for this device
    String fcmToken = await _firebaseMessaging.getToken();

    // Save it to Firestore
    if (fcmToken != null) {
      var tokens =
          _db.collection('users').doc(uid).collection('tokens').doc(fcmToken);

      await tokens.set({
        'token': fcmToken,
        // 'createdAt': FieldValue.serverTimestamp(), // optional
        'platform': Platform.operatingSystem // optional
      });
    }
  }

  Future<String> _getId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      // import 'dart:io'
      var iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }

  @override
  Widget build(BuildContext context) {
    var endpointUrl = 'https://emtehanat.net/ar/exams/searching';
    // Map<String, String> queryParams = {
    //   'fcm_token': '${fcmToken}',
    //   "device_id": '${deviceId}'
    // };

    // String queryString = Uri(queryParameters: queryParams).query;

    // var requestUrl = endpointUrl + '?' + queryString;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                "Emtehanat",
                style: TextStyle(color: Colors.black),
              )),
          body: SafeArea(
              child: Column(children: <Widget>[
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(url: Uri.parse(endpointUrl)),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    androidOnPermissionRequest:
                        (controller, origin, resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      var uri = navigationAction.request.url;
                      if (![
                        "http",
                        "https",
                        "file",
                        "chrome",
                        "data",
                        "javascript",
                        "about"
                      ].contains(uri.scheme)) {
                        if (await canLaunch(url)) {
                          // Launch the App
                          await launch(
                            url,
                          );
                          // and cancel the request
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.CANCEL;
                      } else {
                        // if (uri.toString().startsWith(
                        //     'https://www.emtehanat.net/ar/register/student')) {
                        //   var endpointUrl =
                        //       'https://www.emtehanat.net/ar/register/student';
                        //   Map<String, String> queryParams = {
                        //     'fcm_token': '${fcmToken}',
                        //     "device_id": '${deviceId}'
                        //   };
                        //   String queryString =
                        //       Uri(queryParameters: queryParams).query;

                        //   var requestUrl = endpointUrl + '?' + queryString;

                        // var data =
                        //     "fcm_token=${fcmToken}&device_id=${deviceId}";

                        //   controller.postUrl(
                        //       url: Uri.parse(endpointUrl),
                        //       postData: utf8.encode(data));

                        //   return NavigationActionPolicy.ALLOW;
                        // } else if (uri.toString().startsWith(
                        //     'https://www.emtehanat.net/ar/login/student')) {
                        //   var endpointUrl =
                        //       'https://www.emtehanat.net/ar/login/student';
                        //   Map<String, String> queryParams = {
                        //     'fcm_token': '${fcmToken}',
                        //     "device_id": '${deviceId}'
                        //   };
                        //   String queryString =
                        //       Uri(queryParameters: queryParams).query;

                        //   var requestUrl = endpointUrl + '?' + queryString;

                        //   var data =
                        //       "fcm_token=${fcmToken}&device_id=${deviceId}";

                        //   controller.postUrl(
                        //       url: Uri.parse(endpointUrl),
                        //       postData: utf8.encode(data));

                        //   return NavigationActionPolicy.ALLOW;
                        // } else if (uri.toString().startsWith(
                        //     'https://www.emtehanat.net/ar/login')) {
                        //   var endpointUrl =
                        //       'https://www.emtehanat.net/ar/login';
                        //   Map<String, String> queryParams = {
                        //     'fcm_token': '${fcmToken}',
                        //     "device_id": '${deviceId}'
                        //   };
                        //   String queryString =
                        //       Uri(queryParameters: queryParams).query;

                        //   var requestUrl = endpointUrl + '?' + queryString;

                        //   var data =
                        //       "fcm_token=${fcmToken}&device_id=${deviceId}";

                        //   controller.postUrl(
                        //       url: Uri.parse(endpointUrl),
                        //       postData: utf8.encode(data));

                        //   return NavigationActionPolicy.ALLOW;
                        // } else if (uri.toString().startsWith(
                        //     'https://www.emtehanat.net/ar/register')) {
                        //   var endpointUrl =
                        //       'https://www.emtehanat.net/ar/register';
                        //   Map<String, String> queryParams = {
                        //     'fcm_token': '${fcmToken}',
                        //     "device_id": '${deviceId}'
                        //   };
                        //   String queryString =
                        //       Uri(queryParameters: queryParams).query;

                        //   var requestUrl = endpointUrl + '?' + queryString;

                        //   var data =
                        //       "fcm_token=${fcmToken}&device_id=${deviceId}";

                        //   controller.postUrl(
                        //       url: Uri.parse(endpointUrl),
                        //       postData: utf8.encode(data));

                        return NavigationActionPolicy.ALLOW;
                        // } else {
                        //   return NavigationActionPolicy.ALLOW;
                        // }
                      }
                    },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;

                        urlController.text = this.url;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print(consoleMessage);
                    },
                  ),
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress)
                      : Container(),
                ],
              ),
            ),
            // ButtonBar(
            //   alignment: MainAxisAlignment.center,
            //   children: <Widget>[
            //     ElevatedButton(
            //       child: Icon(Icons.arrow_back),
            //       onPressed: () {
            //         webViewController?.goBack();
            //       },
            //     ),
            //     ElevatedButton(
            //       child: Icon(Icons.arrow_forward),
            //       onPressed: () {
            //         webViewController?.goForward();
            //       },
            //     ),
            //     ElevatedButton(
            //       child: Icon(Icons.refresh),
            //       onPressed: () {
            //         webViewController?.reload();
            //       },
            //     ),
            //   ],
            // ),
          ]))),
    );
  }
}
