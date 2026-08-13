class Garage {
  final int id;
  final String name;
  final String? ownerName;
  final String? address;
  final String? phone;
  final String? email;

  Garage({
    required this.id,
    required this.name,
    this.ownerName,
    this.address,
    this.phone,
    this.email,
  });

  factory Garage.fromJson(Map<String, dynamic> json) {
    return Garage(
      id: json['id'] as int,
      name: json['name'] as String,
      ownerName: json['owner_name'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_name': ownerName,
      'address': address,
      'phone': phone,
      'email': email,
    };
  }
}
