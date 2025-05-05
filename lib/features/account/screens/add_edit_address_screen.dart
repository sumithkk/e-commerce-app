import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:chucker_flutter/chucker_flutter.dart';

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final Dio dio = Dio()..interceptors.add(ChuckerDioInterceptor());
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController line1Controller = TextEditingController();

  bool isLoading = false;

  Future<void> saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.get('userId')?.toString();
    final token = prefs.getString('accessToken');

    if (userId == null || token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required')));
      return;
    }

    setState(() => isLoading = true);

    final Map<String, dynamic>? addressItem =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isEditing = addressItem != null;
    final addressId = addressItem?['id'];

    final url =
        isEditing
            ? 'http://57.128.166.138:2000/api/v1/address/$addressId'
            : 'http://57.128.166.138:2000/api/v1/address/customer/$userId';

    final body = {
      "firstName": firstNameController.text,
      "lastName": lastNameController.text,
      "phoneNumber": phoneNumberController.text,
      "email": emailController.text,
      "country": countryController.text,
      "street": streetController.text,
      "city": cityController.text,
      "line1": line1Controller.text,
    };

    try {
      final response =
          isEditing
              ? await dio.put(
                url,
                options: Options(
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                ),
                data: jsonEncode(body),
              )
              : await dio.post(
                url,
                options: Options(
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                ),
                data: jsonEncode(body),
              );

      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Address updated successfully'
                  : 'Address added successfully',
            ),
          ),
        );
        Navigator.pop(context, true); // ✅ Return true to refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to save address'),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [Save Address] Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? addressItem =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final bool isEditing = addressItem != null;

    if (isEditing && firstNameController.text.isEmpty) {
      firstNameController.text = addressItem['firstName'] ?? '';
      lastNameController.text = addressItem['lastName'] ?? '';
      phoneNumberController.text = addressItem['phoneNumber'] ?? '';
      emailController.text = addressItem['email'] ?? '';
      countryController.text = addressItem['country'] ?? '';
      streetController.text = addressItem['street'] ?? '';
      cityController.text = addressItem['city'] ?? '';
      line1Controller.text = addressItem['line1'] ?? '';
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Address' : 'Add Address')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                        ),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: countryController,
                        decoration: const InputDecoration(labelText: 'Country'),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: streetController,
                        decoration: const InputDecoration(labelText: 'Street'),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: line1Controller,
                        decoration: const InputDecoration(
                          labelText: 'Address Line 1',
                        ),
                        validator:
                            (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saveAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          child: Text(
                            isEditing ? 'Update Address' : 'Save Address',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
