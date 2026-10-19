import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Calls the Supabase Edge Function 'create-invoice' to generate a Xendit payment link.
  Future<Map<String, dynamic>?> createInvoice({
    required String externalId,
    required double amount,
    required String payerEmail,
    required String description,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-invoice',
        body: {
          'external_id': externalId,
          'amount': amount,
          'payer_email': payerEmail,
          'description': description,
        },
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        print('Error from Edge Function: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Exception while creating invoice: $e');
      return null;
    }
  }
}