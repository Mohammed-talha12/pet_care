import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/widgets/custom_text_field.dart';
import '../../auth/widgets/primary_button.dart';
import 'package:pet_care/features/core/utils/image_helper.dart';
class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _bioController = TextEditingController();
  final _expController = TextEditingController();
  final _rateController = TextEditingController();
  final _skillsController = TextEditingController(); // 👈 New for skills tagging
  
  bool _isLoading = false;
  bool _isVerified = false; 
  List<String> _portfolioUrls = []; 
  List<String> _skills = []; // 👈 Stores specific provider skills

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      final data = await Supabase.instance.client
          .from('service_providers')
          .select()
          .eq('id', userId ?? '')
          .maybeSingle();

      if (data != null) {
        setState(() {
          _bioController.text = data['bio'] ?? '';
          _expController.text = data['experience_years']?.toString() ?? '';
          _rateController.text = data['hourly_rate']?.toString() ?? '';
          _isVerified = data['is_verified'] ?? false;
          _portfolioUrls = List<String>.from(data['portfolio_urls'] ?? []);
          _skills = List<String>.from(data['skills'] ?? []); // 👈 Load skills
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPortfolioImage() async {
    final file = await ImageHelper.pickImage();
    if (file == null) return;

    setState(() => _isLoading = true);
    final url = await ImageHelper.uploadImage(file, 'portfolios');
    
    if (url != null) {
      setState(() => _portfolioUrls.add(url));
      await _saveProfile(silent: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile({bool silent = false}) async {
    if (!silent && (_bioController.text.isEmpty || _expController.text.isEmpty)) return;

    if (!silent) setState(() => _isLoading = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      await Supabase.instance.client.from('service_providers').upsert({
        'id': userId,
        'bio': _bioController.text.trim(),
        'experience_years': int.tryParse(_expController.text.trim()) ?? 0,
        'hourly_rate': double.tryParse(_rateController.text.trim()) ?? 0.0,
        'portfolio_urls': _portfolioUrls,
        'skills': _skills, // 👈 Save skills list
      });

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professional profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!silent) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Professional Profile')),
      body: _isLoading && _portfolioUrls.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  CustomTextField(controller: _bioController, label: "About Me / Bio", maxLines: 3),
                  const SizedBox(height: 15),
                  CustomTextField(controller: _expController, label: "Years of Experience", keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  CustomTextField(controller: _rateController, label: "Hourly Rate (\$)"),
                  const SizedBox(height: 25),
                  _buildSkillsSection(), // 👈 Skills tagging
                  const SizedBox(height: 25),
                  const Text("Portfolio Gallery", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildPortfolioGrid(), // 👈 Refined Gallery
                  const SizedBox(height: 30),
                  PrimaryButton(text: "Save All Changes", onPressed: () => _saveProfile()),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
              if (_isVerified) // 🛡️ Verification Badge logic
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_isVerified ? "Verified Professional" : "Pending Verification",
              style: TextStyle(
                color: _isVerified ? Colors.blue : Colors.orange, 
                fontWeight: FontWeight.bold,
                fontSize: 14
              )),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Skills & Certifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _skills.map((skill) => Chip(
            label: Text(skill),
            onDeleted: () => setState(() => _skills.remove(skill)),
          )).toList(),
        ),
        Row(
          children: [
            Expanded(
              child: CustomTextField(controller: _skillsController, label: "Add Skill (e.g. CPR Certified)"),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              onPressed: () {
                if (_skillsController.text.isNotEmpty) {
                  setState(() {
                    _skills.add(_skillsController.text.trim());
                    _skillsController.clear();
                  });
                }
              },
            )
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: _portfolioUrls.length + 1,
      itemBuilder: (context, index) {
        if (index == _portfolioUrls.length) {
          return GestureDetector(
            onTap: _uploadPortfolioImage,
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_a_photo, color: Colors.grey),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(_portfolioUrls[index], fit: BoxFit.cover),
        );
      },
    );
  }
}