import 'package:delta_mager_pro_client_app/consts/constants/values/routes.dart';
import 'package:delta_mager_pro_client_app/consts/constants/values/route_ids.dart';
import 'package:JoDija_tamplites/tampletes/screens/routed_contral_panal/models/route_item.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/b2b_home_screen.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/b2b_products_screen.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/b2b_all_products_screen.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/product_details_screen.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/splash_screen.dart';
import 'package:flutter/material.dart' show Icons;

class SidebarItemsConfig {
  List<RouteItem> get items {
    return [
      RouteItem(
        id: 'splash',
        path: AppRoutes.splash,
        isSideBarRouted: false,
        label: 'جاري التحميل',
        icon: Icons.refresh,
        content: SplashScreen(),
      ),
      RouteItem(
        id: AppRouteIds.b2bHome,
        path: AppRoutes.b2bHome,
        isSideBarRouted: false,
        label: 'الرئيسية (الطلبات)',
        icon: Icons.storefront,
        content: B2BHomeScreen(),
      ),
      RouteItem(
        id: AppRouteIds.allProducts,
        path: AppRoutes.allProducts,
        isSideBarRouted: false,
        label: 'كل المنتجات',
        icon: Icons.grid_view_outlined,
        content: B2BAllProductsScreen(),
      ),
      RouteItem(
        id: AppRouteIds.products,
        path: AppRoutes.products,
        isSideBarRouted: false,
        label: 'المنتجات',
        icon: Icons.shopping_bag,
        content: B2BProductsScreen(),
        prams: {"catid": "dd"},
      ),
      RouteItem(
        id: 'productDetails',
        path: AppRoutes.productDetails,
        isSideBarRouted: false,
        label: 'تفاصيل المنتج',
        icon: Icons.info,
        content: ProductDetailsScreen(),
        prams: {"productid": "dd"},
      ),
    ];
  }
}
