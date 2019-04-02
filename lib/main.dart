import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'WebView'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          NavigationControls(_controller.future),
          SampleMenu(_controller.future)
        ],
      ),
      body: Builder(builder: (BuildContext context){
        return WebView(
          initialUrl: 'https://flutter.dev',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController){
            _controller.complete(webViewController);
          },
          javascriptChannels: <JavascriptChannel>[
            _toasterJavascriptChannel(context),
          ].toSet(),
          navigationDelegate: (NavigationRequest request){
            if(request.url.startsWith('https://ww.youtube.com/')){
              print('blocking navigation to $request');
              return NavigationDecision.prevent;
            }
            print('allowing navigation to $request');
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url){
            print('Page finished loading: $url');
          },
        );
      }),
      floatingActionButton: favoriteButton(),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context){
    return JavascriptChannel(
        name:'Toaster',
        onMessageReceived: (JavascriptMessage message){
          Scaffold.of(context).showSnackBar(
              SnackBar(content: Text(message.message))
          );
        }
    );
  }

  Widget favoriteButton(){
    return FutureBuilder<WebViewController>(
      future: _controller.future,
      builder: (BuildContext context, AsyncSnapshot<WebViewController> controller){
        if(controller.hasData){
          return FloatingActionButton(
            onPressed: () async {
              final String url = await controller.data.currentUrl();
              Scaffold.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Favorited $url'),
                  )
              );
            },
            child: const Icon(Icons.favorite),
          );
        }
        return Container();
      },
    );
  }
}


const String kNavigationExamplePage = '''
<!DOCTYPE html><html>
<head><title>Navigation Delegate Example</title></head>
<body>
<p>
The navigation delegate is set to block navigation to the youtube website.
</p>
<ul>
<ul><a href="https://www.youtube.com/">https://www.youtube.com/</a></ul>
<ul><a href="https://www.google.com/">https://www.google.com/</a></ul>
</ul>
</body>
</html>
''';

enum MenuOptions{
  showUserAgent,
  listCookies,
  clearCookies,
  addToCache,
  listCache,
  clearCache,
  navigationDelegate
}


class SampleMenu extends StatelessWidget{
  SampleMenu(this.controller);

  final Future<WebViewController> controller;
  final CookieManager cookieManager = CookieManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: controller,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller){
        return PopupMenuButton<MenuOptions>(
          onSelected: (MenuOptions value){
            switch(value){
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
                _onNavigationDelegateExample(controller.data, context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuItem<MenuOptions>>[
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.showUserAgent,
              child: const Text('Show user agent'),
              enabled: controller.hasData,
            ),
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCookies,
              child: const Text('List cookies'),
              enabled: controller.hasData,
            ),
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCookies,
              child: const Text('Clear cookies'),
              enabled: controller.hasData,
            ),
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.addToCache,
              child: const Text('Add to cache'),
              enabled: controller.hasData,
            ),
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.listCache,
              child: const Text('List cache'),
              enabled: controller.hasData,
            ),
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.clearCache,
              child: const Text('Clear cache'),
              enabled: controller.hasData,
            ),
            PopupMenuItem<MenuOptions>(
              value: MenuOptions.navigationDelegate,
              child: const Text('Navigation Delegate'),
              enabled: controller.hasData,
            ),
          ],
        );
      },
    );
  }

  void _onShowUserAgent( WebViewController controller,BuildContext context) async{
    controller.evaluateJavascript('Toaster.postMessage("User Agent: " + navigator.userAgent);');
  }

  void _onListCookies(WebViewController controller,BuildContext context) async {
    final String cookies = await controller.evaluateJavascript('document.cookie');
    Scaffold.of(context).showSnackBar(
        SnackBar(
            content: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Cookies'),
                _getCookieList(cookies),
              ],
            )
        )
    );
  }

  Widget _getCookieList(String cookies) {
    if (cookies == null || cookies == '""') {
      return Container();
    }
    final List<String> cookieList = cookies.split(';');
    final Iterable<Text> cookieWidgets = cookieList.map((String cookie) =>
        Text(cookie));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: cookieWidgets.toList(),
    );
  }

  void _onClearCookies(BuildContext context) async {
    final bool hadCookies = await cookieManager.clearCookies();
    String message = "There were cookies. Now, they are gone!";
    if(!hadCookies){
      message = "There are no cookies.";
    }
    Scaffold.of(context).showSnackBar(
        SnackBar(
            content: Text(message)
        )
    );
  }


  void _onAddToCache(WebViewController controller,BuildContext context) async {
    await controller.evaluateJavascript('caches.open("test_caches_entry"); localStorage["test_localStorage"] = "dummy_entry";');
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Added a test entry to cache'),
    ));
  }

  void _onListCache(WebViewController controller,BuildContext context) async {
    await controller.evaluateJavascript('caches.keys()'
        '.then((cacheKeys) => JSON.stringify({"cacheKeys" : cacheKeys, "localStorage" : localStorage}))'
        '.then((caches) => Toaster.postMessage(caches))');
  }

  void _onClearCache(WebViewController controller,BuildContext context) async {
    await controller.clearCache();
    Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text("Cache clears."),
        )
    );
  }

  void _onNavigationDelegateExample(WebViewController controller,BuildContext context) async {
    final String contentBase64 = base64Encode(const Utf8Encoder().convert(kNavigationExamplePage));
    controller.loadUrl('data:text/html;base64,$contentBase64');
  }



}

class NavigationControls extends StatelessWidget{
  const NavigationControls(this._webViewControllerFuture)
      :assert(_webViewControllerFuture != null);

  final Future<WebViewController> _webViewControllerFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
      future: _webViewControllerFuture,
      builder:
          (BuildContext context,AsyncSnapshot<WebViewController> snapshot){
        final bool webViewReady = snapshot.connectionState == ConnectionState.done;
        WebViewController controller = snapshot.data;
        return Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: !webViewReady ? null : () async {
                if(await controller.canGoBack()){
                  controller.goBack();
                }else{
                  Scaffold.of(context).showSnackBar(
                      const SnackBar(content: Text("No back history item"))
                  );
                  return;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: !webViewReady
                  ? null
                  : () async {
                if(await controller.canGoForward()){
                  controller.goForward();
                }else{
                  Scaffold.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("No forward history item")),
                  );
                  return;
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.replay),
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


