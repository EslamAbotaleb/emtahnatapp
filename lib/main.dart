import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info/device_info.dart';

import 'package:emtahnatapp/screens/student_page.dart';
import 'package:emtahnatapp/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

const myTask = "syncWithTheBackEnd";

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (kDebugMode) {
    FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(false); //disable false
  } else {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }
// enableInDevMode
  if (!kReleaseMode)
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
// Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runZoned(() {
    runApp(EmtehanatPage(url: 'https://emtehanat.net/ar/mobile-home'));

    // runApp(DisplayContentRequest());
  }, onError: (error) {
    // print(error);
    print("It's not so bad but good in this also not so big.");
    print("Problem still exists: $error");
    // FirebaseCrashlytics.instance.recordFlutterError;
  });
}

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

/*
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Workmanager.initialize(callbackDispatcher);
  Workmanager.registerOneOffTask(
    "1",
    myTask, //This is the value that will be returned in the callbackDispatcher
    initialDelay: Duration(minutes: 5),
    constraints: WorkManagerConstraintConfig(
      requiresCharging: true,
      networkType: NetworkType.connected,
    ),
  );
  // if (Platform.isAndroid) {
  //   await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  // }
  if (!kReleaseMode)
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
// Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runZoned(() {
    runApp(StudentPage(
      url: 'https://www.emtehanat.net/ar/login',
    ));
  }, onError: (error) {
    // print(error);
    print("It's not so bad but good in this also not so big.");
    print("Problem still exists: $error");
    // FirebaseCrashlytics.instance.recordFlutterError;
  });
  // runApp(new DisplayContentRequest());
}
*/

class DisplayContentRequest extends StatefulWidget {
  final String url;
  final String fcmToken;
  const DisplayContentRequest({this.url, this.fcmToken, Key key});
  @override
  _DisplayContentRequestState createState() =>
      new _DisplayContentRequestState();
}

