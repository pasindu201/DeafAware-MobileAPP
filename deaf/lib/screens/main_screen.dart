import 'package:flutter/material.dart';
import '../tab_pages/home.dart';
import '../tab_pages/profile.dart';
import '../tab_pages/sound_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int _bottomBarIndex = 0;
  bool _isPageTwoLocked = false;
  final int _activateTime = 2000; // Lock duration in milliseconds

  void _onItemTapped(int index) {
    if (_isPageTwoLocked && index == 1) {
      // Prevent switching to Page2 if it's locked
      return;
    }

    setState(() {
      _bottomBarIndex = index;
      if (index == 1) {
        _isPageTwoLocked = true;
        // Unlock after the specified duration
        Future.delayed(Duration(milliseconds: _activateTime), () {
          setState(() {
            _isPageTwoLocked = false;
          });
        });
      }
    });
  }

  AppBar _buildAppBar() {
    switch (_bottomBarIndex) {
      case 0:
        return AppBar(
        title: const Text(
          "Current Location",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 5,
        centerTitle: true,
        backgroundColor: Colors.blue,
      );
      case 1:
        return AppBar(
        title: const Text(
          "Sound Detection",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 5,
        centerTitle: true,
        backgroundColor: Colors.blue,
      );
      case 2:
        return AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 5,
        centerTitle: true,
        backgroundColor: Colors.blue,
      );
      default:
        return AppBar(
          title: const Text('App'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _bottomBarIndex,
        children: [
          HomeTabPage(key: PageStorageKey('home')),
          RecordingScreen(key: PageStorageKey('sound detection')), 
          UserProfilePage(key: PageStorageKey('profile')),
        ],
      ),
      bottomNavigationBar: AbsorbPointer(
        absorbing: _isPageTwoLocked,
        child: BottomNavigationBar(
          backgroundColor: Colors.grey, 
          selectedItemColor: Colors.blue, 
          unselectedItemColor: Colors.black,
          unselectedFontSize: 13,
          currentIndex: _bottomBarIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic_rounded),
              label: 'Sound Detection', 
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
