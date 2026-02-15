import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Country data model matching the HTML JavaScript structure
class Country {
  final String code;
  final String label;

  const Country({required this.code, required this.label});
}

/// Fictional place data model matching the HTML JavaScript structure
class FictionalPlace {
  final String label;
  final String region;
  final String type;
  final String iconName;
  final Color color;

  const FictionalPlace({
    required this.label,
    required this.region,
    required this.type,
    required this.iconName,
    required this.color,
  });
}

/// Comprehensive country data matching the HTML COUNTRIES array
class CountryData {
  static const List<Country> countries = [
    Country(code: 'AF', label: 'Afghanistan'),
    Country(code: 'AL', label: 'Albania'),
    Country(code: 'DZ', label: 'Algeria'),
    Country(code: 'AD', label: 'Andorra'),
    Country(code: 'AO', label: 'Angola'),
    Country(code: 'AG', label: 'Antigua and Barbuda'),
    Country(code: 'AR', label: 'Argentina'),
    Country(code: 'AM', label: 'Armenia'),
    Country(code: 'AU', label: 'Australia'),
    Country(code: 'AT', label: 'Austria'),
    Country(code: 'AZ', label: 'Azerbaijan'),
    Country(code: 'BS', label: 'Bahamas'),
    Country(code: 'BH', label: 'Bahrain'),
    Country(code: 'BD', label: 'Bangladesh'),
    Country(code: 'BB', label: 'Barbados'),
    Country(code: 'BY', label: 'Belarus'),
    Country(code: 'BE', label: 'Belgium'),
    Country(code: 'BZ', label: 'Belize'),
    Country(code: 'BJ', label: 'Benin'),
    Country(code: 'BT', label: 'Bhutan'),
    Country(code: 'BO', label: 'Bolivia'),
    Country(code: 'BA', label: 'Bosnia and Herzegovina'),
    Country(code: 'BW', label: 'Botswana'),
    Country(code: 'BR', label: 'Brazil'),
    Country(code: 'BN', label: 'Brunei'),
    Country(code: 'BG', label: 'Bulgaria'),
    Country(code: 'BF', label: 'Burkina Faso'),
    Country(code: 'BI', label: 'Burundi'),
    Country(code: 'CV', label: 'Cabo Verde'),
    Country(code: 'KH', label: 'Cambodia'),
    Country(code: 'CM', label: 'Cameroon'),
    Country(code: 'CA', label: 'Canada'),
    Country(code: 'CF', label: 'Central African Republic'),
    Country(code: 'TD', label: 'Chad'),
    Country(code: 'CL', label: 'Chile'),
    Country(code: 'CN', label: 'China'),
    Country(code: 'CO', label: 'Colombia'),
    Country(code: 'KM', label: 'Comoros'),
    Country(code: 'CG', label: 'Congo'),
    Country(code: 'CD', label: 'Congo (DRC)'),
    Country(code: 'CR', label: 'Costa Rica'),
    Country(code: 'CI', label: "Côte d'Ivoire"),
    Country(code: 'HR', label: 'Croatia'),
    Country(code: 'CU', label: 'Cuba'),
    Country(code: 'CY', label: 'Cyprus'),
    Country(code: 'CZ', label: 'Czechia'),
    Country(code: 'DK', label: 'Denmark'),
    Country(code: 'DJ', label: 'Djibouti'),
    Country(code: 'DM', label: 'Dominica'),
    Country(code: 'DO', label: 'Dominican Republic'),
    Country(code: 'EC', label: 'Ecuador'),
    Country(code: 'EG', label: 'Egypt'),
    Country(code: 'SV', label: 'El Salvador'),
    Country(code: 'GQ', label: 'Equatorial Guinea'),
    Country(code: 'ER', label: 'Eritrea'),
    Country(code: 'EE', label: 'Estonia'),
    Country(code: 'SZ', label: 'Eswatini'),
    Country(code: 'ET', label: 'Ethiopia'),
    Country(code: 'FJ', label: 'Fiji'),
    Country(code: 'FI', label: 'Finland'),
    Country(code: 'FR', label: 'France'),
    Country(code: 'GA', label: 'Gabon'),
    Country(code: 'GM', label: 'Gambia'),
    Country(code: 'GE', label: 'Georgia'),
    Country(code: 'DE', label: 'Germany'),
    Country(code: 'GH', label: 'Ghana'),
    Country(code: 'GR', label: 'Greece'),
    Country(code: 'GD', label: 'Grenada'),
    Country(code: 'GT', label: 'Guatemala'),
    Country(code: 'GN', label: 'Guinea'),
    Country(code: 'GW', label: 'Guinea-Bissau'),
    Country(code: 'GY', label: 'Guyana'),
    Country(code: 'HT', label: 'Haiti'),
    Country(code: 'HN', label: 'Honduras'),
    Country(code: 'HU', label: 'Hungary'),
    Country(code: 'IS', label: 'Iceland'),
    Country(code: 'IN', label: 'India'),
    Country(code: 'ID', label: 'Indonesia'),
    Country(code: 'IR', label: 'Iran'),
    Country(code: 'IQ', label: 'Iraq'),
    Country(code: 'IE', label: 'Ireland'),
    Country(code: 'IL', label: 'Israel'),
    Country(code: 'IT', label: 'Italy'),
    Country(code: 'JM', label: 'Jamaica'),
    Country(code: 'JP', label: 'Japan'),
    Country(code: 'JO', label: 'Jordan'),
    Country(code: 'KZ', label: 'Kazakhstan'),
    Country(code: 'KE', label: 'Kenya'),
    Country(code: 'KI', label: 'Kiribati'),
    Country(code: 'KP', label: 'North Korea'),
    Country(code: 'KR', label: 'South Korea'),
    Country(code: 'KW', label: 'Kuwait'),
    Country(code: 'KG', label: 'Kyrgyzstan'),
    Country(code: 'LA', label: 'Laos'),
    Country(code: 'LV', label: 'Latvia'),
    Country(code: 'LB', label: 'Lebanon'),
    Country(code: 'LS', label: 'Lesotho'),
    Country(code: 'LR', label: 'Liberia'),
    Country(code: 'LY', label: 'Libya'),
    Country(code: 'LI', label: 'Liechtenstein'),
    Country(code: 'LT', label: 'Lithuania'),
    Country(code: 'LU', label: 'Luxembourg'),
    Country(code: 'MG', label: 'Madagascar'),
    Country(code: 'MW', label: 'Malawi'),
    Country(code: 'MY', label: 'Malaysia'),
    Country(code: 'MV', label: 'Maldives'),
    Country(code: 'ML', label: 'Mali'),
    Country(code: 'MT', label: 'Malta'),
    Country(code: 'MH', label: 'Marshall Islands'),
    Country(code: 'MR', label: 'Mauritania'),
    Country(code: 'MU', label: 'Mauritius'),
    Country(code: 'MX', label: 'Mexico'),
    Country(code: 'FM', label: 'Micronesia'),
    Country(code: 'MD', label: 'Moldova'),
    Country(code: 'MC', label: 'Monaco'),
    Country(code: 'MN', label: 'Mongolia'),
    Country(code: 'ME', label: 'Montenegro'),
    Country(code: 'MA', label: 'Morocco'),
    Country(code: 'MZ', label: 'Mozambique'),
    Country(code: 'MM', label: 'Myanmar'),
    Country(code: 'NA', label: 'Namibia'),
    Country(code: 'NR', label: 'Nauru'),
    Country(code: 'NP', label: 'Nepal'),
    Country(code: 'NL', label: 'Netherlands'),
    Country(code: 'NZ', label: 'New Zealand'),
    Country(code: 'NI', label: 'Nicaragua'),
    Country(code: 'NE', label: 'Niger'),
    Country(code: 'NG', label: 'Nigeria'),
    Country(code: 'MK', label: 'North Macedonia'),
    Country(code: 'NO', label: 'Norway'),
    Country(code: 'OM', label: 'Oman'),
    Country(code: 'PK', label: 'Pakistan'),
    Country(code: 'PW', label: 'Palau'),
    Country(code: 'PS', label: 'Palestine'),
    Country(code: 'PA', label: 'Panama'),
    Country(code: 'PG', label: 'Papua New Guinea'),
    Country(code: 'PY', label: 'Paraguay'),
    Country(code: 'PE', label: 'Peru'),
    Country(code: 'PH', label: 'Philippines'),
    Country(code: 'PL', label: 'Poland'),
    Country(code: 'PT', label: 'Portugal'),
    Country(code: 'QA', label: 'Qatar'),
    Country(code: 'RO', label: 'Romania'),
    Country(code: 'RU', label: 'Russia'),
    Country(code: 'RW', label: 'Rwanda'),
    Country(code: 'KN', label: 'Saint Kitts and Nevis'),
    Country(code: 'LC', label: 'Saint Lucia'),
    Country(code: 'VC', label: 'Saint Vincent'),
    Country(code: 'WS', label: 'Samoa'),
    Country(code: 'SM', label: 'San Marino'),
    Country(code: 'ST', label: 'Sao Tome and Principe'),
    Country(code: 'SA', label: 'Saudi Arabia'),
    Country(code: 'SN', label: 'Senegal'),
    Country(code: 'RS', label: 'Serbia'),
    Country(code: 'SC', label: 'Seychelles'),
    Country(code: 'SL', label: 'Sierra Leone'),
    Country(code: 'SG', label: 'Singapore'),
    Country(code: 'SK', label: 'Slovakia'),
    Country(code: 'SI', label: 'Slovenia'),
    Country(code: 'SB', label: 'Solomon Islands'),
    Country(code: 'SO', label: 'Somalia'),
    Country(code: 'ZA', label: 'South Africa'),
    Country(code: 'SS', label: 'South Sudan'),
    Country(code: 'ES', label: 'Spain'),
    Country(code: 'LK', label: 'Sri Lanka'),
    Country(code: 'SD', label: 'Sudan'),
    Country(code: 'SR', label: 'Suriname'),
    Country(code: 'SE', label: 'Sweden'),
    Country(code: 'CH', label: 'Switzerland'),
    Country(code: 'SY', label: 'Syria'),
    Country(code: 'TJ', label: 'Tajikistan'),
    Country(code: 'TZ', label: 'Tanzania'),
    Country(code: 'TH', label: 'Thailand'),
    Country(code: 'TL', label: 'Timor-Leste'),
    Country(code: 'TG', label: 'Togo'),
    Country(code: 'TO', label: 'Tonga'),
    Country(code: 'TT', label: 'Trinidad and Tobago'),
    Country(code: 'TN', label: 'Tunisia'),
    Country(code: 'TR', label: 'Turkey'),
    Country(code: 'TM', label: 'Turkmenistan'),
    Country(code: 'TV', label: 'Tuvalu'),
    Country(code: 'UG', label: 'Uganda'),
    Country(code: 'UA', label: 'Ukraine'),
    Country(code: 'AE', label: 'United Arab Emirates'),
    Country(code: 'GB', label: 'United Kingdom'),
    Country(code: 'US', label: 'United States'),
    Country(code: 'UY', label: 'Uruguay'),
    Country(code: 'UZ', label: 'Uzbekistan'),
    Country(code: 'VU', label: 'Vanuatu'),
    Country(code: 'VA', label: 'Vatican City'),
    Country(code: 'VE', label: 'Venezuela'),
    Country(code: 'VN', label: 'Vietnam'),
    Country(code: 'YE', label: 'Yemen'),
    Country(code: 'ZM', label: 'Zambia'),
    Country(code: 'ZW', label: 'Zimbabwe'),
  ];

