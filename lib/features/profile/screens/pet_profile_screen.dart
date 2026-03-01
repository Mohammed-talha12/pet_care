import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/storage_service.dart'; // Ensure this path is correct

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageService();

  void _addPetDialog() {
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final ageController = TextEditingController();
    String? uploadedImageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add New Pet"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- PHOTO UPLOAD SECTION ---
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    setDialogState(() => isUploading = true);
                    final url = await _storageService.uploadImage('pet-images');
                    setDialogState(() {
                      uploadedImageUrl = url;
                      isUploading = false;
                    });
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: uploadedImageUrl != null 
                        ? NetworkImage(uploadedImageUrl!) 
                        : null,
                    child: isUploading 
                        ? const CircularProgressIndicator()
                        : (uploadedImageUrl == null ? const Icon(Icons.camera_alt, size: 30) : null),
                  ),
                ),
                const Text("Tap to upload photo", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 15),
                // ----------------------------
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Pet Name")),
                TextField(controller: breedController, decoration: const InputDecoration(labelText: "Breed")),
                TextField(controller: ageController, decoration: const InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                await _supabase.from('pets').insert({
                  'owner_id': _supabase.auth.currentUser!.id,
                  'name': nameController.text,
                  'breed': breedController.text,
                  'age': int.tryParse(ageController.text) ?? 0,
                  'image_url': uploadedImageUrl, // ✨ Saved the photo URL
                });
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Pets")),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPetDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('pets')
            .stream(primaryKey: ['id'])
            .eq('owner_id', _supabase.auth.currentUser!.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final pets = snapshot.data!;
          if (pets.isEmpty) return const Center(child: Text("No pets added yet."));

          return ListView.builder(
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: pet['image_url'] != null 
                        ? NetworkImage(pet['image_url']) 
                        : null,
                    child: pet['image_url'] == null ? const Icon(Icons.pets) : null,
                  ),
                  title: Text(pet['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${pet['breed']} • ${pet['age']} years old"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async => await _supabase.from('pets').delete().eq('id', pet['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}