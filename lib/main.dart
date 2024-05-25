import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/cart_screen.dart';
import 'screens/productListScreen.dart';
import 'screens/auth/loginScreen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profileScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple E-commerce App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder<User?>(
              stream: _auth.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return MainScreen();
                } else {
                  return LoginPage();
                }
              },
            ),
        '/home': (context) => MainScreen(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupScreen(),
        '/productList': (context) => ProductListScreen(),
        '/cart': (context) => CartScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isLoggedIn = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? userRole;
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchUserRole();
  }

  void _checkLoginStatus() async {
    User? user = _auth.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  Future<void> _fetchUserRole() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        userRole = userDoc['role'];
        _initializeScreens();
      });
    }
  }

  void _initializeScreens() {
    if (userRole == 'Admin') {
      _screens = [
        ProductListScreen(),
        ProfileScreen(),
      ];
    } else {
      _screens = [
        ProductListScreen(),
        CartScreen(),
        ProfileScreen(),
      ];
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoggedIn
          ? _screens.isEmpty
              ? Center(child: CircularProgressIndicator())
              : _screens[_currentIndex]
          : [
              ProductListScreen(),
              LoginPage(),
              SignupScreen(),
              CartScreen(),
              ProfileScreen(),
            ][_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        backgroundColor: Colors.blueAccent,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black87,
        items: _isLoggedIn
            ? (userRole == 'Admin'
                ? [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Products',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ]
                : [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Products',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.shopping_cart),
                      label: 'Cart',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ])
            : [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Products',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.login),
                  label: 'Login',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_add),
                  label: 'Signup',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Cart',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
      ),
    );
  }
}
