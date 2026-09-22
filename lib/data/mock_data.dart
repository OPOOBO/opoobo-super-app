import 'package:flutter/material.dart';
import '../models/service_module.dart';
import '../models/activity_item.dart';

class MockData {
  MockData._();

  static final List<ServiceModule> services = [
    const ServiceModule(
      id: 'bus',
      name: 'OPOOBO Bus',
      short: 'Bus',
      description: 'Book interstate bus trips',
      icon: Icons.directions_bus_rounded,
      tint: Color(0xFFFF4500),
      badge: 'Popular',
      lastUsed: '2 days ago',
      state: ServiceState.installed,
      href: '/module/bus',
    ),
    const ServiceModule(
      id: 'market',
      name: 'OPOOBO Market',
      short: 'Market',
      description: 'Groceries and products',
      icon: Icons.shopping_basket_rounded,
      tint: Color(0xFF3DAF6E),
      lastUsed: 'Yesterday',
      state: ServiceState.installed,
    ),
    const ServiceModule(
      id: 'food',
      name: 'OPOOBO Food',
      short: 'Food',
      description: 'Order meals nearby',
      icon: Icons.restaurant_rounded,
      tint: Color(0xFFD98A2E),
      badge: '20% off',
      lastUsed: '5 hours ago',
      state: ServiceState.update,
    ),
    const ServiceModule(
      id: 'delivery',
      name: 'OPOOBO Delivery',
      short: 'Delivery',
      description: 'Send packages fast',
      icon: Icons.local_shipping_rounded,
      tint: Color(0xFF4A8FD4),
      lastUsed: 'Last week',
      state: ServiceState.installed,
    ),
    const ServiceModule(
      id: 'travel',
      name: 'OPOOBO Travel',
      short: 'Travel',
      description: 'Flights and hotels',
      icon: Icons.flight_rounded,
      tint: Color(0xFF5B8FCF),
      state: ServiceState.notInstalled,
    ),
    const ServiceModule(
      id: 'wallet',
      name: 'OPOOBO Wallet',
      short: 'Wallet',
      description: 'Payments and transfers',
      icon: Icons.account_balance_wallet_rounded,
      tint: Color(0xFF9947E0),
      badge: 'Linked',
      lastUsed: 'Today',
      state: ServiceState.installed,
    ),
    const ServiceModule(
      id: 'recharge',
      name: 'OPOOBO Recharge',
      short: 'Recharge',
      description: 'Airtime and data top-up',
      icon: Icons.smartphone_rounded,
      tint: Color(0xFF65AB54),
      lastUsed: '3 days ago',
      state: ServiceState.installed,
    ),
    const ServiceModule(
      id: 'utility',
      name: 'OPOOBO Utility',
      short: 'Utility',
      description: 'Pay electricity and bills',
      icon: Icons.lightbulb_rounded,
      tint: Color(0xFFD9A733),
      state: ServiceState.notInstalled,
    ),
    const ServiceModule(
      id: 'ride',
      name: 'OPOOBO Ride',
      short: 'Ride',
      description: 'Request a ride nearby',
      icon: Icons.directions_car_rounded,
      tint: Color(0xFF3366CC),
      lastUsed: 'Yesterday',
      state: ServiceState.installed,
    ),
    const ServiceModule(
      id: 'health',
      name: 'OPOOBO Health',
      short: 'Health',
      description: 'Telemedicine and pharmacy',
      icon: Icons.favorite_rounded,
      tint: Color(0xFFD44333),
      state: ServiceState.notInstalled,
    ),
    const ServiceModule(
      id: 'social',
      name: 'OPOOBO Social',
      short: 'Social',
      description: 'Connect with friends',
      icon: Icons.chat_bubble_rounded,
      tint: Color(0xFF8847CC),
      lastUsed: 'Today',
      state: ServiceState.update,
    ),
    const ServiceModule(
      id: 'cloud',
      name: 'OPOOBO Cloud',
      short: 'Cloud',
      description: 'Files and backup storage',
      icon: Icons.cloud_rounded,
      tint: Color(0xFF55A3D9),
      state: ServiceState.installed,
    ),
    const ServiceModule(
      id: 'learning',
      name: 'OPOOBO Learning',
      short: 'Learning',
      description: 'Courses and tutorials',
      icon: Icons.school_rounded,
      tint: Color(0xFF3DAF6E),
      state: ServiceState.notInstalled,
    ),
    const ServiceModule(
      id: 'business',
      name: 'OPOOBO Business',
      short: 'Business',
      description: 'Merchant and invoicing tools',
      icon: Icons.work_rounded,
      tint: Color(0xFF8C6640),
      state: ServiceState.notInstalled,
    ),
    const ServiceModule(
      id: 'events',
      name: 'OPOOBO Events',
      short: 'Events',
      description: 'Tickets and experiences',
      icon: Icons.confirmation_number_rounded,
      tint: Color(0xFFD44088),
      badge: 'New',
      state: ServiceState.installed,
    ),
  ];

