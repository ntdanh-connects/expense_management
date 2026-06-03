import 'package:flutter/material.dart';

class CategoryUIConstants {
  static const List<String> colorsList = [
    '#FF8F9C',
    '#9BE5FF',
    '#FFC68C',
    '#E99BFF',
    '#FF8CEE',
    '#FFA8A8',
    '#FFA8B9',
    '#9BFFE5',
    '#9BAFFF',
    '#FFB59B',
    '#9BFFB2',
    '#BFA8FF',
    '#FFE68C',
    '#B5FF8C',
    '#4C4DDC',
    '#D2E8DA',
    '#FCDCD4',
    '#FFCE73',
    '#E2DDFD',
    '#A9F0D1',
  ];

  static const List<String> incomeIcons = [
    'salary', 'award', 'business', 'profit', 'debt', 'support',
    'cash', 'piggy_bank', 'bill_dollar', 'mobile_dollar', 'wallet',
    'bank', 'chart_alt', 'chart', 'discount', 'gift', 'handshake',
    'house_money'
  ];

  static const List<String> expenseIcons = [
    'food', 'car', 'shopping_cart', 'shopping_bag', 'gamepad', 
    'health', 'heart', 'receipt', 'house', 
    'users', 'book', 'building', 'rings', 'grid', 'monitor',
    'coffee', 'book_open', 'paw', 'dumbbell',
    'baby_bottle', 'masks', 'beer', 'suitcase', 'tshirt',
    'graduation_cap', 'basket', 'cigarette',
    'teddy_bear', 'bread', 'globe', 'coffee_cup',
    'clapperboard', 'medical_shield', 'lightbulb', 'gas_station',
    'gas_cylinder', 'flower', 'inbox_archive', 'house_settings',
    'desktop', 'shopping_cart_alt', 'scissors',
    'ticket', 'motorcycle', 'house_search', 'car_settings',
    'parking', 'phone_call', 'baby_carriage', 'glove',
    'car_shopping', 'train', 'chair', 'bill', 'headphones',
    'laptop', 'office_chair', 'medical_shield_alt', 'electricity',
    'hand_heart', 'spa', 'airplane', 'water_drop', 'network'
  ];

