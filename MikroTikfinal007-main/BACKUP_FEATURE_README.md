# Backup System Feature - Implementation Guide

## Overview
A complete backup management system for MikroTik routers integrated into the MikroTik Manager Flutter application.

## Files Added

### 1. `lib/backup_system_screen.dart`
Main backup management screen with full CRUD functionality.

**Key Components:**
- `BackupSystemScreen` - StatefulWidget for the main UI
- `_BackupSystemScreenState` - State management class

**Main Functions:**
- `_loadBackups()` - Fetches backup files from router
- `_createNewBackup()` - Creates new backup on router
- `_restoreBackup()` - Restores a selected backup (reboots router)
- `_deleteBackup()` - Deletes a backup file
- `_calculateTimeAgo()` - Converts creation time to relative time
- `_buildBackupCard()` - Renders individual backup card UI

### 2. Modified `lib/main.dart`
Added navigation entry to the backup system.

**Changes:**
- Imported `backup_system_screen.dart`
- Added `ServiceItem` for backup in the home screen grid

## MikroTik API Commands Used

```dart
// List all files
'/file/print'

// Create backup
'/system/backup/save'
'=name=backup_name'
'=dont-encrypt=yes'

// Restore backup
'/system/backup/load'
'=name=backup_name.backup'

// Delete file
'/file/remove'
'=numbers=filename'
```

## UI Design

### Color Scheme
- **Primary Purple:** `#8A56AC`
- **Card Background:** `#3E355F`
- **Light Purple (file name):** `#B39DDB`
- **Winbox Type:** `Colors.purple`
- **User Manager Type:** `Colors.green`

### Card Layout
```
┌─────────────────────────────────────┐
│ [Icon]  [File Name (Purple BG)]    │
│         [Size with icon]            │
│         [Time ago]              [⋮] │
└─────────────────────────────────────┘
```

### States Handled
1. **Loading:** Circular progress indicator with text
2. **Empty:** Icon + message + instructions
3. **List:** Scrollable list with refresh capability
4. **Creating:** FAB shows progress indicator

## User Flow

```
Home Screen
    ↓
[Tap "النسخ الاحتياطي"]
    ↓
Backup List Screen
    ├→ [Tap Card] → Bottom Sheet → Options
    │                                 ├→ Info Dialog
    │                                 ├→ Restore (with warning)
    │                                 └→ Delete (with confirmation)
    │
    └→ [Tap FAB] → Name Dialog → Create Backup
```

## Error Handling

All operations wrapped in try-catch blocks with:
- `RouterOSClient?` nullable for safe cleanup
- `if (mounted)` checks before setState
- User-friendly SnackBar messages in Arabic
- Proper client cleanup in `finally` blocks

## Security Considerations

1. **Current Implementation:**
   - Backups are NOT encrypted (`dont-encrypt=yes`)
   - No password protection

2. **Enhancement Options:**
   - Add password dialog for encrypted backups
   - Implement secure storage for backup passwords
   - Add biometric authentication

## Testing Checklist

- [ ] List backups successfully loads
- [ ] Create backup generates file on router
- [ ] Restore backup triggers router reboot
- [ ] Delete backup removes file from router
- [ ] Time calculation works for different time ranges
- [ ] UI renders correctly on different screen sizes
- [ ] Error messages display properly
- [ ] App handles network disconnection gracefully
- [ ] Navigation returns to login after restore
- [ ] FAB disables during backup creation

## Future Enhancements

### Priority 1 - Essential
- [ ] Add password/encryption option
- [ ] Export backups to local storage
- [ ] Upload backups from local storage

### Priority 2 - Useful
- [ ] Schedule automatic backups
- [ ] Cloud backup sync
- [ ] Backup notes/descriptions
- [ ] Search and filter

### Priority 3 - Nice to Have
- [ ] Compare two backups
- [ ] Backup size trends
- [ ] Old backup cleanup suggestions
- [ ] Backup integrity check

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  router_os_client: ^latest  # MikroTik API client
  shared_preferences: ^latest # For credentials
```

## Code Quality

- Follows Flutter/Dart style guide
- Uses const constructors where possible
- Proper null safety implementation
- Consistent Arabic localization
- Material Design 3 principles
- Dark theme support

## Performance Notes

- Backup list sorted by creation time (newest first)
- Only backup and user manager database files filtered
- RefreshIndicator for manual refresh
- No unnecessary rebuilds
- Efficient state management

## Localization

Currently supports Arabic only. For multi-language support:

1. Extract all strings to localization files
2. Use `intl` package
3. Add language selector in settings

## Support

For issues or questions:
- Check MikroTik API documentation
- Review RouterOS version compatibility
- Ensure user has proper permissions

---

**Version:** 1.0.0  
**Last Updated:** November 2025  
**Developer:** Nassar Alshabi
