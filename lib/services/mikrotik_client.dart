abstract class MikrotikClient {
  bool get isConnected;
  Future<Map<String, dynamic>> getSystemResources();
  Future<List<Map<String, dynamic>>> getInterfaceStats();
  Future<List<Map<String, dynamic>>> getHotspotUsers();
  Future<List<Map<String, dynamic>>> getHotspotActiveUsers();
  Future<List<Map<String, dynamic>>> getHotspotHosts();
  Future<List<Map<String, dynamic>>> getHotspotProfiles();
  Future<List<Map<String, dynamic>>> getDhcpLeases();
  Future<void> addUser(Map<String, dynamic> user);
  Future<void> addHotspotUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
    String? validity,
    String? dataLimit,
  });
  Future<void> updateUser(String id, Map<String, dynamic> user);
  Future<void> updateHotspotUser({
    required String id,
    required String username,
    required String profile,
    String? comment,
  });
  Future<void> deleteUser(String id);
  Future<void> deleteUserByName(String username);
  Future<void> removeHotspotUser(String id);
  Future<void> toggleUserStatus(String id, bool disabled);
  Future<void> setHotspotUserStatus(String id, bool disabled);
  Future<void> setHotspotUserProfile(String id, String profile);
  Future<void> logoutUser(String id);
  Future<void> logoutUserByName(String username);
  Future<void> logoutHotspotUser(String id);
  Future<void> addProfile(Map<String, dynamic> profile);
  Future<void> updateProfile(String id, Map<String, dynamic> profile);
  Future<void> deleteProfile(String id);
  Future<List<Map<String, dynamic>>> getFiles();
  Future<void> deleteFile(String id);
  Future<void> createBackup(String name);
  Future<void> exportConfig(String name);
  Future<String> downloadFile(String name);
  void close();
}
