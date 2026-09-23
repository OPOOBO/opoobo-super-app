import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Stroke icons from the OPB home design (24×24, round caps).
class LineIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  final double strokeWidth;

  const LineIcon({
    super.key,
    required this.name,
    this.size = 24,
    this.color = const Color(0xFFFF4500),
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svgFor(name, color, strokeWidth),
      width: size,
      height: size,
    );
  }
}

/// Service glyph for a module slug (`bus`, `market`, `mall`, `go`, `local`).
class ModuleLineIcon extends StatelessWidget {
  final String? moduleName;
  final double size;
  final Color color;

  const ModuleLineIcon({
    super.key,
    required this.moduleName,
    this.size = 28,
    this.color = const Color(0xFFFF4500),
  });

  @override
  Widget build(BuildContext context) {
    return LineIcon(name: iconNameForModule(moduleName), size: size, color: color);
  }
}

String iconNameForModule(String? moduleName) {
  switch (moduleName) {
    case 'bus':
    case 'directions_bus_rounded':
    case 'directions_bus_outlined':
      return 'bus';
    case 'market':
    case 'shopping_cart_rounded':
    case 'shopping_cart_outlined':
    case 'shopping_basket_rounded':
      return 'market';
    case 'mall':
    case 'storefront_rounded':
    case 'storefront_outlined':
      return 'mall';
    case 'local':
    case 'location_on_rounded':
      return 'local';
    case 'go':
    case 'rides':
    case 'directions_car_rounded':
    case 'directions_car_outlined':
      return 'rides';
    default:
      return 'services';
  }
}

String _hex(Color color) {
  final r = (color.r * 255).round().clamp(0, 255);
  final g = (color.g * 255).round().clamp(0, 255);
  final b = (color.b * 255).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

String _svgFor(String name, Color color, double strokeWidth) {
  final stroke = _hex(color);
  final body = _bodies[name] ?? _bodies['services']!;
  return '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="$stroke" stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">$body</svg>''';
}

const Map<String, String> _bodies = {
  'home':
      '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9,22 9,12 15,12 15,22"/>',
  'scan':
      '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h2v2h-2zM18 14h3M14 18v3M18 18h3v3h-3z"/>',
  'services':
      '<rect x="3" y="3" width="8" height="8" rx="1.5"/><rect x="13" y="3" width="8" height="8" rx="1.5"/><rect x="3" y="13" width="8" height="8" rx="1.5"/><rect x="13" y="13" width="8" height="8" rx="1.5"/>',
  'profile':
      '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
  'search':
      '<circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>',
  'chevron': '<polyline points="9 18 15 12 9 6"/>',
  'medal':
      '<circle cx="12" cy="8" r="6"/><path d="M15.477 12.89 17 22l-5-3-5 3 1.523-9.11"/>',
  'bus':
      '<rect x="3" y="5" width="18" height="12" rx="2"/><path d="M5 5V4a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v1"/><path d="M3 11h18"/><circle cx="7.5" cy="14.5" r="1.2"/><circle cx="16.5" cy="14.5" r="1.2"/><path d="M8 17h8"/><path d="M6 17v2M18 17v2"/>',
  'market':
      '<path d="M6 2 4 6H2"/><path d="M4 6h16l-2 9H6L4 6z"/><path d="M9 6v9M15 6v9"/><circle cx="9" cy="20" r="1"/><circle cx="15" cy="20" r="1"/>',
  'mall':
      '<rect x="2" y="9" width="20" height="12" rx="1"/><path d="M1 9l3-5h16l3 5"/><rect x="10" y="14" width="4" height="7" rx="0.5"/><rect x="4" y="13" width="4" height="3" rx="0.5"/><rect x="16" y="13" width="4" height="3" rx="0.5"/>',
  'local':
      '<path d="M12 21C12 21 5 13.5 5 8.5a7 7 0 0 1 14 0C19 13.5 12 21 12 21z"/><circle cx="12" cy="8.5" r="2.5"/>',
  'rides':
      '<path d="M2 14h1l2-5h10l2 5h1a2 2 0 0 1 0 4H4a2 2 0 0 1-2-4z"/><path d="M7 9l1.5-3h7L17 9"/><circle cx="6.5" cy="17" r="1.5"/><circle cx="17.5" cy="17" r="1.5"/><path d="M8.5 9h7"/>',
};
