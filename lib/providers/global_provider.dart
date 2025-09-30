import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GlobalProvider extends ChangeNotifier {
  Map<String, dynamic> globalData = {};

  // Basic setValue and getValue methods
  void setValue(String key, dynamic value) {
    globalData[key] = value;
    notifyListeners();
  }

  dynamic getValue(String key) => globalData[key];

  // Business Details Methods
  void setBusinessDetails({required String name}) {
    globalData['name'] = name;
    notifyListeners();
  }

  // Portfolio Images Methods
  void setPortfolioImages(List<String> images) {
    globalData['portfolio_images'] = images;
    notifyListeners();
  }

  void addPortfolioImage(String imageUrl) {
    if (globalData['portfolio_images'] == null) {
      globalData['portfolio_images'] = <String>[];
    }
    (globalData['portfolio_images'] as List<String>).add(imageUrl);
    notifyListeners();
  }

  void removePortfolioImage(String imageUrl) {
    (globalData['portfolio_images'] as List<String>?)?.remove(imageUrl);
    notifyListeners();
  }

  // Categories/Services Methods
  void setCategories(List<Map<String, dynamic>> categories) {
    globalData['categories'] = categories;
    notifyListeners();
  }

  void addCategory({
    required String categoryId,
    required double price,
    String? delivery_time,
    List<String>? display_images,
    String? category_name,
  }) {
    if (globalData['categories'] == null) {
      globalData['categories'] = <Map<String, dynamic>>[];
    }

    final category = {
      'category_id': categoryId,
      'price': price,
      'delivery_time': delivery_time ?? '',
      'display_images': display_images ?? [],
      'category_name': category_name ?? '',
    };

    (globalData['categories'] as List<Map<String, dynamic>>).add(category);
    notifyListeners();
  }

  void removeCategory(String categoryId) {
    (globalData['categories'] as List<Map<String, dynamic>>?)
        ?.removeWhere((category) => category['category_id'] == categoryId);
    notifyListeners();
  }

  void updateCategory({
    required String categoryId,
    double? price,
    String? deliveryTime,
    List<String>? displayImages,
    String? categoryName,
  }) {
    final categories = globalData['categories'] as List<Map<String, dynamic>>?;
    if (categories == null) return;

    final index = categories.indexWhere((c) => c['category_id'] == categoryId);
    if (index != -1) {
      if (price != null) categories[index]['price'] = price;
      if (deliveryTime != null) categories[index]['delivery_time'] = deliveryTime;
      if (displayImages != null) categories[index]['display_images'] = displayImages;
      if (categoryName != null) categories[index]['category_name'] = categoryName;
      notifyListeners();
    }
  }

  void setAddress(Map<String, dynamic> addressData) {
    globalData['address'] = addressData;
    notifyListeners();
    debugPrint('Address saved to GlobalProvider: $addressData');
  }

// Get address data
  Map<String, dynamic>? getAddress() {
    return globalData['address'] as Map<String, dynamic>?;
  }

// Update specific address fields
  void updateAddress({
    String? locationName,
    String? fullAddress,
    double? latitude,
    double? longitude,
  }) {
    Map<String, dynamic> currentAddress = getAddress() ?? {};

    if (locationName != null) currentAddress['locationName'] = locationName;
    if (fullAddress != null) currentAddress['fullAddress'] = fullAddress;
    if (latitude != null) currentAddress['latitude'] = latitude;
    if (longitude != null) currentAddress['longitude'] = longitude;

    setAddress(currentAddress);
  }

  // Address Methods
  // void setAddress({
  //   required String street,
  //   required String city,
  //   required String state,
  //   required String pincode,
  //   required String mobile,
  // }) {
  //   globalData['address'] = {
  //     'street': street,
  //     'city': city,
  //     'state': state,
  //     'pincode': pincode,
  //     'mobile': mobile,
  //   };
  //   notifyListeners();
  // }

  void updateAddressField(String field, String value) {
    if (globalData['address'] == null) {
      globalData['address'] = <String, dynamic>{};
    }
    (globalData['address'] as Map<String, dynamic>)[field] = value;
    notifyListeners();
  }

  // Location Methods
  void setLocation({required double longitude, required double latitude}) {
    globalData['location'] = {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    };
    notifyListeners();
  }

  // KYC Document Methods
  void setKycAddressProof({required String frontImageUrl, required String backImageUrl}) {
    globalData['kyc_address_proof_front'] = frontImageUrl;
    globalData['kyc_address_proof_back'] = backImageUrl;
    notifyListeners();
  }

  void setIdProof({required String frontImageUrl, required String backImageUrl}) {
    globalData['id_proof_front'] = frontImageUrl;
    globalData['id_proof_back'] = backImageUrl;
    notifyListeners();
  }

  // Individual document setters
  void setKycAddressProofFront(String imageUrl) {
    globalData['kyc_address_proof_front'] = imageUrl;
    notifyListeners();
  }

  void setKycAddressProofBack(String imageUrl) {
    globalData['kyc_address_proof_back'] = imageUrl;
    notifyListeners();
  }

  void setIdProofFront(String imageUrl) {
    globalData['id_proof_front'] = imageUrl;
    notifyListeners();
  }

  void setIdProofBack(String imageUrl) {
    globalData['id_proof_back'] = imageUrl;
    notifyListeners();
  }

  // Utility Methods
  bool isDataComplete() {
    final requiredFields = [
      'name',
      'portfolio_images',
      'categories',
      'address',
      'location',
      'kyc_address_proof_front',
      'kyc_address_proof_back',
      'id_proof_front',
      'id_proof_back',
    ];

    for (String field in requiredFields) {
      if (globalData[field] == null) return false;
    }

    if ((globalData['portfolio_images'] as List?)?.isEmpty ?? true) return false;
    if ((globalData['categories'] as List?)?.isEmpty ?? true) return false;

    return true;
  }

  List<String> getMissingFields() {
    final requiredFields = [
      'name',
      'portfolio_images',
      'categories',
      'address',
      'location',
      'kyc_address_proof_front',
      'kyc_address_proof_back',
      'id_proof_front',
      'id_proof_back',
    ];

    List<String> missingFields = [];
    for (String field in requiredFields) {
      if (globalData[field] == null) missingFields.add(field);
    }

    if ((globalData['portfolio_images'] as List?)?.isEmpty ?? true) {
      missingFields.add('portfolio_images (empty)');
    }
    if ((globalData['categories'] as List?)?.isEmpty ?? true) {
      missingFields.add('categories (empty)');
    }

    return missingFields;
  }

  Map<String, dynamic> getApiPayload() {
    return Map<String, dynamic>.from(globalData);
  }

  // API Call Method
  Future<bool> submitData({required String apiUrl, Map<String, String>? headers}) async {
    if (!isDataComplete()) {
      final missing = getMissingFields();
      throw Exception('Data is incomplete. Missing fields: ${missing.join(', ')}');
    }

    final payload = getApiPayload();
    final defaultHeaders = {'Content-Type': 'application/json'};
    if (headers != null) defaultHeaders.addAll(headers);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: defaultHeaders,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) return true;

    throw Exception('API call failed with status: ${response.statusCode}, body: ${response.body}');
  }

  // Clear all data
  void clearData() {
    globalData.clear();
    notifyListeners();
  }

  // Clear specific field
  void clearField(String key) {
    globalData.remove(key);
    notifyListeners();
  }

  // Get data summary for debugging
  Map<String, dynamic> getDataSummary() {
    return {
      'name': globalData['name'],
      'portfolio_images_count': (globalData['portfolio_images'] as List?)?.length ?? 0,
      'categories_count': (globalData['categories'] as List?)?.length ?? 0,
      'address_set': globalData['address'] != null,
      'location_set': globalData['location'] != null,
      'kyc_docs_count': [
        globalData['kyc_address_proof_front'],
        globalData['kyc_address_proof_back'],
        globalData['id_proof_front'],
        globalData['id_proof_back'],
      ].where((doc) => doc != null).length,
      'is_complete': isDataComplete(),
    };
  }

  // Debug method to print current state
  void printCurrentData() {
    if (kDebugMode) {
      print('Current Global Data:');
      print(jsonEncode(globalData));
      print('\nData Summary:');
      print(jsonEncode(getDataSummary()));
    }
  }
}