  static final List<ActivityItem> activity = [
    const ActivityItem(
      id: 'a1',
      title: 'Lagos \u2192 Abuja',
      meta: 'OPOOBO Bus \u00b7 Seat 12A',
      amount: '\u20a618,500',
      time: '08:40',
      day: 'Today',
      kind: ActivityKind.trips,
      icon: Icons.directions_bus_rounded,
      tint: Color(0xFFFF4500),
      status: ActivityStatus.ongoing,
    ),
    const ActivityItem(
      id: 'a2',
      title: 'Jollof & Grilled Chicken',
      meta: 'OPOOBO Food \u00b7 Mama\'s Kitchen',
      amount: '\u20a66,200',
      time: '07:15',
      day: 'Today',
      kind: ActivityKind.orders,
      icon: Icons.restaurant_rounded,
      tint: Color(0xFFD98A2E),
      status: ActivityStatus.completed,
    ),
    const ActivityItem(
      id: 'a3',
      title: 'Wallet top-up',
      meta: 'OPOOBO Wallet \u00b7 Card \u2022\u20224421',
      amount: '+\u20a650,000',
      time: '21:02',
      day: 'Yesterday',
      kind: ActivityKind.payments,
      icon: Icons.account_balance_wallet_rounded,
      tint: Color(0xFF9947E0),
      status: ActivityStatus.completed,
    ),
    const ActivityItem(
      id: 'a4',
      title: 'Parcel to Ikeja',
      meta: 'OPOOBO Delivery \u00b7 OPD-88213',
      amount: '\u20a63,400',
      time: '16:48',
      day: 'Yesterday',
      kind: ActivityKind.deliveries,
      icon: Icons.local_shipping_rounded,
      tint: Color(0xFF4A8FD4),
      status: ActivityStatus.pending,
    ),
    const ActivityItem(
      id: 'a5',
      title: 'Weekly groceries',
      meta: 'OPOOBO Market \u00b7 14 items',
      amount: '\u20a627,900',
      time: '11:20',
      day: 'Mon, 3 Aug',
      kind: ActivityKind.purchases,
      icon: Icons.shopping_basket_rounded,
      tint: Color(0xFF3DAF6E),
      status: ActivityStatus.completed,
    ),
    const ActivityItem(
      id: 'a6',
      title: 'Airtime \u2014 MTN',
      meta: 'OPOOBO Recharge \u00b7 0803\u2022\u20224410',
      amount: '\u20a62,000',
      time: '09:05',
      day: 'Mon, 3 Aug',
      kind: ActivityKind.payments,
      icon: Icons.smartphone_rounded,
      tint: Color(0xFF65AB54),
      status: ActivityStatus.completed,
    ),
  ];

  static final List<String> advancedBusFeatures = [
    'Seat management',
    'Travel history',
    'Loyalty program',
    'Route management',
    'Bus tracking',
    'Driver information',
    'Fleet information',
    'Membership management',
  ];

  static Color statusColor(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.completed:
        return const Color(0xFF2D9F6F);
      case ActivityStatus.ongoing:
        return const Color(0xFFFF4500);
      case ActivityStatus.pending:
        return const Color(0xFFE5A733);
    }
  }

  static String statusLabel(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.ongoing:
        return 'Ongoing';
      case ActivityStatus.pending:
        return 'Pending';
    }
  }
}
