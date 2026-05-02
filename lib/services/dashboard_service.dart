 
import '../models/dashboard.dart';
import 'api_service.dart';

class DashboardService {
  static Future<FarmerDashboard> getFarmerDashboard() async {
    final data = await ApiService.get('/dashboard/farmer/');
    return FarmerDashboard.fromJson(data);
  }

  static Future<AdminDashboard> getAdminDashboard() async {
    final data = await ApiService.get('/dashboard/admin/');
    return AdminDashboard.fromJson(data);
  }
}