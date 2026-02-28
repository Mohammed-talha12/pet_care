import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  // Default role is 'pet_parent'
  String _selectedRole = 'pet_parent'; 
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    // 1. Prevent action if already loading or fields are empty
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true); 

    try {
      // 2. Create user in Supabase Auth
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
          'role': _selectedRole,
        },
      );

      final userId = res.user?.id;

      if (userId != null) {
        // 3. Insert into the public profiles table for Dashboard routing
        await Supabase.instance.client.from('profiles').upsert({
          'id': userId,
          'full_name': _nameController.text.trim(),
          'role': _selectedRole, 
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Successful!'), 
              backgroundColor: Colors.green
            ),
          );
          // Return to login screen so they can sign in
          Navigator.pop(context); 
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 4. Reset loading state
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Are you a Pet Parent or a Service Provider?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),
            
            // Segmented toggle for role selection
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Pet Parent")),
                    selected: _selectedRole == 'pet_parent',
                    onSelected: (val) {
                      if (val) setState(() => _selectedRole = 'pet_parent');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Provider")),
                    selected: _selectedRole == 'service_provider',
                    onSelected: (val) {
                      if (val) setState(() => _selectedRole = 'service_provider');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            
            CustomTextField(
              controller: _nameController, 
              label: "Full Name"
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _emailController, 
              label: "Email", 
              keyboardType: TextInputType.emailAddress
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _passwordController, 
              label: "Password", 
              isPassword: true
            ),
            
            const SizedBox(height: 40),
            
            // Logic to show loading spinner or the button
            _isLoading 
              ? const CircularProgressIndicator() 
              : PrimaryButton(
                  text: "Register", 
                  onPressed: _handleRegister
                ),
                
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}