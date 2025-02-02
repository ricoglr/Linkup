import 'package:flutter/material.dart';
import '../screens/add_event_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;
  bool isDarkMode = false;
  final List<Widget> _pages = [
    HomeScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hem light hem dark mode için uygun bir renk
    final barColor = isDark
        ? Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.2) // Dark mode için koyu ton
        : Theme.of(context)
            .colorScheme
            .primary
            .withOpacity(0.2); // Light mode için koyu ton

    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 4,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        elevation: 10,
        color: barColor,
        height: 65, // Yüksekliği biraz artırdık
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: IconButton(
                icon: const Icon(Icons.home),
                color: _selectedIndex == 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                onPressed: () => _onItemTapped(0),
                iconSize: 32, // İkon boyutunu biraz artırdık
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: IconButton(
                icon: const Icon(Icons.person),
                color: _selectedIndex == 1
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                onPressed: () => _onItemTapped(1),
                iconSize: 32, // İkon boyutunu biraz artırdık
              ),
            ),
          ],
        ),
      ),
    );
  }
}