  static IconData getIconData(String? iconKey) {
    if (iconKey == null) return Icons.category_rounded;
    switch (iconKey.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'gamepad':
        return Icons.sports_esports_rounded;
      case 'beauty':
        return Icons.spa_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'receipt':
        return Icons.receipt_long_rounded;
      case 'house':
        return Icons.home_rounded;
      case 'users':
        return Icons.people_rounded;
      case 'chart':
        return Icons.insert_chart_rounded;
      case 'book':
        return Icons.book_rounded;
      case 'salary':
        return Icons.monetization_on_rounded;
      case 'award':
        return Icons.emoji_events_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'profit':
        return Icons.trending_up_rounded;
      case 'debt':
        return Icons.history_rounded;
      case 'support':
        return Icons.volunteer_activism_rounded;
      case 'building':
        return Icons.business_rounded;
      case 'rings':
        return Icons.people_alt_rounded;
      case 'grid':
        return Icons.grid_view_rounded;
      case 'monitor':
        return Icons.tv_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'baby_clothing':
        return Icons.child_friendly_rounded;
      case 'book_open':
        return Icons.menu_book_rounded;
      case 'paw':
        return Icons.pets_rounded;
      case 'dumbbell':
        return Icons.fitness_center_rounded;
      case 'baby_bottle':
        return Icons.baby_changing_station_rounded;
      case 'masks':
        return Icons.masks_rounded;
      case 'beer':
        return Icons.sports_bar_rounded;
      case 'suitcase':
        return Icons.work_rounded;
      case 'tshirt':
        return Icons.checkroom_rounded;
      case 'croissant':
        return Icons.bakery_dining_rounded;
      case 'graduation_cap':
        return Icons.school_rounded;
      case 'water_drop_money':
        return Icons.water_drop_rounded;
      case 'basket':
        return Icons.shopping_basket_rounded;
      case 'cigarette':
        return Icons.smoking_rooms_rounded;
      case 'teddy_bear':
        return Icons.toys_rounded;
      case 'bread':
        return Icons.bakery_dining_rounded;
      case 'heart_paw':
        return Icons.pets_rounded;
      case 'globe':
        return Icons.public_rounded;
      case 'hand_money':
        return Icons.handshake_rounded;
      case 'coffee_cup':
        return Icons.local_cafe_rounded;
      case 'money_bag':
        return Icons.savings_rounded;
      case 'graduation_cap_alt':
        return Icons.school_rounded;
      case 'masks_alt':
        return Icons.masks_rounded;
      case 'house_money':
        return Icons.home_work_rounded;
      case 'handshake':
        return Icons.handshake_rounded;
      case 'clapperboard':
        return Icons.movie_rounded;
      case 'medical_shield':
        return Icons.shield_moon_rounded;
      case 'lightbulb':
        return Icons.lightbulb_rounded;
      case 'gas_station':
        return Icons.local_gas_station_rounded;
      case 'gas_cylinder':
        return Icons.propane_tank_rounded;
      case 'flower':
        return Icons.local_florist_rounded;
      case 'inbox_archive':
        return Icons.archive_rounded;
      case 'heart_money':
        return Icons.volunteer_activism_rounded;
      case 'house_settings':
        return Icons.home_repair_service_rounded;
      case 'desktop':
        return Icons.desktop_windows_rounded;
      case 'shopping_cart_alt':
        return Icons.shopping_cart_checkout_rounded;
      case 'hand_coin':
        return Icons.monetization_on_rounded;
      case 'piggy_bank':
        return Icons.savings_rounded;
      case 'scissors':
        return Icons.content_cut_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'ticket':
        return Icons.local_activity_rounded;
      case 'motorcycle':
        return Icons.motorcycle_rounded;
      case 'dumbbell_alt':
        return Icons.fitness_center_rounded;
      case 'house_search':
        return Icons.travel_explore_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'wallet_shield':
        return Icons.account_balance_wallet_rounded;
      case 'car_settings':
        return Icons.car_repair_rounded;
      case 'first_aid':
        return Icons.medical_services_rounded;
      case 'parking':
        return Icons.local_parking_rounded;
      case 'phone_call':
        return Icons.phone_in_talk_rounded;
      case 'baby_carriage':
        return Icons.child_friendly_rounded;
      case 'glove':
        return Icons.sports_mma_rounded;
      case 'car_shopping':
        return Icons.local_taxi_rounded;
      case 'train':
        return Icons.directions_railway_rounded;
      case 'chair':
        return Icons.chair_rounded;
      case 'car_alt':
        return Icons.directions_car_rounded;
      case 'bill':
        return Icons.receipt_rounded;
      case 'teddy_bear_alt':
        return Icons.toys_rounded;
      case 'headphones':
        return Icons.headphones_rounded;
      case 'laptop':
        return Icons.laptop_rounded;
      case 'office_chair':
        return Icons.chair_alt_rounded;
      case 'medical_shield_alt':
        return Icons.health_and_safety_rounded;
      case 'electricity':
        return Icons.bolt_rounded;
      case 'hand_heart':
        return Icons.favorite_border_rounded;
      case 'heart_plus':
        return Icons.favorite_rounded;
      case 'gift_box':
        return Icons.card_giftcard_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'airplane':
        return Icons.airplanemode_active_rounded;
      case 'chart_alt':
        return Icons.bar_chart_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'discount':
        return Icons.local_offer_rounded;
      case 'bill_dollar':
        return Icons.price_change_rounded;
      case 'mobile_dollar':
        return Icons.phone_android_rounded;
      case 'bank':
        return Icons.account_balance_rounded;
      case 'network':
        return Icons.lan_rounded;
      case 'parking_alt':
        return Icons.local_parking_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color getColorFromHex(String? hexString, {Color fallback = Colors.grey}) {
    if (hexString == null) return fallback;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
