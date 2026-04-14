import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'contacts_screen.dart';
import 'trips_screen.dart';
import 'emergency_toolkit_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<Widget> get _screens => [
    const DashboardScreen(),
    const ContactsScreen(),
    const TripsScreen(),
    const EmergencyToolkitScreen(),
    const ProfileScreen(),
  ];

  static const _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.group_rounded, 'label': 'Circle'},
    {'icon': Icons.map_rounded, 'label': 'Trips'},
    {'icon': Icons.build_rounded, 'label': 'Toolkit'},
    {'icon': Icons.person_rounded, 'label': 'Safe Id'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10141A),
      body: _screens[_index],
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final active = _index == i;
              return GestureDetector(
                onTap: () {
                  if (_index != i) {
                    setState(() => _index = i);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFFF5352).withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _navItems[i]['icon'] as IconData,
                        color: active
                            ? const Color(0xFFFF5352)
                            : const Color(0xFF949BA6),
                        size: 24,
                      ),
                      if (active) ...[
                        const SizedBox(height: 4),
                        Text(
                          _navItems[i]['label'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF5352),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}