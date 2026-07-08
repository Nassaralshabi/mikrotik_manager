@@
-class PdfTemplatesScreen extends StatefulWidget {
-  final List<Map<String, dynamic>> profiles;
-
-  const PdfTemplatesScreen({super.key, required this.profiles});
+class PdfTemplatesScreen extends StatefulWidget {
+  final List<Map<String, dynamic>> profiles;
+
+  const PdfTemplatesScreen({super.key, this.profiles = const []});
