import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountingReportsScreen extends StatefulWidget {
  final String accessToken;

  const AccountingReportsScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _AccountingReportsScreenState createState() => _AccountingReportsScreenState();
}

class _AccountingReportsScreenState extends State<AccountingReportsScreen> {
  bool _isLoading = false;
  String _reportType = 'p_l'; // p_l (أرباح وخسائر) أو statement (كشف حساب)
  List<dynamic> _reportData = [];
  final TextEditingController _accountRefController = TextEditingController();

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _reportData = [];
    });

    try {
      String url = 'http://localhost:4000/accounting/reports/profit-loss';
      if (_reportType == 'statement') {
        url = 'http://localhost:4000/accounting/reports/statement?account_ref_id=${_accountRefController.text}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // افتراض أن البيانات تعود كقائمة أو كائن يحتوي على تفاصيل
          _reportData = data is List ? data : [data];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في جلب التقرير')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: $e')),
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
        title: const Text('التقارير المحاسبية'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _reportType,
              items: const [
                DropdownMenuItem(value: 'p_l', child: Text('تقرير الأرباح والخسائر')),
                DropdownMenuItem(value: 'statement', child: Text('كشف حساب تفصيلي')),
              ],
              onChanged: (value) {
                setState(() {
                  _reportType = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'نوع التقرير',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_reportType == 'statement') ...[
              TextFormField(
                controller: _accountRefController,
                decoration: const InputDecoration(
                  labelText: 'معرّف الحساب (Account Ref ID)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchReport,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('عرض التقرير'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _reportData.length,
                      itemBuilder: (context, index) {
                        final item = _reportData[index];
                        return Card(
                          child: ListTile(
                            title: Text(item['title'] ?? 'بند محاسبي'),
                            subtitle: Text(item['description'] ?? ''),
                            trailing: Text(
                              '${item['amount'] ?? '0.00'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
