import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../theme/app_theme.dart';
import '../../services/printer_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();
  
  bool _isLoading = false;
  bool _isBluetoothEnabled = false;
  List<BluetoothInfo> _devices = [];
  String? _connectedMac;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isEnabled = await _printerService.checkBluetoothStatus();
      setState(() {
        _isBluetoothEnabled = isEnabled;
        _connectedMac = _printerService.connectedMacAddress;
      });

      if (isEnabled) {
        await _scanDevices();
      } else {
        setState(() {
          _errorMessage = 'Bluetooth is disabled. Please enable it to use thermal printer.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final devices = await _printerService.getBluetoothDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to scan devices: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToDevice(String macAddress) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final success = await _printerService.connect(macAddress);
      setState(() {
        if (success) {
          _connectedMac = macAddress;
        } else {
          _errorMessage = 'Failed to connect to device. Make sure it is turned on and paired.';
        }
        _isLoading = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Printer connected successfully'),
            backgroundColor: context.appPrimary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _isLoading = true;
    });

    await _printerService.disconnect();
    
    setState(() {
      _connectedMac = null;
      _isLoading = false;
    });
  }

  Future<void> _testPrint() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _printerService.printVoucher(
      hotspotName: 'OMMON TEST',
      username: 'test_user',
      password: 'test_password',
      price: 'Rp. 5000',
      validity: '1 Day',
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Test print sent' : 'Failed to print'),
          backgroundColor: success ? context.appPrimary : context.appError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        title: Text(
          'Thermal Printer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isBluetoothEnabled)
            IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: _scanDevices,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusHeader(),
            if (_errorMessage.isNotEmpty) _buildErrorCard(),
            Expanded(
              child: _isLoading && _devices.isEmpty
                  ? Center(child: CircularProgressIndicator(color: context.appPrimary))
                  : _buildDeviceList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: context.appSurface,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _connectedMac != null 
                  ? Colors.green.withValues(alpha: 0.1) 
                  : context.appOnSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.print_rounded,
              color: _connectedMac != null ? Colors.green : context.appOnSurface,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _connectedMac != null ? 'Printer Connected' : 'No Printer Connected',
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _connectedMac != null ? 'Ready to print vouchers' : 'Select a paired device below',
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_connectedMac != null)
            ElevatedButton(
              onPressed: _isLoading ? null : _testPrint,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('TEST'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: context.appError),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: context.appError),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    if (!_isBluetoothEnabled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled_rounded, size: 64, color: context.appOnSurface.withValues(alpha: 0.3)),
            SizedBox(height: 16),
            Text(
              'Bluetooth is disabled',
              style: TextStyle(color: context.appOnSurface, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Please enable Bluetooth in your device settings',
              style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initPrinter,
              style: ElevatedButton.styleFrom(backgroundColor: context.appPrimary, foregroundColor: Colors.white),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_rounded, size: 64, color: context.appOnSurface.withValues(alpha: 0.3)),
            SizedBox(height: 16),
            Text(
              'No Paired Devices',
              style: TextStyle(color: context.appOnSurface, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Please pair your printer in Android Settings first',
              style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isConnected = device.macAdress == _connectedMac;

        return Card(
          color: context.appSurface,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isConnected ? context.appPrimary : context.appOnSurface.withValues(alpha: 0.1),
              width: isConnected ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(
              Icons.print_rounded,
              color: isConnected ? context.appPrimary : context.appOnSurface.withValues(alpha: 0.6),
              size: 32,
            ),
            title: Text(
              device.name.isEmpty ? 'Unknown Device' : device.name,
              style: TextStyle(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              device.macAdress,
              style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
            ),
            trailing: _isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: context.appPrimary))
                : isConnected
                    ? TextButton(
                        onPressed: _disconnect,
                        style: TextButton.styleFrom(foregroundColor: context.appError),
                        child: Text('DISCONNECT'),
                      )
                    : ElevatedButton(
                        onPressed: () => _connectToDevice(device.macAdress),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('CONNECT'),
                      ),
          ),
        );
      },
    );
  }
}
