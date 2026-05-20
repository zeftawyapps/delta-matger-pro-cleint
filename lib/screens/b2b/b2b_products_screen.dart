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

class B2BProductsScreen extends StatefulWidget with AppShellRouterMixin {
  final String? organizationId;
  final CategoryModel? categoryFilter;
  final String? searchQuery;

  B2BProductsScreen({
    super.key,
    this.organizationId,
    this.categoryFilter,
    this.searchQuery,
  });

  @override
  State<B2BProductsScreen> createState() => _B2BProductsScreenState();
}

class _B2BProductsScreenState extends State<B2BProductsScreen> {
  String get effectiveOrganizationId {
    if (widget.organizationId != null && widget.organizationId!.isNotEmpty) {
      return widget.organizationId!;
    }
    return AppRoutes.activeOrgName;
  }

  CategoryModel? get effectiveCategoryFilter {
    if (widget.categoryFilter != null) return widget.categoryFilter;
    final queryMap = widget.getPrams();
    final categoryId = queryMap?['catid'];
    if (categoryId != null && categoryId != "") {
      CategoryModel? category;
      context.read<CategoriesBloc>().state.listState.maybeWhen(
        success: (categories) {
          if (categories != null) {
            try {
              category = categories.firstWhere((c) => c.id == categoryId);
            } catch (_) {}
          }
        },
        orElse: () {},
      );
      return category;
    }
    return null;
  }

  String? get effectiveSearchQuery {
    if (widget.searchQuery != null) return widget.searchQuery;
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catId = widget.getPrams()?['catid'];
      final query = effectiveSearchQuery;

      context.read<ProductsBloc>().loadPublicProducts(
        categoryId: (catId == 'all' || catId == null) ? null : catId,
        name: null,
      );

      // Load public categories in case we deep linked directly here
      context.read<CategoriesBloc>().loadPublicCategories();


    });
  }

  @override
  void didUpdateWidget(covariant B2BProductsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldParams = oldWidget.getPrams();
    final newParams = widget.getPrams();
    if (oldParams?['catid'] != newParams?['catid']) {
      final catId = newParams?['catid'];
      final query = effectiveSearchQuery;
      context.read<ProductsBloc>().loadPublicProducts(
        categoryId: (catId == 'all' || catId == null) ? null : catId,
        name: query,
        forceRefresh: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesBloc, FeaturDataSourceState<CategoryModel>>(
      builder: (context, categoriesState) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final category = effectiveCategoryFilter;
        final query = effectiveSearchQuery;

        final title = category?.nameAr ?? 'المنتجات';

        return Scaffold(
          body: Stack(
            children: [
              // 1. Full-screen Background Image
              if (category != null &&
                  category.imageUrl != null &&
                  category.imageUrl!.isNotEmpty)
                Positioned.fill(
                  child: Hero(
                    tag: 'category_${category.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(category.imageUrl!, fit: BoxFit.cover),
                        // Soft dark overlay to make light cards stand out beautifully
                        Container(color: Colors.black.withOpacity(0.45)),
                      ],
                    ),
                  ),
                )
              else
                // Beautiful abstract gradient if no category or image is available
                Positioned.fill(
                  child: Container(
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
                        // Dark tint
                        Container(color: Colors.black.withOpacity(0.2)),
                      ],
                    ),
                  ),
                ),

              // 2. Full-screen Scrollable Panel on top of the background
              Positioned.fill(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Spacer of 150px to let the top of the background show
                        const SizedBox(height: 150),

                        // The Large Translucent Walnut Shell Panel (Light theme translucent)
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
                                color: Colors.white.withOpacity(
                                  0.92,
                                ), // Beautiful light translucent background
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.6),
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
                                  // Drag Handle Accent
                                  const SizedBox(height: 14),
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Category title and Description
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors
                                                      .black87, // High contrast text on light background
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: LightColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (category != null &&
                                            category
                                                .descriptionAr
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            category.descriptionAr,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.3,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Subtle divider
                                  Container(
                                    height: 1,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    color: Colors.black.withOpacity(0.08),
                                  ),
                                  const SizedBox(height: 8),

                                  // Products list BLoC loader
                                  BlocBuilder<
                                    ProductsBloc,
                                    FeaturDataSourceState<ProductModel>
                                  >(
                                    builder: (context, state) {
                                      return state.listState.when(
                                        init: () => const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 40,
                                            ),
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        loading: () => const Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 40,
                                            ),
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        success: (products) {
                                          var filteredProducts = products ?? [];

                                          if (category != null) {
                                            filteredProducts = filteredProducts
                                                .where(
                                                  (p) =>
                                                      p.categoryId ==
                                                      category.id,
                                                )
                                                .toList();
                                          }

                                          if (query != null &&
                                              query.isNotEmpty) {
                                            final q = query.toLowerCase();
                                            filteredProducts = filteredProducts
                                                .where((p) {
                                                  return p.name.ar
                                                          .toLowerCase()
                                                          .contains(q) ||
                                                      p.name.en
                                                          .toLowerCase()
                                                          .contains(q);
                                                })
                                                .toList();
                                          }

                                          if (filteredProducts.isEmpty) {
                                            return const Center(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 60,
                                                  horizontal: 20,
                                                ),
                                                child: Text(
                                                  'لا توجد منتجات',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          return GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 4,
                                                  childAspectRatio: 0.75,
                                                  crossAxisSpacing: 12,
                                                  mainAxisSpacing: 12,
                                                ),
                                            itemCount: filteredProducts.length,
                                            itemBuilder: (context, index) {
                                              final product =
                                                  filteredProducts[index];
                                              return _buildProductCard(
                                                context,
                                                product,
                                                isDark,
                                              );
                                            },
                                          );
                                        },
                                        failure: (error, retry) => Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 40,
                                              horizontal: 20,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Text(
                                                  'حدث خطأ في تحميل المنتجات',
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: retry,
                                                  child: const Text(
                                                    'إعادة المحاولة',
                                                  ),
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
                        // Space at the bottom
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Floating Overlay Navigation Header (Back button and Cart badge on top)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Floating Back Button with frosted glass effect
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
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  widget.goPop(context);
                                } else {
                                  widget.goRoute(context, '/');
                                }
                              },
                            ),
                          ),
                        ),

                        // Floating Cart Badge with frosted glass effect
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
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductModel product,
    bool isDark,
  ) {
    return B2BProductCard(product: product, isDark: isDark);
  }
}
