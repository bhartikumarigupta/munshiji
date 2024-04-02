import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_whatsapp/open_whatsapp.dart';

class MyWebView extends StatefulWidget {
  @override
  _MyWebViewState createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  bool? _isLoadingPage;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isLoadingPage = true;
  }

  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  String convertWhatsAppLink(String originalLink) {
    // Parse the original WhatsApp link
    Uri originalUri = Uri.parse(originalLink);

    // Create a new URI using the components of the original URI
    Uri convertedUri = Uri(
      scheme: 'https',
      host: 'api.whatsapp.com',
      path: '/send/',
      queryParameters: originalUri.queryParameters,
    );

    // Return the new URI as a string
    return convertedUri.toString();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        WebViewController webViewController = await _controller.future;
        if (await webViewController.canGoBack()) {
          webViewController.goBack();
          return false; // Prevents the default action for the back button.
        } else {
          // Show dialog to confirm exit if there's no page to go back to.
          bool exitApp = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Confirmation'),
              content: Text('Do you want to exit the App?'),
              actions: <Widget>[
                InkWell(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Text('No'),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Text('Yes'),
                ),
              ],
            ),
          );

          // If the dialog is dismissed by tapping outside of it, it will return null. In this case, we handle it as 'false'.
          return exitApp ?? false;
        }
      },
      child: Stack(
        children: <Widget>[
          WebView(
            initialUrl: 'https://m.billingprobe.com/',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller.complete(webViewController);
            },
            navigationDelegate: (NavigationRequest request) async {
              log('URL: ${request.url}');
              if (request.url.startsWith("whatsapp://send/")) {
                log('WhatsApp URL detected: ${request.url}');
                if (await canLaunchUrl(
                    convertWhatsAppLink(request.url) as Uri)) {
                  log('Launching WhatsApp URL: ${convertWhatsAppLink(request.url)}');
                  await launchUrl(convertWhatsAppLink(request.url) as Uri);
                  FlutterOpenWhatsapp.sendSingleMessage(
                      "918179015345", "Hello");
                  return NavigationDecision.prevent;
                }
              }
              if (request.url.startsWith("tel:")) {
                log('Tel URL detected: ${request.url}');
                if (await canLaunchUrl(Uri.parse(request.url))) {
                  log('Launching Tel URL: ${request.url}');
                  await launchUrl(request.url as Uri);
                  return NavigationDecision.prevent;
                }
              }
              return NavigationDecision.navigate;
            },
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              setState(() {
                _isLoadingPage = false;
              });
              print('Page finished loading: $url');
            },
            gestureNavigationEnabled: true,
          ),

          _isLoadingPage! // If the page is still loading, show a CircularProgressIndicator
              ? Center(child: CircularProgressIndicator())
              : Container(), // Otherwise, show empty container to hide indicator
        ],
      ),
    );
  }
}
