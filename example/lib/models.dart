class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool inStock;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.inStock,
    required this.rating,
  });
}

class ApiUser {
  final String id;
  final String name;
  final String email;
  final String company;
  final String position;

  ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
    required this.position,
  });
}
