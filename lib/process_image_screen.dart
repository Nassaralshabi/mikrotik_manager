@@
-class ProcessImageScreen extends StatefulWidget {
-  final String imagePath;
-  final String prefix;
-  final int length;
-  final int total;
-
-  const ProcessImageScreen({
-    super.key,
-    required this.imagePath,
-    required this.prefix,
-    required this.length,
-    required this.total,
-  });
+class ProcessImageScreen extends StatefulWidget {
+  final String imagePath;
+  final String prefix;
+  final int length;
+  final int total;
+
+  const ProcessImageScreen({
+    super.key,
+    this.imagePath = '',
+    this.prefix = '',
+    this.length = 0,
+    this.total = 0,
+  });
