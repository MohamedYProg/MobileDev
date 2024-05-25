import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'User'; // Default role

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 32),
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Name',
                  icon: Icons.person,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  icon: Icons.email,
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 16),
                _buildRoleDropdown(),
                SizedBox(height: 32),
                _buildSignupButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      obscureText: obscureText,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: Icon(Icons.person_outline, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      items: ['User', 'Admin'].map((String role) {
        return DropdownMenuItem<String>(
          value: role,
          child: Text(role),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedRole = newValue!;
        });
      },
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () async {
        String name = _nameController.text;
        String email = _emailController.text;
        String password = _passwordController.text;
        String role = _selectedRole;

        print('Starting signup process...');
        print('Name: $name, Email: $email, Role: $role');

        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
              email: email, password: password);

          final user = userCredential.user!;
          print('User created: ${user.uid}');

          // Prepare user data including email and uid
          Map<String, dynamic> userData = {
            'name': name,
            'email': email, // Add email to user data
            'role': role,
            'uid': user.uid, // Add uid to user data
          };

          await _firestore.collection('users').doc(user.uid).set(userData);
          print('User data saved to Firestore.');

          // Send email verification
          await user.sendEmailVerification();
          print('Verification email sent.');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Signup successful! A verification email has been sent to $email.'),
                backgroundColor: Colors.green),
          );

          // Navigate to the main screen (you may need to adjust this based on your app's logic)
          Navigator.pushReplacementNamed(context, '/login');
        } on FirebaseAuthException catch (e) {
          print('FirebaseAuthException: ${e.code} - ${e.message}');
          String errorMessage;
          if (e.code == 'weak-password') {
            errorMessage = 'The password provided is too weak.';
          } else if (e.code == 'email-already-in-use') {
            errorMessage =
                'The email address is already in use by another account.';
          } else {
            errorMessage =
                e.message ?? 'An error occurred. Please try again later.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        } catch (e) {
          print('Exception: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('An error occurred. Please try again later.'),
                backgroundColor: Colors.red),
          );
        }
      },
      child: Text(
        'Signup',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
