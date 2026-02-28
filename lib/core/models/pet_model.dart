class Pet {
  final String id;
  final String ownerId;
  final String name;
  final String type; 
  final String breed;
  final int age;
  final String? medicalConditions;
  final String? allergies;   // 👈 Added to match requirements
  final String? specialNeeds; // 👈 Added to match requirements
  final String? imageUrl;     // 👈 Renamed from photoUrl to fix the error

  Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    this.medicalConditions,
    this.allergies,
    this.specialNeeds,
    this.imageUrl,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] ?? '',
      ownerId: map['owner_id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age'] ?? 0,
      medicalConditions: map['medical_conditions'],
      allergies: map['allergies'],
      specialNeeds: map['special_needs'],
      imageUrl: map['image_url'], // 👈 Ensure this matches your Supabase column name
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'name': name,
      'type': type, 
      'breed': breed,
      'age': age,
      'medical_conditions': medicalConditions,
      'allergies': allergies,
      'special_needs': specialNeeds,
      'image_url': imageUrl, // 👈 This will now be saved correctly in Supabase
    };
  }
}