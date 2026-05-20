import 'dart:ui';
import 'package:delta_mager_pro_client_app/screens/b2b/widgets/b2b_cart_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delta_mager_pro_client_app/consts/constants/theme/app_colors.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/products_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/categories_bloc.dart';

import 'package:delta_mager_pro_client_app/logic/model/category.dart';
import 'package:delta_mager_pro_client_app/logic/model/product_model.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/widgets/b2b_product_card.dart';
import 'package:JoDija_tamplites/util/data_souce_bloc/feature_data_source_state.dart';
import 'package:JoDija_tamplites/tampletes/screens/routed_contral_panal/utiles/side_bar_navigation_router.dart';
import 'package:delta_mager_pro_client_app/consts/constants/values/routes.dart';
import 'package:delta_mager_pro_client_app/logic/mixins/system_manager.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/organization_config_bloc.dart';

class B2BAllProductsScreen extends StatefulWidget with AppShellRouterMixin {
  final String? organizationId;

  B2BAllProductsScreen({
    super.key,
    this.organizationId,
  });

  @override
  State<B2BAllProductsScreen> createState() => _B2BAllProductsScreenState();
}

class _B2BAllProductsScreenState extends State<B2BAllProductsScreen> with SystemManager {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;

  String get effectiveOrganizationId {
    if (widget.organizationId != null && widget.organizationId!.isNotEmpty) {
      return widget.organizationId!;
    }
    return AppRoutes.activeOrgName;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load all public products and categories initially
      context.read<ProductsBloc>().loadPublicProducts(
        categoryId: null,
        name: null,
      );
      context.read<CategoriesBloc>().loadPublicCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600
        ? 2
        : screenWidth < 900
            ? 3
            : 4;
    final double childAspectRatio = screenWidth < 600
        ? 0.58
        : screenWidth < 900
            ? 0.7
            : 0.75;

    final configBloc = context.watch<OrganizationConfigBloc>();
    final orgConfig = configBloc.state.itemState.maybeWhen(
      success: (data) => data,
      orElse: () => null,
    );

    if (orgConfig == null) {
      getSystemConfig(context, feature: 'products', mainPath: AppRoutes.products);
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🌟 Dynamically compute a background image based on selected category or active visible product
    String? bgImageUrl;
    final categoriesBlocState = context.watch<CategoriesBloc>().state;
    final productsBlocState = context.watch<ProductsBloc>().state;

    if (_selectedCategoryId != null) {
      categoriesBlocState.listState.maybeWhen(
        success: (categories) {
          if (categories != null) {
            try {
              final selectedCat = categories.firstWhere((c) => c.id == _selectedCategoryId);
              if (selectedCat.imageUrl != null && selectedCat.imageUrl!.isNotEmpty) {
                bgImageUrl = selectedCat.imageUrl;
              }
            } catch (_) {}
          }
        },
        orElse: () {},
      );
    }

    if (bgImageUrl == null) {
      productsBlocState.listState.maybeWhen(
        success: (products) {
          if (products != null && products.isNotEmpty) {
            var filtered = products;
            if (_selectedCategoryId != null) {
              filtered = filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
            }
            final query = _searchController.text.trim().toLowerCase();
            if (query.isNotEmpty) {
              filtered = filtered.where((p) {
                return p.name.ar.toLowerCase().contains(query) ||
                       p.name.en.toLowerCase().contains(query);
              }).toList();
            }
            if (filtered.isNotEmpty) {
              bgImageUrl = filtered.first.mainImage;
            }
          }
        },
        orElse: () {},
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Dynamic Glassmorphic Product Image Background
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: bgImageUrl != null
                  ? Stack(
                      key: ValueKey<String>(bgImageUrl!),
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          bgImageUrl!,
                          fit: BoxFit.cover,
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            color: Colors.black.withOpacity(isDark ? 0.65 : 0.4),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      key: const ValueKey<String>('fallback_gradient'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [DarkColors.primary, DarkColors.surface]
                              : [LightColors.primary, Colors.blueAccent],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            right: -50,
                            top: -50,
                            child: CircleAvatar(
                              radius: 180,
                              backgroundColor: Colors.white.withOpacity(0.04),
                            ),
                          ),
                          Positioned(
                            left: -30,
                            bottom: -30,
                            child: CircleAvatar(
                              radius: 120,
                              backgroundColor: Colors.white.withOpacity(0.02),
                            ),
                          ),
                          Container(color: Colors.black.withOpacity(0.15)),
                        ],
                      ),
                    ),
            ),
          ),

