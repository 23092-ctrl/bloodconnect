class ApiEndpoints {
  static const baseUrl = 'http://192.168.100.32/api';

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';

  // Users
  static const me = '/users/me';
  static const users = '/users';

  // Blood Centers
  static const bloodCenters = '/blood-centers';
  static const nearestCenters = '/blood-centers/nearest';

  // Blood Inventory
  static const bloodInventory = '/blood-inventory';
  static const globalSummary = '/blood-inventory/summary/global';

  // Donations
  static const donations = '/donations';
  static const myDonations = '/donations/my';
  static const donationStats = '/donations/my/stats';

  // Notifications
  static const notifications = '/notifications';

  // Appointments
  static const appointments = '/appointments';
  static const myAppointments = '/appointments/my';
}
