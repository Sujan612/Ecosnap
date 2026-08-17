import 'package:ecosnap/Demo/profile.dart' show ProfilePage;
import 'package:ecosnap/Demo/recognition.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({super.key, required this.currentIndex});

  void _onTabSelected(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget targetPage;
    switch (index) {
      case 0:
        targetPage = const EcoSnapHomeScreen();
        break;
      case 1:
        targetPage = RecognitionPage();
        break;
      case 2:
        targetPage = ProfilePage();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7EE),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home,
            index: 0,
          ),
          _buildNavItem(
            context,
            icon: Icons.center_focus_strong,
            index: 1,
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context,
      {required IconData icon, required int index}) {
    final bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabSelected(context, index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA7E9AF) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
