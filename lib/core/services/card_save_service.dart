@@
-   final db = _getDatabase();
+    final database = _getDatabase();
@@
-    await db.into(db.cards).insert(
-      db.CardsCompanion.insert(
-        username: card.username,
-        password: Value(card.password),
-        profileId: profileId ?? 0,
-        sharedUsers: Value(card.sharedUsers),
-        createdAt: DateTime.now(),
-      ),
-    );
+    await database.into(database.cards).insert(
+      db.CardsCompanion.insert(
+        username: card.username,
+        password: Value(card.password),
+        profileId: profileId ?? 0,
+        sharedUsers: Value(card.sharedUsers),
+        createdAt: DateTime.now(),
+      ),
+    );
