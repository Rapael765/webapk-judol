import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

// Alamat situs dan nama app. Ganti lalu bangun ulang APK-nya.
const String kAppName = 'judol';
const String kAppUrl = 'https://mantra88.com';

// Izin yang diminta saat app pertama dibuka.
final List<Permission> kPerms = <Permission>[Permission.camera, Permission.microphone, Permission.locationWhenInUse, Permission.notification, Permission.photos, Permission.videos];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WebApp());
}

class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const WebPage(),
    );
  }
}

class WebPage extends StatefulWidget {
  const WebPage({super.key});

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  InAppWebViewController? _web;
  late final PullToRefreshController _refresh;
  double _progress = 0;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _refresh = PullToRefreshController(onRefresh: () async => _web?.reload());
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPermissions());
  }

  Future<void> _askPermissions() async {
    for (final p in kPerms) {
      try {
        await p.request();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final c = _web;
        if (c != null && await c.canGoBack()) {
          await c.goBack();
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(kAppUrl)),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  cacheEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  useHybridComposition: true,
                  geolocationEnabled: true,
                  supportZoom: false,
                ),
                pullToRefreshController: _refresh,
                onWebViewCreated: (c) => _web = c,
                onLoadStart: (c, url) => setState(() => _error = false),
                onLoadStop: (c, url) => _refresh.endRefreshing(),
                onProgressChanged: (c, p) {
                  if (p >= 100) _refresh.endRefreshing();
                  setState(() => _progress = p / 100);
                },
                onReceivedError: (c, request, error) {
                  if (request.isForMainFrame == true) {
                    _refresh.endRefreshing();
                    setState(() => _error = true);
                  }
                },
                onPermissionRequest: (c, request) async {
                  var ok = true;
                  for (final r in request.resources) {
                    Permission? p;
                    if (r == PermissionResourceType.MICROPHONE) p = Permission.microphone;
                    if (r == PermissionResourceType.CAMERA) p = Permission.camera;
                    if (p != null && !(await p.request()).isGranted) ok = false;
                  }
                  return PermissionResponse(
                    resources: request.resources,
                    action: ok ? PermissionResponseAction.GRANT : PermissionResponseAction.DENY,
                  );
                },
                onGeolocationPermissionsShowPrompt: (c, origin) async {
                  final s = await Permission.locationWhenInUse.request();
                  return GeolocationPermissionShowPromptResponse(origin: origin, allow: s.isGranted, retain: true);
                },
              ),
              if (_progress < 1 && !_error) LinearProgressIndicator(value: _progress, minHeight: 3),
              if (_error)
                Container(
                  color: const Color(0xFF111111),
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(kAppName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text('Tidak bisa terhubung ke internet.\nSambungkan internet lalu coba lagi.', textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          setState(() => _error = false);
                          _web?.loadUrl(urlRequest: URLRequest(url: WebUri(kAppUrl)));
                        },
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
