import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  // initialize supabase client
  final supabase = Supabase.instance.client;

  // check database connection
  Future<bool> checkDatabaseConnection() async {
    try {
      // test database connection: query table
      final response = await supabase
          .from('sampleAccount') // table name
          .select()
          .limit(1);

      // if response is successful but no data, return true
      if (response.isEmpty) {
        return true;
      }
      // if response is successful, return true
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      final response = await supabase.from('sampleAccount').select();

      return response;
    } catch (e) {
      throw Exception('Failed to insert data: $e');
    }
  }
}
