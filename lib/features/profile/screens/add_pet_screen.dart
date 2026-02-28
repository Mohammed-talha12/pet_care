import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_care/core/models/pet_model.dart'; 
import 'package:pet_care/features/auth/widgets/custom_text_field.dart';
import 'package:pet_care/features/auth/widgets/primary_button.dart';
// 🚀 Import the helper we discussed
import 'package:pet_care/core/utils/image_helper.dart'; 

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _medicalController = TextEditingController();
final _allergiesController = TextEditingController();
final _specialNeedsController = TextEditingController();
  String _selectedType = 'Dog';
  bool _isSaving = false;
  File? _imageFile; // 📸 Holds the selected photo

  // Function to trigger the gallery
  Future<void> _pickPetImage() async {
    final pickedFile = await ImageHelper.pickImage();
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
  }

  Future<void> _savePet() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a pet name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      String? imageUrl;
      
      // ☁️ Upload photo to Supabase Storage first
      if (_imageFile != null) {
        imageUrl = await ImageHelper.uploadImage(_imageFile!, 'pet-photos');
      }

      // Updated model to include the imageUrl
       final newPet = Pet(
       id: '', 
       ownerId: userId ?? '',
       name: _nameController.text.trim(),
       type: _selectedType,
       breed: _breedController.text.trim(),
       age: int.tryParse(_ageController.text) ?? 0,
       medicalConditions: _medicalController.text.trim(), // 👈 New
       allergies: _allergiesController.text.trim(),        // 👈 New
       specialNeeds: _specialNeedsController.text.trim(),  // 👈 New
       imageUrl: imageUrl,
     );

      await Supabase.instance.client.from('pets').insert(newPet.toMap());
      
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pet profile created!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Pet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 📸 Photo Selection UI
            GestureDetector(
              onTap: _pickPetImage,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageFile == null 
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey) 
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedType, 
              decoration: const InputDecoration(
                labelText: "Pet Type",
                border: OutlineInputBorder(),
              ),
              items: ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 15),
            CustomTextField(controller: _nameController, label: "Pet Name"),
            const SizedBox(height: 15),
            CustomTextField(controller: _breedController, label: "Breed"),
            const SizedBox(height: 15),
            const SizedBox(height: 15),
            CustomTextField(controller: _medicalController, label: "Medical Conditions (Optional)"),
            const SizedBox(height: 15),
            CustomTextField(controller: _allergiesController, label: "Allergies (Optional)"),
            const SizedBox(height: 15),
            CustomTextField(controller: _specialNeedsController, label: "Special Needs (Optional)"),
            CustomTextField(
              controller: _ageController, 
              label: "Age", 
              keyboardType: TextInputType.number
            ),
            const SizedBox(height: 30),
            _isSaving 
              ? const CircularProgressIndicator() 
              : PrimaryButton(text: "Save Pet Profile", onPressed: _savePet),
          ],
        ),
      ),
    );
  }
}