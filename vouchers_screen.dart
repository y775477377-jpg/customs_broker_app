import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VouchersAndExpensesScreen extends StatefulWidget {
  final String accessToken;

  const VouchersAndExpensesScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _VouchersAndExpensesScreenState createState() => _VouchersAndExpensesScreenState();
}

class _VouchersAndExpensesScreenState extends State<VouchersAndExpensesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // أنواع المعاملات: receipt (قبض), payment (صرف), expense (مصروف)
  String _voucherType = 'receipt';
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _refIdController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submitVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:4000/accounting/vouchers'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': _voucherType,
          'amount': double.parse(_amountController.text),
          'account_ref_id': _refIdController.text,
          'description': _descriptionController.text,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ السند وترحيله محاسبياً بنجاح')),
        );
        _amountController.clear();
        _refIdController.clear();
        _descriptionController.clear();
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${errorData['message'] ?? 'فشل العملية'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في الاتصال: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السندات والمصروفات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _voucherType,
                items: const [
                  DropdownMenuItem(value: 'receipt', child: Text('سند قبض (إيراد/تحصيل)')),
                  DropdownMenuItem(value: 'payment', child: Text('سند صرف (دفع)')),
                  DropdownMenuItem(value: 'expense', child: Text('تسجيل مصروف')),
                ],
                onChanged: (value) {
                  setState(() {
                    _voucherType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'نوع السند أو المعاملة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'الرجاء إدخال مبلغ صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _refIdController,
                decoration: const InputDecoration(
                  labelText: 'معرّف الحساب أو الجهة (Account Ref ID)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'هذا الحقل مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'البيان / الوصف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitVoucher,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ وترحيل السند',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
