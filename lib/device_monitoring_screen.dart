@@
-class DeviceMonitoringScreen extends StatefulWidget {
-  final RouterOSClient client;
-
-  const DeviceMonitoringScreen({super.key, required this.client});
+class DeviceMonitoringScreen extends StatefulWidget {
+  final RouterOSClient? client;
+
+  const DeviceMonitoringScreen({super.key, this.client});
