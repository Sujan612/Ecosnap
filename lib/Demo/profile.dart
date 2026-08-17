import 'package:flutter/material.dart';
import 'bottomnavbar.dart';

class ProfilePage extends StatelessWidget {
  final Color backgroundColor = const Color(0xFFFDF3E8);
  final Color buttonColor = const Color(0xFFC8F4C9);
  final Color iconColor = Colors.green;

  final List<Map<String, dynamic>> settings = [
    {'icon': Icons.person_outline, 'text': 'Edit Profile'},
    {'icon': Icons.bar_chart, 'text': 'My Statistics'},
    {'icon': Icons.vpn_key, 'text': 'Permissions'},
    {'icon': Icons.description_outlined, 'text': 'Terms of use'},
    {'icon': Icons.gavel_outlined, 'text': 'Legal Terms'},
    {'icon': Icons.volunteer_activism_outlined, 'text': 'Donations'},
    {'icon': Icons.star_border, 'text': 'Rate this app'},
    {'icon': Icons.view_sidebar_outlined, 'text': 'Version'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back, color: Colors.green),
                  SizedBox(width: 12),
                  Icon(Icons.eco, color: Colors.green),
                  SizedBox(width: 12),
                  Text(
                    'John Doe',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Settings List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: settings.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(settings[index]['icon'], color: iconColor),
                      title: Text(
                        settings[index]['text'],
                        style: const TextStyle(color: Colors.green, fontSize: 16),
                      ),
                      onTap: () {
                        // Handle tap logic
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2), // 👈 Profile selected
    );
  }
}
