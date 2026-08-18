// lib/screens/location_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPickerScreen extends StatefulWidget {
  final Function(String address, String city) onLocationSelected;

  const LocationPickerScreen({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late MapController _mapController;
  LatLng _selectedLocation = const LatLng(33.6844, 73.0479);
  String _selectedAddress = '';
  String _selectedCity = '';
  String _selectedPlaceName = '';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // 🔥 Search results for dropdown
  List<Map<String, dynamic>> _searchResults = [];
  bool _showDropdown = false;
  bool _isSearching = false;

  // OpenStreetMap Nominatim API (100% FREE)
  final String _nominatimUrl = 'https://nominatim.openstreetmap.org';

  // Popular Pakistani cities with their common areas
  final Map<String, List<String>> _cityAreas = {
    'Islamabad': [
      'F-6', 'F-7', 'F-8', 'F-10', 'F-11', 'G-6', 'G-7', 'G-8', 'G-9', 'G-10',
      'G-11', 'I-8', 'I-9', 'I-10', 'E-7', 'E-8', 'D-12', 'D-13', 'Blue Area',
      'G-13', 'G-14', 'G-15', 'D-12', 'D-13', 'Rawal Lake View', 'Margalla Hills',
      'Shah Allah Ditta', 'Bahria Town Islamabad', 'Golf City', 'Capital Smart City'
    ],
    'Rawalpindi': [
      'Saddar', 'Cantt', 'Chaklala', 'Westridge', 'Gulrez', 'Mall Road', 'Sixth Road',
      'PWD Housing Society', 'Bahria Town Rawalpindi', 'DHA Rawalpindi',
      'Ghauri Town', 'Liaquat Bagh', 'Raja Bazaar', 'Tariqabad', 'Dhoke Khabba',
      'Islamabad Highway', 'Khaqan Town', 'Gulshan-e-Abad', 'Moti Mahal'
    ],
    'Lahore': [
      'Gulberg', 'Defence', 'Model Town', 'Johar Town', 'Wapda Town',
      'Muslim Town', 'Allama Iqbal Town', 'Garden Town', 'DHA Lahore',
      'Bahria Town Lahore', 'Lake City', 'Shadman', 'LDA Avenue', 'Cantt',
      'Mall Road', 'Anarkali', 'Icchra', 'Samnabad', 'Qurtaba Chowk'
    ],
    'Karachi': [
      'Clifton', 'Defence', 'Gulshan-e-Iqbal', 'Gulistan-e-Johar', 'North Nazimabad',
      'Korangi', 'Landhi', 'Malir', 'Lyari', 'Saddar', 'Tariq Road', 'DHA Karachi',
      'Bahria Town Karachi', 'Naya Nazimabad', 'Gulshan-e-Maymar', 'Shah Faisal Town'
    ],
    'Peshawar': [
      'Sadar', 'Cantt', 'University Town', 'Hayatabad', 'Gulbahar', 'Faqirabad',
      'Tahkal', 'Phase 7 Hayatabad', 'DHA Peshawar', 'Regi Model Town'
    ],
    'Quetta': [
      'Cantt', 'Satellite Town', 'Jinnah Town', 'Gulshan-e-Iqbal', 'University Road',
      'Meezan Chowk', 'Hazarganji', 'Kechi Baig'
    ],
    'Faisalabad': [
      'Cantt', 'Gulshan-e-Jinnah', 'New City', 'Gulberg', 'Madina Town',
      'People\'s Colony', 'DHA Faisalabad', 'Millat Town'
    ],
    'Multan': [
      'Cantt', 'Gulshan-e-Raza', 'Shah Rukn-e-Alam', 'Jalalpur', 'DHA Multan',
      'City Housing Scheme'
    ],
    'Sialkot': [
      'Cantt', 'Model Town', 'Gulshan-e-Iqbal', 'Khayaban-e-Sialkot',
      'Defence Housing Authority'
    ],
    'Gujranwala': [
      'Cantt', 'New City', 'Gulshan-e-Iqbal', 'Model Town', 'DHA Gujranwala'
    ],
    'Abbottabad': [
      'Cantt', 'Jinnahabad', 'Mirpur', 'Nawanshehr', 'Gulshan-e-Abbottabad'
    ],
    'Murree': [
      'Mall Road', 'GPO', 'Sunset View', 'Nathia Gali', 'Changla Gali',
      'Bansra Gali', 'Bhurban'
    ],
  };

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // Current location get karein
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      _getAddressFromLocation(_selectedLocation);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Coordinates se address fetch karein
  Future<void> _getAddressFromLocation(LatLng position) async {
    try {
      final url = Uri.parse(
        '$_nominatimUrl/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'K-TEX App'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};

        final neighbourhood = address['neighbourhood'] ?? '';
        final suburb = address['suburb'] ?? '';
        final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
        final state = address['state'] ?? '';
        final country = address['country'] ?? 'Pakistan';

        String placeName = '';

        if (neighbourhood.isNotEmpty && !_isSectorOrZone(neighbourhood)) {
          placeName = neighbourhood;
        } else if (suburb.isNotEmpty && !_isSectorOrZone(suburb)) {
          placeName = suburb;
        } else if (city.isNotEmpty) {
          placeName = city;
        } else {
          placeName = data['display_name']?.split(',').first ??
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }

        placeName = _cleanPlaceName(placeName);

        String fullAddress = placeName;
        if (city.isNotEmpty && city != placeName) {
          fullAddress = '$placeName, $city';
        } else if (state.isNotEmpty && state != placeName) {
          fullAddress = '$placeName, $state';
        } else if (country.isNotEmpty && country != placeName) {
          fullAddress = '$placeName, $country';
        }

        setState(() {
          _selectedPlaceName = placeName;
          _selectedAddress = fullAddress;
          _selectedCity = city.isNotEmpty ? city : state;

          // 🔥 City controller mein city set karein
          if (_selectedCity.isNotEmpty) {
            _cityController.text = _selectedCity;
          }
        });

        // 🔥 City selected toh us city ke areas load karein
        if (_selectedCity.isNotEmpty) {
          _loadCityAreas(_selectedCity);
        }
      }
    } catch (e) {
      setState(() {
        _selectedAddress = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _selectedPlaceName = 'Selected Location';
        _selectedCity = 'Unknown';
      });
    }
  }

  // 🔥 Load city areas from predefined list OR search via API
  Future<void> _loadCityAreas(String cityName) async {
    List<Map<String, dynamic>> results = [];

    // Pehle predefined areas check karein
    String matchedCity = _findMatchingCity(cityName);
    if (matchedCity.isNotEmpty && _cityAreas.containsKey(matchedCity)) {
      final areas = _cityAreas[matchedCity]!;
      results = areas.map((area) => {
        'name': '$area, $matchedCity',
        'city': matchedCity,
        'isPredefined': true,
      }).toList();
    }

    // 🔥 Agar predefined areas nahi hain toh Nominatim API se search karein
    if (results.isEmpty) {
      try {
        final url = Uri.parse(
          '$_nominatimUrl/search?format=json&q=${Uri.encodeComponent(cityName)}&limit=15&addressdetails=1',
        );

        final response = await http.get(
          url,
          headers: {'User-Agent': 'K-TEX App'},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          results = data.map((item) {
            final address = item['address'] ?? {};
            final city = address['city'] ?? address['town'] ?? address['village'] ?? cityName;
            final displayName = item['display_name'] ?? '';

            // Extract area name (first part of display name)
            String areaName = displayName.split(',').first.trim();

            return {
              'name': areaName,
              'city': city,
              'lat': item['lat'] != null ? double.parse(item['lat']) : null,
              'lon': item['lon'] != null ? double.parse(item['lon']) : null,
              'display_name': displayName,
              'isPredefined': false,
            };
          }).toList();
        }
      } catch (e) {
        // API fail ho toh predefined areas use karein (if available)
        if (matchedCity.isNotEmpty && _cityAreas.containsKey(matchedCity)) {
          final areas = _cityAreas[matchedCity]!;
          results = areas.map((area) => {
            'name': '$area, $matchedCity',
            'city': matchedCity,
            'isPredefined': true,
          }).toList();
        }
      }
    }

    // Remove duplicates
    final seen = <String>{};
    results.removeWhere((item) => !seen.add(item['name']));

    setState(() {
      _searchResults = results;
      _showDropdown = results.isNotEmpty;
    });
  }

  // 🔥 Find matching city from predefined list
  String _findMatchingCity(String input) {
    final lowerInput = input.toLowerCase().trim();

    for (String city in _cityAreas.keys) {
      if (lowerInput.contains(city.toLowerCase()) ||
          city.toLowerCase().contains(lowerInput) ||
          _isSimilar(city, input)) {
        return city;
      }
    }
    return '';
  }

  // 🔥 Check if two strings are similar
  bool _isSimilar(String a, String b) {
    final aLower = a.toLowerCase().replaceAll(' ', '');
    final bLower = b.toLowerCase().replaceAll(' ', '');
    return aLower.contains(bLower) || bLower.contains(aLower);
  }

  bool _isSectorOrZone(String name) {
    final lower = name.toLowerCase();
    final sectorPatterns = ['sector', 'zone', 'block', 'street', 'phase', 'stadium', 'road'];
    for (var pattern in sectorPatterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  String _cleanPlaceName(String name) {
    final patterns = [
      r'^Sector\s+', r'^Zone\s+', r'^Block\s+', r'^Phase\s+',
      r'\s+Sector$', r'\s+Zone$', r'\s+Block$', r'\s+Phase$',
    ];

    String cleaned = name;
    for (var pattern in patterns) {
      cleaned = cleaned.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    return cleaned.trim();
  }

  // 🔥 Search location with city context
  Future<void> _searchLocationWithCity(String query) async {
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      String searchQuery = query;

      // Agar city selected hai toh us city mein search karein
      if (_cityController.text.isNotEmpty && !query.contains(_cityController.text)) {
        searchQuery = '$query, ${_cityController.text}';
      }

      final url = Uri.parse(
        '$_nominatimUrl/search?format=json&q=${Uri.encodeComponent(searchQuery)}&limit=10&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'K-TEX App'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) {
          final address = item['address'] ?? {};
          final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
          final displayName = item['display_name'] ?? '';
          String areaName = displayName.split(',').first.trim();

          return {
            'name': areaName,
            'city': city,
            'lat': item['lat'] != null ? double.parse(item['lat']) : null,
            'lon': item['lon'] != null ? double.parse(item['lon']) : null,
            'display_name': displayName,
            'isPredefined': false,
          };
        }).toList();

        setState(() {
          _searchResults = results.where((item) => item['lat'] != null).toList();
          _showDropdown = _searchResults.isNotEmpty;
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
        // Fallback to predefined areas
        _loadCityAreas(_cityController.text);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _showDropdown = false;
      });
      // Fallback to predefined areas
      _loadCityAreas(_cityController.text);
    }
  }

  // 🔥 Select location from dropdown
  void _selectLocationFromDropdown(Map<String, dynamic> location) {
    setState(() {
      _showDropdown = false;
      _searchController.text = location['name'];
    });

    if (location['lat'] != null && location['lon'] != null) {
      LatLng newLocation = LatLng(location['lat'], location['lon']);
      setState(() {
        _selectedLocation = newLocation;
      });
      _mapController.move(newLocation, 15);
      _getAddressFromLocation(newLocation);
    } else {
      // Agar coordinates nahi hain toh city search karein
      _searchLocationWithCity(location['name']);
    }
  }

  // 🔥 City search karne par areas load karein
  void _onCityChanged(String value) {
    if (value.length >= 2) {
      _loadCityAreas(value);
    } else {
      setState(() {
        _showDropdown = false;
        _searchResults.clear();
      });
    }
  }

  // 🔥 Confirm location select karein
  void _confirmLocation() {
    if (_selectedAddress.isNotEmpty) {
      // Agar user ne city select ki hai lekin address nahi fill kiya
      String addressToSend = _selectedPlaceName.isNotEmpty ? _selectedPlaceName : _selectedAddress;
      String cityToSend = _selectedCity.isNotEmpty ? _selectedCity : _cityController.text;

      widget.onLocationSelected(addressToSend, cityToSend);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.grey[900] : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectedAddress.isNotEmpty ? _confirmLocation : null,
            child: Text(
              'Confirm',
              style: TextStyle(
                fontFamily: 'Inter',
                color: _selectedAddress.isNotEmpty ? Colors.orange : Colors.grey,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 🔥 City Input with Dropdown
          _buildCitySearchBar(isDark),
          const SizedBox(height: 4),

          // 🔥 Location Search Bar
          _buildLocationSearchBar(isDark),
          const SizedBox(height: 4),

          // 🔥 Dropdown Results
          if (_showDropdown && _searchResults.isNotEmpty)
            _buildDropdownResults(isDark),

          // 🗺️ Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 14,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                    _showDropdown = false;
                  });
                  _getAddressFromLocation(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ktex',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📍 Selected Address Display
          _buildAddressDisplay(isDark),
        ],
      ),
    );
  }

  // 🔥 City Search Bar with Dropdown
  Widget _buildCitySearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Row(
        children: [
          const Icon(Icons.location_city, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _cityController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                onChanged: _onCityChanged,
                decoration: InputDecoration(
                  hintText: 'Enter city name (e.g., Islamabad, Lahore)',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: _cityController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _cityController.clear();
                        _searchResults.clear();
                        _showDropdown = false;
                      });
                    },
                  )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Location Search Bar
  Widget _buildLocationSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                onChanged: (value) {
                  if (value.length >= 2) {
                    _searchLocationWithCity(value);
                  } else {
                    setState(() {
                      _searchResults.clear();
                      _showDropdown = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search specific area...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchResults.clear();
                        _showDropdown = false;
                      });
                    },
                  )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location, color: Colors.orange),
            tooltip: 'Use current location',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // 🔥 Dropdown Results
  Widget _buildDropdownResults(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final location = _searchResults[index];
          final isPredefined = location['isPredefined'] ?? false;

          return ListTile(
            leading: Icon(
              isPredefined ? Icons.location_city : Icons.place,
              color: Colors.orange,
              size: 18,
            ),
            title: Text(
              location['name'] ?? '',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            subtitle: location['city'] != null && location['city'].toString().isNotEmpty
                ? Text(
              location['city'],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            )
                : null,
            trailing: isPredefined
                ? const Icon(Icons.star, color: Colors.amber, size: 16)
                : null,
            onTap: () => _selectLocationFromDropdown(location),
          );
        },
      ),
    );
  }

  Widget _buildAddressDisplay(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedAddress.isEmpty
                      ? 'Tap on the map to select your location'
                      : _selectedAddress,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (_selectedCity.isNotEmpty && _selectedCity != 'Unknown') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_city, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Text(
                  'City: $_selectedCity',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}