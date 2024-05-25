import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _fetchEmail() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc['email'];
      } else {
        return 'No email found';
      }
    }
    return 'No user logged in';
  }

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            FutureBuilder<String>(
              future: _fetchEmail(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return Card(
                  margin: EdgeInsets.all(16.0),
                  child: ListTile(
                    leading: Icon(Icons.email),
                    title: Text(
                      'Email',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${snapshot.data}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                );
              },
            ),
            Divider(),
            // Add more widgets here in the future
          ],
        ),
      ),
    );
  }
}
