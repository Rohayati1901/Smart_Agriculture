import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'dashboart_screen.dart';

class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({super.key});

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  List<String> deviceIds = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    try {
      final ref = FirebaseDatabase.instance.ref('devices');
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        setState(() {
          deviceIds = [];
          isLoading = false;
        });
        return;
      }

      final rawData = snapshot.value;
      if (rawData is! Map) {
        setState(() {
          errorMessage =
              'Format data perangkat tidak sesuai. Pastikan node root adalah devices/{deviceId}.';
          isLoading = false;
        });
        return;
      }

      final data = Map<String, dynamic>.from(rawData);
      setState(() {
        deviceIds = data.keys.toList();
        isLoading = false;
      });
    } on FirebaseException catch (e) {
      setState(() {
        errorMessage =
            'Akses Firebase gagal: ${e.message ?? e.code}. Cek rules Realtime Database dan login aplikasi.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal mengambil data perangkat: $e';
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _refreshDevices() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await fetchDevices();
  }

  Future<void> _logoutFromDrawer() async {
    Navigator.of(context).maybePop();
    await logout();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      body = _MessageCard(
        icon: Icons.error_outline,
        title: 'Data belum bisa dibuka',
        subtitle: errorMessage!,
      );
    } else if (deviceIds.isEmpty) {
      body = const _MessageCard(
        icon: Icons.devices_other_outlined,
        title: 'Belum ada perangkat',
        subtitle: 'Tambahkan data perangkat di Firebase agar bisa dipilih.',
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: deviceIds.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final id = deviceIds[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(deviceId: id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.sensors_outlined,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perangkat ${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6C7A68),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            id,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Perangkat'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Buka menu',
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Menu Perangkat',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _DrawerActionTile(
                icon: Icons.refresh,
                title: 'Muat Ulang Perangkat',
                onTap: () {
                  Navigator.of(context).maybePop();
                  _refreshDevices();
                },
              ),
              _DrawerActionTile(
                icon: Icons.logout,
                title: 'Logout',
                onTap: _logoutFromDrawer,
                danger: true,
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA5D6A7), Color(0xFFD7F0DA)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.eco_rounded, color: Color(0xFF2E7D32)),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, ayo cek tanaman',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF204A1D),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Pilih perangkat yang ingin kamu lihat dan kontrol.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF45633F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _DrawerActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB3261E) : const Color(0xFF234F1E);
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Icon(icon, color: const Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5E6E5A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
