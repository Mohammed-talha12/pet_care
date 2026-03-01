class PetService {
  final String id;
  final String providerId;
  final String serviceType; // e.g., 'Walking', 'Grooming' [cite: 27]
  final double price;
  final String? description;

  PetService({
    required this.id,
    required this.providerId,
    required this.serviceType,
    required this.price,
    this.description,
  });

  factory PetService.fromMap(Map<String, dynamic> map) {
    return PetService(
      id: map['id'],
      providerId: map['provider_id'],
      serviceType: map['service_type'],
      price: (map['price'] as num).toDouble(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider_id': providerId,
      'service_type': serviceType,
      'price': price,
      'description': description,
    };
  }
}