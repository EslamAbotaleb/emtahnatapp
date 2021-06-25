
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DynamicLinkService {

  Future handleDynamicLinks() async {
    // Get the initial dynamic link if the app is opened with a dynamic link
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();

    // handle link that has been retrieved
    _handleDeepLink(data);

    // Register a link callback to fire if the app is opened up from the background
    // using a dynamic link.
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      // handle link that has been retrieved
      _handleDeepLink(dynamicLink);
    }, onError: (OnLinkErrorException e) async {
      print('Link Failed: ${e.message}');
    });
  }

  void _handleDeepLink(PendingDynamicLinkData data) {
    final Uri deepLink = data.link;
    if (deepLink != null) {
      print('_handleDeepLink | deeplink: $deepLink');

      // var isPost = deepLink.pathSegments.contains('post');
      // if (isPost) {
        var title = deepLink.queryParameters['iho8'];
        if (title != null) {
          // Navigator.push(context, deepLink.path);
        }
      }
    }
  }

  Future<String> createFirstPostLink(String title) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://emtahnatapp.page.link',
      link: Uri.parse('https://emtahnatapp.page.link/iho8'),
      androidParameters: AndroidParameters(
        packageName: 'com.emtahnatapp.eg',
      ),



      
      // Other things to add as an example. We don't need it now
    
      
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Example of a Dynamic Link',
        description: 'This link works whether app is installed or not!',
      ),
    );

    final Uri dynamicUrl = await parameters.buildUrl();

    return dynamicUrl.toString();
  }
