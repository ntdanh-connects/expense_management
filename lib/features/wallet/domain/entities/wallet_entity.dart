class WalletEntity {
  final String id;
  final String name;
  final double balance;
  final String type;
  final String icon;
  final String color;
  final bool isHidden;

  WalletEntity({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    required this.icon,
    required this.color,
    required this.isHidden,
  });
}