class _DisplayContentRequestState extends State<DisplayContentRequest>
    with WidgetsBindingObserver {
  // AppLifecycleState _notification;
  final GlobalKey webViewKey = GlobalKey();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  InAppWebViewController webViewController;
  StreamController<bool> _showLockScreenStream = StreamController();
  // StreamSubscription _showLockScreenSubs;
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
  String _linkMessage;
  bool _isCreatingLink = false;
  double progress = 0;
  final urlController = TextEditingController();
  final cookieManager = WebviewCookieManager();

  DateTime backButtonTime;
  void _showLockScreenDialog() {
    _navigatorKey.currentState
        .pushReplacement(new MaterialPageRoute(builder: (BuildContext context) {
      return DisplayContentRequest();
    }));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // _showLockScreenSubs = _showLockScreenStream.stream.listen((bool show) {
    //   if (mounted && show) {
    //     _showLockScreenDialog();
    //   }
    // });
    // initDynamicLinks();

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

    disableCapture();
    configureCallbacks();
    // subscribeToTopic();
    _getDeviceId();
  }

  Future<void> disableCapture() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void configureCallbacks() {
    _firebaseMessaging.configure(onMessage: (message) async {
      print('onMessage:$message');
    }, onResume: (message) async {
      print('onResume : $message');
    }, onLaunch: (message) async {
      print('onResume: $message');
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => DisplayContentRequest()));
    });
  }

  var fcmToken;
  var deviceId;
  void subscribeToTopic() {
    _firebaseMessaging.getToken().then((token) {
      print(token);
      fcmToken = token;
      _saveTokenInShared(fcmToken.toString());
      _saveDeviceToken();

      // _firebaseMessaging.subscribeToTopic(token);
    });
  }

  _saveTokenInShared(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('fcmToken', token);
  }

  void getDeviceToken() async {
    String deviceToken = await _firebaseMessaging.getToken();
    print(deviceToken);
    deviceId = deviceToken;
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    // _showLockScreenSubs?.cancel();
    this.fcmToken = null;
    this.deviceId = null;

    //  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  // Future<bool> _willPop() async {
  //   DateTime currentTime = DateTime.now();
  //   bool backButton = backButtonTime == null ||
  //       currentTime.difference(backButtonTime) > Duration(seconds: 4);
  //   if (backButton) {
  //     backButtonTime = currentTime;
  //     print("must press double tapped to close");
  //     return false;
  //   }

  //   return true;
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _createDynamicLink(true);

    if (state == AppLifecycleState.resumed) {
      print("resume");
      // _createDynamicLink(false);

      _showLockScreenStream.add(true);
    }
  }

  _getDeviceId() async {
    deviceId = await _getId();
  }

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
    // if (Platform.isIOS) {
    //   // import 'dart:io'
    //   var iosDeviceInfo = await deviceInfo.iosInfo;
    //   return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    // } else {
    var androidDeviceInfo = await deviceInfo.androidInfo;
    return androidDeviceInfo.androidId; // unique ID on Android
    // }
  }

  CookieManager _cookieManager = CookieManager.instance();

  @override
  Widget build(BuildContext context) {
    // var endpointUrl = 'https://www.emtehanat.net/ar/login';
    // Map<String, String> queryParams = {
    //   'fcm_token': '${fcmToken}',
    //   "device_id": '${deviceId}'
    // };

    // String queryString = Uri(queryParameters: queryParams).query;

    // var requestUrl = endpointUrl + '?' + queryString;
    print("fcmTokenfcmToken${widget.fcmToken.toString()}");
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
                    initialUrlRequest: URLRequest(
                      url: Uri.parse(widget.url),
                      // headers: {
                      //   'fcm_token': fcmToken.toString(),
                      //   'device_id': deviceId.toString()
                      // }
                    ),
                    initialUserScripts: UnmodifiableListView<UserScript>([]),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) async {
                      webViewController = controller;

                      await _cookieManager.setCookie(
                        url: Uri.parse(widget.url),
                        name: 'fcm_token',
                        value: widget.fcmToken.toString(),
                      );
                      await _cookieManager.setCookie(
                        url: Uri.parse(widget.url),
                        name: 'device_id',
                        value: deviceId.toString(),
                      );

                      // webViewController.evaluateJavascript(
                      //     source:
                      //         'document.cookie = "fcm_token=${fcmToken.toString()}"');
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
                        (InAppWebViewController controller,
                            shouldOverrideUrlLoadingRequest) async {
                      var uri = shouldOverrideUrlLoadingRequest.request.url;

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
                      }

                      return NavigationActionPolicy.ALLOW;
                    },
                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                      List<Cookie> cookies = await _cookieManager.getCookies(
                          url: Uri.parse(widget.url));
                      cookies.forEach((cookie) {
                        print(cookie.name + " " + cookie.value);
                        // cookie.value = fcmToken.toString();
                      });
                      // List<Cookie> cookies = await _cookieManager.setCookie(url: Uri.parse(widget.url), name: 'name', value: 'value');

                      //           await _cookieManager.setCookies([
                      // Cookie('cookieName', 'cookieValue')
                      //   ..domain = 'youtube.com'
                      //   ..expires = DateTime.now().add(Duration(days: 10))
                      //   ..httpOnly = false
                      // ]);
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
          ]))),
    );
  }

  // void _handleDeepLink(PendingDynamicLinkData data) {
  //   final Uri deepLink = data.link;
  //   if (deepLink != null) {
  //     print('_handleDeepLink | deeplink: $deepLink');

  //     // var isPost = deepLink.pathSegments.contains('post');
  //     // if (isPost) {
  //     var title = deepLink.queryParameters['iho8'];
  //     Navigator.pushNamed(context, deepLink.path);

  //     // if (title != null) {}
  //   }
  // }

  Future<void> initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        // ignore: unawaited_futures
        // Navigator.pushNamed(context, deepLink.path);
      
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmtehanatPage(url: deepLink.path)));
        
      }
      // _createDynamicLink(false);
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      // ignore: unawaited_futures
      // Navigator.pushNamed(context, deepLink.path);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmtehanatPage(url: deepLink.path)));

    }
  }

  Future<void> _createDynamicLink(bool short) async {
    setState(() {
      _isCreatingLink = true;
    });

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://emtahnatapp.page.link',
      link: Uri.parse('https://emtahnatapp.page.link/iho8'),
      androidParameters: AndroidParameters(
        packageName: 'com.emtahnatapp.eg',
        minimumVersion: 0,
      ),

      // iosParameters: IosParameters(
      //   bundleId: 'com.google.FirebaseCppDynamicLinksTestApp.dev',
      //   minimumVersion: '0',
      // ),
    );

    Uri url;
    if (short) {
      final ShortDynamicLink shortLink = await parameters.buildShortLink();
      url = shortLink.shortUrl;
    } else {
      url = await parameters.buildUrl();
    }

    setState(() {
      _linkMessage = url.toString();
      _isCreatingLink = false;
    });
  }
}

Future<void> retrieveDynamicLink(BuildContext context) async {
  try {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              EmtehanatPage(url: 'https://emtehanat.net/ar/mobile-home')));
    }

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              EmtehanatPage(url: 'https://emtehanat.net/ar/mobile-home')));
    });
  } catch (e) {
    print(e.toString());
  }
}
