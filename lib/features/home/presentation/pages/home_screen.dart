@@
-class HomeScreen extends StatefulWidget {
-  final bool isVersion7OrNewer;
-  final String username;
-
-  const HomeScreen({
-    super.key,
-    required this.isVersion7OrNewer,
-    required this.username,
-  });
+class HomeScreen extends StatefulWidget {
+  final bool isVersion7OrNewer;
+  final String username;
+
+  // Make params optional with safe defaults so router can instantiate without args
+  const HomeScreen({
+    super.key,
+    this.isVersion7OrNewer = false,
+    this.username = '',
+  });
@@
-  @override
-  void didChangeAppLifecycleState(AppLifecycleState state) async {
-    super.didChangeAppLifecycleState(state);
-    if (state == AppLifecycleState.resumed) {
-      if (!mounted) return;
-      _loadLinkStatus(); // Reload status on resume
-      // Use Riverpod container to read provider from BuildContext without listening
-      ProviderScope.containerOf(context, listen: false)
-          .read(mqttServiceProvider)
-          .checkAndReconnect();
-      final isLinked = _isNetworkLinked; // Use the state variable
-      if (isLinked) {
-        Future.delayed(const Duration(seconds: 1), () {
-          if (!mounted) return;
-          ProviderScope.containerOf(context, listen: false)
-              .read(mqttServiceProvider)
-              .publish({'command': 'get_latest_network_details'});
-        });
-      }
-    }
-  }
+  @override
+  void didChangeAppLifecycleState(AppLifecycleState state) async {
+    super.didChangeAppLifecycleState(state);
+    if (state == AppLifecycleState.resumed) {
+      if (!mounted) return;
+      _loadLinkStatus(); // Reload status on resume
+      // Use Riverpod container to read provider from BuildContext without listening
+      ProviderScope.containerOf(context, listen: false)
+          .read(mqttServiceProvider)
+          .checkAndReconnect();
+      final isLinked = _isNetworkLinked; // Use the state variable
+      if (isLinked) {
+        Future.delayed(const Duration(seconds: 1), () {
+          if (!mounted) return;
+          ProviderScope.containerOf(context, listen: false)
+              .read(mqttServiceProvider)
+              .publish({'command': 'get_latest_network_details'});
+        });
+      }
+    }
+  }
