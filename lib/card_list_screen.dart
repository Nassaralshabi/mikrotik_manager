@@
-class CardListScreen extends StatefulWidget {
-  final List<String> cardList;
-  final bool isNetworkLinked;
-  final Map<String, dynamic> linkedData;
-
-  const CardListScreen({
-    super.key,
-    required this.cardList,
-    this.isNetworkLinked = false,
-    this.linkedData = const {},
-  });
+class CardListScreen extends StatefulWidget {
+  final List<String> cardList;
+  final bool isNetworkLinked;
+  final Map<String, dynamic> linkedData;
+
+  const CardListScreen({
+    super.key,
+    this.cardList = const [],
+    this.isNetworkLinked = false,
+    this.linkedData = const {},
+  });
@@
-  @override
-  void didChangeDependencies() {
-    super.didChangeDependencies();
-    _mqttService = context.read(mqttServiceProvider);
-    _setupMqttListener();
-  }
+  @override
+  void didChangeDependencies() {
+    super.didChangeDependencies();
+    _mqttService = ProviderScope.containerOf(context, listen: false).read(mqttServiceProvider);
+    _setupMqttListener();
+  }
