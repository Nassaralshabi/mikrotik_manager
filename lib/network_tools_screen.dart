@@
-class NetworkToolsScreen extends StatelessWidget {
-  final RouterOSClient client;
-
-  const NetworkToolsScreen({super.key, required this.client});
+class NetworkToolsScreen extends StatelessWidget {
+  final RouterOSClient? client;
+
+  const NetworkToolsScreen({super.key, this.client});
@@
-                  ElevatedButton.icon(
-                    icon: const Icon(Icons.devices_other, size: 28),
-                    label: const Text('مراقبة الأجهزة'),
-                    onPressed: () {
-                      Navigator.of(context).push(MaterialPageRoute(
-                        builder: (context) => DeviceMonitoringScreen(client: client),
-                      ));
-                    },
-                  ),
+                  ElevatedButton.icon(
+                    icon: const Icon(Icons.devices_other, size: 28),
+                    label: const Text('مراقبة الأجهزة'),
+                    onPressed: () {
+                      Navigator.of(context).push(MaterialPageRoute(
+                        builder: (context) => DeviceMonitoringScreen(client: client),
+                      ));
+                    },
+                  ),
