import 'package:delta_mager_pro_client_app/configs/app_shell_config.dart';

class AppRoutes {
  static String? _internalOrgName;

  // 🌍 بيانات عالمية محفوظة طوال فترة تشغيل التطبيق

  /// 🚀 استخراج اسم المنظمة الفعال مع التعامل مع القيم الافتراضية
  static String get activeOrgName {
    if (_internalOrgName != null &&
        _internalOrgName != "" &&
        _internalOrgName != ":sorgName" &&
        _internalOrgName != ":orgName") {
      return _internalOrgName!;
    }
    return AppShellConfigs.defaultOrgName;
  }

  static set defaultOrgName(String value) {
    AppShellConfigs.defaultOrgName = value;
  }

  static set activeOrgName(String value) {
    _internalOrgName = value;
  }

  static const String splash = '/splash';
  static String loginWithOrgName(String orgName) {
    return '/login';
  }

  static String welcomWithOrgName(String orgName) {
    return '/welcom';
  }

  static String catigoryWithOrgName(String orgName) {
    return '/category';
  }

  static String productsWithOrgName(String orgName) {
    return '/products';
  }

  static String offersWithOrgName(String orgName) {
    return '/offers';
  }

  static String ordersWithOrgName(String orgName) {
    return '/orders';
  }

  static String aboutUsPrivacyWithOrgName(String orgName) {
    return '/about-us-privacy';
  }

  static String blogsWithOrgName(String orgName) {
    return '/blogs';
  }

  static String usersWithOrgName(String orgName) {
    return '/users';
  }

  static String standaloneWithOrgName(String orgName) {
    return '/standalone';
  }

  static String testMasterGridWithOrgName(String orgName) {
    return '/test-master-grid';
  }

  static String policiesWithOrgName(String orgName) {
    return '/policies';
  }

  static String get logIn => "/login";
  static String get welcome => "/welcom";
  static const String loginAdmin = '/delta/matgerpro/loginAdmin';
  static const String adminOperations = '/delta/matgerpro/adminOperations';
  static const String customAnalyses = '/analyses/custem/:org/new';
  static const String customAnalyses2 = '/analyses/custem2/:id/new';
  static String get analyses => "/analyses";
  static String get settings => "/settings";
  static String get systemSettings => "/system-settings";
  static String get systemManagment => "/system-managment";
  static String get cpCategory => "/category";
  static String get products => "/products/:catid";
  static String get offers => "/offers";
  static String get cpOrders => "/orders";
  static String get aboutUsPrivacy => "/about-us-privacy";
  static String get cpBlogs => "/blogs";
  static String get cpUsers => "/users";
  static String get standalone => "/standalone";
  static String get testMasterGrid => "/test-master-grid";
  static String get policies => "/policies";
  static String get b2bHome => "/b2b-home";
  static String get orderPaths => "/order-paths";
}
