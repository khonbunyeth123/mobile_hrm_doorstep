import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        Navigator.pushNamed(context, '/menu-scan');
        break;
      case 2:
        Navigator.pushNamed(context, '/leave-request');
        break;
      case 3:
        Navigator.pushNamed(context, '/history');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // Navigate to notifications screen
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Have a productive day at work',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),

            // Action Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildActionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan QR',
                  // subtitle: 'Menu & Orders',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/menu-scan'),
                ),
                _buildActionCard(
                  icon: Icons.event_note,
                  title: 'Leave Request',
                  // subtitle: 'Apply for leave',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/leave-request'),
                ),
                _buildActionCard(
                  icon: Icons.history,
                  title: 'History',
                  // subtitle: 'View records',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/history'),
                ),
                _buildActionCard(
                  icon: Icons.person,
                  title: 'Profile',
                  // subtitle: 'Manage account',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.check_circle,
                    title: 'Leave Request Approved',
                    subtitle: 'Your leave request for Jan 15-17 was approved',
                    time: '2 hours ago',
                    color: Colors.blue,
                  ),
                  Divider(height: 1),
                  _buildActivityItem(
                    icon: Icons.qr_code,
                    title: 'QR Code Scanned',
                    subtitle: 'Accessed lunch menu successfully',
                    time: '5 hours ago',
                    color: Colors.blue,
                  ),
                  Divider(height: 1),
                  _buildActivityItem(
                    icon: Icons.person,
                    title: 'Profile Updated',
                    subtitle: 'Contact information updated',
                    time: '1 day ago',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      //   type: BottomNavigationBarType.fixed,
      //   selectedItemColor: Colors.blue,
      //   unselectedItemColor: Colors.grey,
      //   items: [
      //     BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.qr_code_scanner),
      //       label: 'Scan',
      //     ),
      //     BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Leave'),
      //     BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
      //     BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      //   ],
      // ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    // required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            // Text(
            //   subtitle,
            //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            //   textAlign: TextAlign.center,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        time,
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
    );
  }
}
