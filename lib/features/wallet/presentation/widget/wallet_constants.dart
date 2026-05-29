import 'package:flutter/material.dart';

class WalletUIConstants {
  static const List<Map<String, String>> colorsList = [
    {'name': 'Indigo', 'hex': '#4C4DDC'},
    {'name': 'Sage', 'hex': '#D2E8DA'},
    {'name': 'Peach', 'hex': '#FCDCD4'},
    {'name': 'Yellow', 'hex': '#FFCE73'},
    {'name': 'Lavender', 'hex': '#E2DDFD'},
    {'name': 'Mint', 'hex': '#A9F0D1'},
  ];

  static const List<Map<String, dynamic>> iconsList = [
    {'key': 'cash', 'icon': Icons.payments_rounded},
    {'key': 'bank', 'icon': Icons.account_balance_rounded},
    {'key': 'wallet', 'icon': Icons.account_balance_wallet_rounded},
    {'key': 'card', 'icon': Icons.credit_card_rounded},
    {'key': 'piggy', 'icon': Icons.savings_rounded},
    {'key': 'bag', 'icon': Icons.shopping_bag_rounded},
    {'key': 'car', 'icon': Icons.directions_car_rounded},
    {'key': 'home', 'icon': Icons.home_rounded},
    {'key': 'food', 'icon': Icons.restaurant_rounded},
    {'key': 'plane', 'icon': Icons.flight_rounded},
  ];

  static IconData getIconData(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'cash':
        return Icons.payments_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'piggy':
        return Icons.savings_rounded;
      case 'bag':
        return Icons.shopping_bag_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'plane':
        return Icons.flight_rounded;
      case 'e-wallet':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }
}
