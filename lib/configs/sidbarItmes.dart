import 'package:delta_mager_pro_client_app/consts/constants/values/routes.dart';
import 'package:delta_mager_pro_client_app/consts/constants/values/route_ids.dart';
import 'package:JoDija_tamplites/tampletes/screens/routed_contral_panal/models/route_item.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/b2b_home_screen.dart';
import 'package:flutter/material.dart' show Icons;

class SidebarItemsConfig {
  List<RouteItem> get items {
    return [
      RouteItem(
        id: AppRouteIds.b2bHome,
        path: AppRoutes.b2bHome,
        label: 'الرئيسية (الطلبات)',
        icon: Icons.storefront,
        content: B2BHomeScreen(),
        prams: {"orgName": AppRoutes.activeOrgName},
      ),
    ];
  }
}
