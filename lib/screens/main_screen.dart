import 'package:flutter/material.dart';
import 'package:taskwin/features/feed/screens/feed_screen.dart';
import 'package:taskwin/features/tasks/screens/tasks_screen.dart';
import 'package:taskwin/features/create/screens/create_task_screen.dart';
import 'package:taskwin/features/wallet/screens/wallet_screen.dart';
import 'package:taskwin/features/profile/screens/profile_screen.dart';
import 'package:taskwin/services/firebase_service.dart';
import 'package:taskwin/features/victory/victory_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const FeedScreen(),
    const TasksScreen(),
    const CreateTaskScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPendingWin();
    });
  }

  Future<void> _checkForPendingWin() async {
    final uid = FirebaseService.currentUser?.uid;
    if (uid == null) return;
    try {
      final userDoc = await FirebaseService.usersCollection.doc(uid).get();
      // Explicitly cast to Map<String, dynamic>? to help the analyzer
      final data = userDoc.data() as Map<String, dynamic>?;
      if (data != null) {
        final lastWinObject = data['lastWin'];
        if (lastWinObject is Map<String, dynamic> &&
            lastWinObject['viewed'] == false &&
            mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => VictoryDialog(win: lastWinObject),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for win: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          elevation: 0,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
