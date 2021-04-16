import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info/device_info.dart';
import 'package:emtahnatapp/screens/student_page.dart';
import 'package:emtahnatapp/workmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

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
    runApp(EmtahnatApp());
  }, onError: (error) {
    // print(error);
    print("It's not so bad but good in this also not so big.");
    print("Problem still exists: $error");
    // FirebaseCrashlytics.instance.recordFlutterError;
  });
  // runApp(new EmtahnatApp());
}

class EmtahnatApp extends StatefulWidget {
  @override
  _EmtahnatAppState createState() => new _EmtahnatAppState();
}

class _EmtahnatAppState extends State<EmtahnatApp> with WidgetsBindingObserver {
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
      return LoginPage();
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
    configureCallbacks();
    subscribeToTopic();
    _getDeviceId();
  }

  void configureCallbacks() {
    _firebaseMessaging.configure(onMessage: (message) async {
      print('onMessage:$message');
    }, onResume: (message) async {
      print('onResume : $message');
    }, onLaunch: (message) async {
      print('onResume: $message');
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => EmtahnatApp()));
    });
  }

  var fcmToken;
  var deviceId;
  void subscribeToTopic() {
    _firebaseMessaging.getToken().then((token) {
      print(token);
      fcmToken = token;
      _saveDeviceToken();

      // _firebaseMessaging.subscribeToTopic(token);
    });
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
    _showLockScreenSubs?.cancel();
    this.fcmToken = null;
    this.deviceId = null;

    //  SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
    });
  }

  Future<bool> _willPop() async {
    DateTime currentTime = DateTime.now();
    bool backButton = backButtonTime == null ||
        currentTime.difference(backButtonTime) > Duration(seconds: 4);
    if (backButton) {
      backButtonTime = currentTime;
      print("must press double tapped to close");
      return false;
    }

    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print("resume");

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
    var endpointUrl = 'https://www.emtehanat.net/ar/login';
    Map<String, String> queryParams = {
      'fcm_token': '${fcmToken}',
      "device_id": '${deviceId}'
    };

    String queryString = Uri(queryParameters: queryParams).query;

    var requestUrl = endpointUrl + '?' + queryString;

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
          body: WillPopScope(
            onWillPop: () async => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                        title: Text('Are you sure you want to quit?'),
                        actions: <Widget>[
                          RaisedButton(
                              child: Text('ok'),
                              onPressed: () => Navigator.of(context).pop(true)),
                          RaisedButton(
                              child: Text('cancel'),
                              onPressed: () =>
                                  Navigator.of(context).pop(false)),
                        ])),
            child: SafeArea(
                child: Column(children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(url: Uri.parse(requestUrl)),
                      initialUserScripts: UnmodifiableListView<UserScript>([]),
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
                        if (uri.toString().startsWith(
                            'https://www.emtehanat.net/ar/register/student')) {
                          controller.loadUrl(
                            urlRequest: URLRequest(
                                url: Uri.parse(
                                    'https://www.emtehanat.net/ar/register/student'),
                                headers: {
                                  'fcm_token': fcmToken,
                                  'device_id': deviceId
                                }),
                          );

                          return NavigationActionPolicy.CANCEL;
                        } else if (uri.toString().startsWith(
                            'https://www.emtehanat.net/ar/login/student')) {
                          controller.loadUrl(
                            urlRequest: URLRequest(
                                url: Uri.parse(
                                    'https://www.emtehanat.net/ar/login/student'),
                                headers: {
                                  'fcm_token': fcmToken,
                                  'device_id': deviceId
                                }),
                          );
                          return NavigationActionPolicy.CANCEL;
                        } else  if (uri.toString().startsWith(
                            'https://www.emtehanat.net/en/register/student')) {
                          controller.loadUrl(
                            urlRequest: URLRequest(
                                url: Uri.parse(
                                    'https://www.emtehanat.net/en/register/student'),
                                headers: {
                                  'fcm_token': fcmToken,
                                  'device_id': deviceId
                                }),
                          );

                          return NavigationActionPolicy.CANCEL;
                        } else if (uri.toString().startsWith(
                            'https://www.emtehanat.net/en/login/student')) {
                          controller.loadUrl(
                            urlRequest: URLRequest(
                                url: Uri.parse(
                                    'https://www.emtehanat.net/en/login/student'),
                                headers: {
                                  'fcm_token': fcmToken,
                                  'device_id': deviceId
                                }),
                          );
                          return NavigationActionPolicy.CANCEL;
                        } else if (uri.toString().startsWith(
                            'https://www.emtehanat.net/ar/register')) {
                          print("fewhifwehfeifheifheifefefe");
                          var url = Uri.parse(
                              'https://www.emtehanat.net/ar/register');
                          var queryParams = ((url.hasQuery) ? '&' : '?') +
                              "fcm_token=" +
                              '${fcmToken}' +
                              "&" +
                              "device_id=" +
                              '${deviceId}';

                          var newUrl = 'https://www.emtehanat.net/ar/register' +
                              queryParams;

                          controller.loadUrl(
                              urlRequest: URLRequest(url: Uri.parse(newUrl)));
                          return NavigationActionPolicy.ALLOW;
                        } else if (uri
                            .toString()
                            .startsWith('https://www.emtehanat.net/ar/login')) {
                          var url =
                              Uri.parse('https://www.emtehanat.net/ar/login');
                          var queryParams = ((url.hasQuery) ? '&' : '?') +
                              "fcm_token=" +
                              '${fcmToken}' +
                              "&" +
                              "device_id=" +
                              '${deviceId}';

                          var newUrl = 'https://www.emtehanat.net/ar/login' +
                              queryParams;

                          controller.loadUrl(
                              urlRequest: URLRequest(url: Uri.parse(newUrl)));
                          return NavigationActionPolicy.ALLOW;
                        }

                        return NavigationActionPolicy.ALLOW;
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
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
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
            ])),
          )),
    );
  }
}
