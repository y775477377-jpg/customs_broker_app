import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeclarationDocumentsWidget extends StatefulWidget {
  final String declarationId;
  final String accessToken;

  const DeclarationDocumentsWidget({
    Key? key,
    required this.declarationId,
    required this.accessToken,
  }) : super(key: key);

  @override
  _DeclarationDocumentsWidgetState createState() => _DeclarationDocumentsWidgetState();
}

class _DeclarationDocumentsWidgetState extends State<DeclarationDocumentsWidget> {
  bool _isUploading = false;
  String _selectedDocType = 'bill_of_lading'; // أحد أنواع المستندات الـ 10 المدعومة

  final Map<String, String> _docTypes = {
    'bill_of_lading': 'بوليصة شحن',
    'invoice': 'فاتورة تجارية',
    'certificate_of_origin': 'شهادة منشأ',
    'truck_photos': 'صور الشاحنات',
  };

  Future<void> _pickAndUploadFile() async {
    // اختيار ملف (PDF أو صور فقط)
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      
      // التحقق من الحجم (أقل من 15MB)
      int fileSizeInBytes = await file.length();
      if (fileSizeInBytes > 15 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حجم الملف يتجاوز الحد المسموح (15MB)')),
        );
        return;
      }

      setState(() {
        _isUploading = true;
      });

      try {
        var uri = Uri.parse('http://localhost:4000/declarations/${widget.declarationId}/documents');
        var request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer ${widget.accessToken}'
          ..fields['document_type'] = _selectedDocType
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

        var response = await request.send();
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفع المستند بنجاح')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الرفع: رمز الخطأ ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في الاتصال: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مستندات الإقرار الجمركي',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedDocType,
              items: _docTypes.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList,
              onChanged: (value) {
                setState(() {
                  _selectedDocType = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'نوع المستند',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadFile,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'جاري الرفع...' : 'اختر ملف وارفع المستند'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
