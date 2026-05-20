import 'package:delta_mager_pro_client_app/screens/b2b/widgets/b2b_cart_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:delta_mager_pro_client_app/consts/constants/theme/app_colors.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/products_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/categories_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/offers_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/model/category.dart';
import 'package:delta_mager_pro_client_app/logic/model/offer.dart';
import 'package:delta_mager_pro_client_app/logic/model/product_model.dart';
import 'package:delta_mager_pro_client_app/logic/providers/cart_provider.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/widgets/b2b_product_card.dart';
import 'package:JoDija_tamplites/util/data_souce_bloc/feature_data_source_state.dart';
import 'package:JoDija_tamplites/tampletes/screens/routed_contral_panal/utiles/side_bar_navigation_router.dart';
import 'package:delta_mager_pro_client_app/consts/constants/values/routes.dart';
import 'package:delta_mager_pro_client_app/configs/app_shell_config.dart';

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
    final categoryId = queryMap?['categoryId'];
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
    final queryMap = widget.getPrams();
    return queryMap?['searchQuery'] ?? queryMap?['categoryId']; // Fallback in case of parameters
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final category = effectiveCategoryFilter;
      final query = effectiveSearchQuery;

      context.read<ProductsBloc>().loadPublicProducts(
        categoryId: category?.id,
        name: query,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final category = effectiveCategoryFilter;
    final query = effectiveSearchQuery;

    final title = category?.nameAr ?? 'المنتجات';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button and Category Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? DarkColors.primary : LightColors.primary)
                    .withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(
                      0.05,
                    ),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => widget.goPop(context),
                  ),
                  const SizedBox(width: 4),
                  if (category != null) ...[
                    Hero(
                      tag: 'category_${category.id}',
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              category.imageUrl != null &&
                                  category.imageUrl!.isNotEmpty
                              ? Image.network(
                                  category.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: isDark
                                      ? DarkColors.surface
                                      : Colors.white,
                                  child: Icon(
                                    Icons.category_outlined,
                                    color: isDark
                                        ? DarkColors.primary
                                        : LightColors.primary,
                                    size: 20,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (category != null &&
                            category.descriptionAr.isNotEmpty)
                          Text(
                            category.descriptionAr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  B2BCartBadge(organizationId: effectiveOrganizationId),
                ],
              ),
            ),
            Expanded(
              child:
                  BlocBuilder<
                    ProductsBloc,
                    FeaturDataSourceState<ProductModel>
                  >(
                    builder: (context, state) {
                      return state.listState.when(
                        init: () =>
                            const Center(child: CircularProgressIndicator()),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        success: (products) {
                          var filteredProducts = products ?? [];

                          if (category != null) {
                            filteredProducts = filteredProducts
                                .where((p) => p.categoryId == category.id)
                                .toList();
                          }

                          if (query != null && query.isNotEmpty) {
                            final q = query.toLowerCase();
                            filteredProducts = filteredProducts.where((p) {
                              return p.name.ar.toLowerCase().contains(q) ||
                                  p.name.en.toLowerCase().contains(q);
                            }).toList();
                          }

                          if (filteredProducts.isEmpty) {
                            return const Center(child: Text('لا توجد منتجات'));
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return _buildProductCard(
                                context,
                                product,
                                isDark,
                              );
                            },
                          );
                        },
                        failure: (error, retry) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('حدث خطأ في تحميل المنتجات'),
                              TextButton(
                                onPressed: retry,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
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
