# ΩMMON - Open Mikrotik Monitor

A professional Flutter app for RouterOS management with modern UI, real-time monitoring, and hotspot management.

## Features

### Dashboard
- **System Resources** - Real-time CPU, RAM, and disk usage with animated charts
- **Traffic Monitor** - Live network interface traffic (TX/RX rates)
- **Combined Resource Chart** - Scrollable history with time labels
- **Quick Actions** - Fast access to vouchers, revenue, and settings

### Hotspot Management
- **Voucher Generation** - Create single or bulk vouchers with QR codes
- **Voucher Templates** - Full Size, Compact, and Minimal print layouts
- **Voucher Bulk Delete** - Select and delete multiple vouchers at once
- **User Profiles** - Manage hotspot profiles with time/data limits
- **Active Users** - Monitor connected users with traffic stats
- **Host Monitoring** - DHCP lease and binding tracking

### Revenue & Reports
- **Revenue Dashboard** - Charts and breakdowns by profile
- **Sales Report Export** - CSV export with date filtering
- **Transaction History** - Filterable list with profile/search filters
- **Date Range Picker** - Filter transactions by date range

### Settings
- **Theme Selection** - Light, Purple, Blue, Green, Pink themes
- **Voucher Templates** - Choose print template (Full/Compact/Minimal)
- **Router Management** - Save and manage multiple router connections

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.6+ |
| State Management | Riverpod 2.6.1 |
| Navigation | go_router 14.6.2 |
| Charts | fl_chart 0.70.1 |
| QR Codes | qr_flutter 4.1.0 |
| Local Storage | Hive 2.2.3 |
| Secure Storage | flutter_secure_storage |
| Typography | Google Fonts (Poppins) |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     UI Layer                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │Dashboard│  │ Vouchers│  │ Revenue │  │ Settings│   │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘   │
│       │            │            │            │         │
│  ┌────┴────────────┴────────────┴────────────┴────┐   │
│  │              Riverpod Providers                │   │
│  └────────────────────┬───────────────────────────┘   │
│                       │                               │
│  ┌────────────────────┬───────────────────────────┐   │
│  │              Services Layer                    │   │
│  │  RouterOSService │ CacheService │ FilterUtils  │   │
│  └────────────────────┬───────────────────────────┘   │
│                       │                               │
│  ┌────────────────────┴───────────────────────────┐   │
│  │              RouterOS API (8728)               │   │
│  └────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Getting Started

### Prerequisites
- Flutter SDK 3.6.0 or higher
- RouterOS device with API access enabled

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/mikhmon-clone-mobile.git

# Navigate to project directory
cd mikhmon-clone-mobile

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### RouterOS Configuration

Ensure your RouterOS device has:
1. API service enabled on port 8728
2. A user account with appropriate permissions
3. Hotspot package installed (for hotspot features)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── theme/
│   └── app_theme.dart        # Theme configuration
├── providers/
│   └── app_providers.dart    # Riverpod providers
├── services/
│   ├── routeros_service.dart # RouterOS API client
│   ├── cache_service.dart    # Local caching
│   ├── theme_service.dart    # Theme persistence
│   ├── template_service.dart # Voucher template persistence
│   └── models.dart           # Data models
├── screens/
│   ├── dashboard/            # Dashboard screens
│   ├── vouchers/             # Voucher management
│   ├── revenue/              # Revenue & reports
│   ├── settings/             # Settings screen
│   └── hotspot_users/        # Hotspot user management
├── utils/
│   ├── voucher_printer.dart  # Voucher HTML generation
│   ├── filter_utils.dart     # Reusable filter utilities
│   └── performance_utils.dart # Performance optimizations
└── widgets/                  # Reusable widgets
```
