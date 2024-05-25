import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobiledev/screens/productListScreen.dart'; // Import product list screen

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _email;
  String? _password;
  String? _role;

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );

        final user = userCredential.user!;

        // Check if user exists in Firestore
        final doc = await _firestore.collection('users').doc(user.email).get();

        if (doc.exists) {
          _role = doc.data()!['role'];

          // Navigate based on role (using named routes for cleaner code)
          if (_role == 'admin') {
            Navigator.pushNamed(
                context, '/productList'); // Route to product list
          } else if (_role == 'user') {
            // Handle user role
          } else {
            // Handle invalid role
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid role'),
              ),
            );
          }
        } else {
          // Handle user not found
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not found'),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user found for that email.'),
            ),
          );
        } else if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wrong password provided for that email.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message!),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Email field
              TextFormField(
                key: const ValueKey('emailInput'),
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email.';
                  }
                  return null;
                },
                onSaved: (newValue) => _email = newValue,
              ),

              // Password field
              TextFormField(
                key: const ValueKey('passwordInput'),
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password.';
                  }
                  return null;
                },
                onSaved: (newValue) => _password = newValue,
              ),

              // Role selection (optional)
              DropdownButtonFormField<String>(
                value: _role,
                hint: const Text('Select Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                onChanged: (value) => setState(() => _role = value),
              ),

              ElevatedButton(
                onPressed: _loginUser,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