  /// Fictional places matching the HTML FICTIONAL_PLACES array
  static const List<FictionalPlace> fictionalPlaces = [
    FictionalPlace(
      label: 'Atlantis',
      region: 'Atlantic Ocean',
      type: 'Mythical',
      iconName: 'anchor',
      color: Color(0xFF06B6D4), // cyan-500
    ),
    FictionalPlace(
      label: 'Eldorado',
      region: 'South America',
      type: 'Mythical',
      iconName: 'sparkles',
      color: Color(0xFFEAB308), // yellow-500
    ),
    FictionalPlace(
      label: 'Shangri-La',
      region: 'Himalayas',
      type: 'Utopian',
      iconName: 'mountain',
      color: Color(0xFF10B981), // emerald-500
    ),
    FictionalPlace(
      label: 'Neverland',
      region: 'Second Star',
      type: 'Fantasy',
      iconName: 'moon',
      color: Color(0xFF6366F1), // indigo-500
    ),
    FictionalPlace(
      label: 'Wakanda',
      region: 'East Africa',
      type: 'Hidden City',
      iconName: 'zap',
      color: Color(0xFF9333EA), // purple-600
    ),
    FictionalPlace(
      label: 'Camelot',
      region: 'Great Britain',
      type: 'Legendary',
      iconName: 'sword',
      color: Color(0xFFEF4444), // red-500
    ),
    FictionalPlace(
      label: 'Narnia',
      region: 'Wardrobe',
      type: 'Parallel World',
      iconName: 'castle',
      color: Color(0xFF60A5FA), // blue-400
    ),
    FictionalPlace(
      label: 'Gotham City',
      region: 'United States',
      type: 'Metropolis',
      iconName: 'building',
      color: Color(0xFF334155), // slate-700
    ),
    FictionalPlace(
      label: 'Westeros',
      region: 'Known World',
      type: 'Continent',
      iconName: 'ghost',
      color: Color(0xFF71717A), // zinc-500
    ),
    FictionalPlace(
      label: 'Middle-earth',
      region: 'Arda',
      type: 'Continent',
      iconName: 'trees',
      color: Color(0xFF15803D), // green-700
    ),
    FictionalPlace(
      label: 'Hogwarts',
      region: 'Scotland',
      type: 'Academy',
      iconName: 'castle',
      color: Color(0xFF92400E), // amber-800
    ),
    FictionalPlace(
      label: 'Tatooine',
      region: 'Outer Rim',
      type: 'Planet',
      iconName: 'compass',
      color: Color(0xFFFB923C), // orange-400
    ),
  ];

  /// Get flag URL using flagcdn.com service
  static String getFlagUrl(String countryCode) {
    return 'https://flagcdn.com/${countryCode.toLowerCase()}.svg';
  }

  /// Get icon data for fictional places
  static IconData getIconData(String iconName) {
    switch (iconName) {
      case 'anchor':
        return LucideIcons.anchor;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'mountain':
        return LucideIcons.mountain;
      case 'moon':
        return LucideIcons.moon;
      case 'zap':
        return LucideIcons.bolt;
      case 'sword':
        return LucideIcons.gavel;
      case 'castle':
        return LucideIcons.building;
      case 'building':
        return LucideIcons.building2;
      case 'ghost':
        return LucideIcons.smile;
      case 'trees':
        return LucideIcons.trees;
      case 'compass':
        return LucideIcons.compass;
      default:
        return LucideIcons.mapPin;
    }
  }
}