          // 2. Main Scrollable Content Panel
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 120),

                    // Translucent panel containing search, categories and product list
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.black.withOpacity(0.85) 
                                : Colors.white.withOpacity(0.92),
                            border: Border.all(
                              color: (isDark ? Colors.white : Colors.white).withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Screen Title
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'كل المنتجات',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: isDark ? DarkColors.primary : LightColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Search Bar (Textfield)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) => setState(() {}),
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'ابحث عن اسم المنتج...',
                                      hintStyle: TextStyle(
                                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                                        fontSize: 13,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: isDark ? DarkColors.primary : LightColors.primary,
                                      ),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(Icons.clear, color: isDark ? Colors.white70 : Colors.black54),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade50,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: isDark ? DarkColors.primary : LightColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Categories Filter horizontal List (Chips)
                              BlocBuilder<CategoriesBloc, FeaturDataSourceState<CategoryModel>>(
                                builder: (context, state) {
                                  return state.listState.maybeWhen(
                                    success: (categories) {
                                      final cats = categories ?? [];
                                      return Container(
                                        height: 50,
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          itemCount: cats.length + 1,
                                          itemBuilder: (context, index) {
                                            final isAll = index == 0;
                                            final cat = isAll ? null : cats[index - 1];
                                            final isSelected = isAll
                                                ? _selectedCategoryId == null
                                                : _selectedCategoryId == cat?.id;

                                            return Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: ChoiceChip(
                                                label: Text(isAll ? 'الكل' : cat!.nameAr),
                                                selected: isSelected,
                                                onSelected: (selected) {
                                                  setState(() {
                                                    _selectedCategoryId = isAll ? null : cat!.id;
                                                  });
                                                },
                                                selectedColor: isDark 
                                                    ? DarkColors.primary 
                                                    : LightColors.primary,
                                                backgroundColor: isDark 
                                                    ? Colors.white10 
                                                    : Colors.black.withOpacity(0.05),
                                                labelStyle: TextStyle(
                                                  color: isSelected 
                                                      ? Colors.white 
                                                      : (isDark ? Colors.white70 : Colors.black87),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    orElse: () => const SizedBox.shrink(),
                                  );
                                },
                              ),

                              // Divider
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                              ),
                              const SizedBox(height: 8),

                              // Products List Loader & Grid
                              BlocBuilder<ProductsBloc, FeaturDataSourceState<ProductModel>>(
                                builder: (context, state) {
                                  return state.listState.when(
                                    init: () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 40),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    loading: () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 40),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    success: (products) {
                                      var filtered = products ?? [];

                                      // 1. Filter by category if selected
                                      if (_selectedCategoryId != null) {
                                        filtered = filtered
                                            .where((p) => p.categoryId == _selectedCategoryId)
                                            .toList();
                                      }

                                      // 2. Filter by search query if any
                                      final query = _searchController.text.trim().toLowerCase();
                                      if (query.isNotEmpty) {
                                        filtered = filtered.where((p) {
                                          return p.name.ar.toLowerCase().contains(query) ||
                                                 p.name.en.toLowerCase().contains(query);
                                        }).toList();
                                      }

                                      if (filtered.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                                            child: Text(
                                              'لا توجد منتجات مطابقة حالياً',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : Colors.black54,
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          childAspectRatio: childAspectRatio,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: filtered.length,
                                        itemBuilder: (context, index) {
                                          return B2BProductCard(
                                            product: filtered[index],
                                            isDark: isDark,
                                          );
                                        },
                                      );
                                    },
                                    failure: (error, retry) => Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'حدث خطأ في تحميل المنتجات',
                                              style: TextStyle(
                                                color: isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: retry,
                                              child: const Text('إعادة المحاولة'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Overlay Navigation Header (Back and Cart)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.12)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          onPressed: () {
                            widget.goRoute(context, AppRoutes.b2bHome);
                          },
                        ),
                      ),
                    ),

                    // Cart badge
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 44,
                        width: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.12)
                                : Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: B2BCartBadge(
                          organizationId: effectiveOrganizationId,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
