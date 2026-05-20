import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:JoDija_tamplites/tampletes/screens/routed_contral_panal/utiles/side_bar_navigation_router.dart';
import 'package:delta_mager_pro_client_app/configs/b2b_home_config.dart';
import 'package:delta_mager_pro_client_app/consts/constants/views/assets.dart';
import 'package:delta_mager_pro_client_app/logic/mixins/system_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matger_pro_core_logic/core/auth/utils/permission_constants.dart'
    show SystemFeatures;
import 'package:provider/provider.dart';
import 'package:delta_mager_pro_client_app/consts/constants/theme/app_colors.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/categories_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/offers_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/model/category.dart';
import 'package:delta_mager_pro_client_app/logic/model/offer.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/products_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/model/product_model.dart';
import 'package:delta_mager_pro_client_app/logic/providers/cart_provider.dart';
import 'package:delta_mager_pro_client_app/screens/b2b/widgets/b2b_product_card.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/organization_config_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/auth_bloc.dart';
import 'package:JoDija_tamplites/util/data_souce_bloc/feature_data_source_state.dart';
import 'package:delta_mager_pro_client_app/consts/constants/values/routes.dart';
import 'package:delta_mager_pro_client_app/logic/providers/app_changes_values.dart';
import 'package:delta_mager_pro_client_app/consts/constants/values/strings.dart';
import 'package:delta_mager_pro_client_app/configs/app_shell_config.dart';
import 'b2b_products_screen.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

class B2BHomeScreen extends StatefulWidget with AppShellRouterMixin {
  B2BHomeScreen({super.key});

  @override
  State<B2BHomeScreen> createState() => _B2BHomeScreenState();
}

class _B2BHomeScreenState extends State<B2BHomeScreen> with SystemManager {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _offersKey = GlobalKey();
  List<ProductModel> _suggestions = [];
  bool _isSearching = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToOffers() {
    final context = _offersKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  String get organizationId {
    final params = (widget as dynamic).getPrams();
    final orgName = params?['orgName'];
    if (orgName != null && orgName != "" && orgName != ":orgName") {
      AppRoutes.activeOrgName = orgName;
      return orgName;
    }
    final user = context.read<AppChangesValues>().user;
    return user?.organizationId ?? AppShellConfigs.defaultOrgName ?? 'shop1';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _onOfferTap(OfferModel offer) {
    if (offer.targetType == OfferTargetType.product &&
        offer.targetId.isNotEmpty) {
      widget.goRoute(context, '/product-details/${offer.targetId}');
      return;
    }

    widget.goRoute(context, '${AppRoutes.products}?offerId=${offer.id}');
  }

  void _loadInitialData({bool forceRefresh = false}) {
    if (forceRefresh) {
      context.read<OrganizationConfigBloc>().organizationConfig = null;
    }
    context.read<OrganizationConfigBloc>().getOrganizationConfigByName(
      organizationId,
    );
    context.read<CategoriesBloc>().loadPublicCategories(
      forceRefresh: forceRefresh,
    );
    context.read<OffersBloc>().loadPublicOffers(forceRefresh: forceRefresh);
    context.read<ProductsBloc>().loadPublicProducts(forceRefresh: forceRefresh);
  }

  Future<void> _handleRefresh() async {
    _loadInitialData(forceRefresh: true);
    context.read<AuthBloc>().checkSavedUser(
      onUserFound: (_) {},
      onUserNotFound: () {},
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sys = getSystemConfig(
      context,
      feature: SystemFeatures.screenB2bHome,
      mainPath: widget.getMainPath(),
    );
    if (sys.authWidget != null) return sys.authWidget!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sections = B2bHomeConfig.sections;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final configBloc = context.watch<OrganizationConfigBloc>();
    final orgConfig = configBloc.state.itemState.maybeWhen(
      success: (data) => data,
      orElse: () => null,
    );
    final title = orgConfig?.layout?.appTitle ?? AppStrings.appName;
    final user = context.watch<AppChangesValues>().user;

    return Scaffold(
      body: Column(
        children: [
          // 🏆 Sticky Premium Header & Navigation
          _buildPremiumHeader(context, isDark),

          // 📦 Main Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(isDark),
                    ...sections
                        .map((sec) => _buildDynamicSection(sec, isDark))
                        .toList(),
                    const SizedBox(height: 40),

                    // 👣 Detailed Premium Footer
                    _buildPremiumFooter(context, isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSection(Map<String, dynamic> section, bool isDark) {
    if (section['isActive'] == false) return const SizedBox.shrink();

    final String type = section['type'];
    final String title = section['title'] ?? "";
    final String mode = section['displayMode'] ?? "grid";
    final Map<String, dynamic> config = Map<String, dynamic>.from(
      section['config'] ?? {},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        _buildSectionContent(type, mode, config, isDark),
      ],
    );
  }

  Widget _buildSectionContent(
    String type,
    String mode,
    Map<String, dynamic> config,
    bool isDark,
  ) {
    switch (type) {
      case B2bHomeConfig.typeOffers:
        return Container(
          key: _offersKey,
          child: _buildOffersSection(isDark, mode: mode),
        );
      case B2bHomeConfig.typeCategories:
        return _buildCategoriesSection(isDark, mode: mode);
      // 🃏 section مستقل بـ grid و card خاصة به
      case B2bHomeConfig.typeJokerProducts:
      case B2bHomeConfig.typeSuperJokerProducts:
        return _buildJokerSection(type, isDark, config: config);
      case B2bHomeConfig.typeNewProducts:
      case B2bHomeConfig.typeBestSellerProducts:
      case B2bHomeConfig.typeOnSaleProducts:
        return _buildFilteredProductsSection(
          type,
          isDark,
          mode: mode,
          config: config,
        );
      case B2bHomeConfig.typeCustomBanner:
        return _buildCustomBanner(config);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFilteredProductsSection(
    String type,
    bool isDark, {
    required String mode,
    required Map<String, dynamic> config,
  }) {
    return BlocBuilder<ProductsBloc, FeaturDataSourceState<ProductModel>>(
      builder: (context, state) {
        return state.listState.maybeWhen(
          success: (allProducts) {
            if (allProducts == null || allProducts.isEmpty)
              return const SizedBox.shrink();
            final products = allProducts.where((p) {
              switch (type) {
                case B2bHomeConfig.typeNewProducts:
                  return p.isNew;
                case B2bHomeConfig.typeBestSellerProducts:
                  return p.isBestSeller;
                case B2bHomeConfig.typeJokerProducts:
                  return p.isJoker;
                case B2bHomeConfig.typeSuperJokerProducts:
                  return p.isSuperJoker;
                case B2bHomeConfig.typeOnSaleProducts:
                  return p.isOnSale ||
                      (p.additionalData['isInsideOffer'] ?? false);
                default:
                  return true;
              }
            }).toList();

            if (products.isEmpty) return const SizedBox.shrink();

            if (mode == B2bHomeConfig.modeSlider ||
                mode == "slider" ||
                mode == "slide" ||
                mode == "zoom_slider") {
              return _buildZoomSlider(
                products,
                isDark,
                isJoker: type == B2bHomeConfig.typeJokerProducts,
              );
            }

            if (mode == B2bHomeConfig.modeHorizontalList) {
              return SizedBox(
                height: 330,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) => Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildProductCard(context, products[index], isDark),
                  ),
                ),
              );
            }

            int crossAxisCount = config['crossAxisCount'] ?? 4;
            // تحديث تلقائي للقيم القديمة (2) لتصبح (4) كما طلب المستخدم للأقسام القياسية
            if (crossAxisCount == 2 &&
                (type == B2bHomeConfig.typeNewProducts ||
                    type == B2bHomeConfig.typeBestSellerProducts ||
                    type == B2bHomeConfig.typeOnSaleProducts)) {
              crossAxisCount = 4;
            }
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: crossAxisCount >= 4
                    ? 1
                    : (crossAxisCount == 1 ? 1.0 : 0.75),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) =>
                  _buildProductCard(context, products[index], isDark),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }

  // 🃏 Section مستقل 100% للجوكر - BlocBuilder خاص + Grid خاص + JokerCard
  Widget _buildJokerSection(
    String type,
    bool isDark, {
    required Map<String, dynamic> config,
  }) {
    return BlocBuilder<ProductsBloc, FeaturDataSourceState<ProductModel>>(
      builder: (context, state) {
        return state.listState.maybeWhen(
          success: (allProducts) {
            if (allProducts == null || allProducts.isEmpty)
              return const SizedBox.shrink();

            final products = allProducts
                .where(
                  (p) => type == B2bHomeConfig.typeJokerProducts
                      ? p.isJoker
                      : p.isSuperJoker,
                )
                .toList();

            if (products.isEmpty) return const SizedBox.shrink();

            final bool isSuperJoker =
                type == B2bHomeConfig.typeSuperJokerProducts;
            // السوبر جوكر: افتراضي 1 (يمكن تغييره لـ 2 من الباك اند)
            // الجوكر: افتراضي 2 (يمكن تغييره لـ 3 من الباك اند)
            final int defaultCols = isSuperJoker ? 1 : 2;
            final int cols = config['crossAxisCount'] ?? defaultCols;
            // نسبة العرض للارتفاع: إذا كان عمود واحد نجعلها أعرض (1.2)، وإذا كانت أعمدة أكثر نجعلها أطول (0.8)
            final double ratio = cols == 1 ? 1.2 : 0.8;

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: ratio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) =>
                  _buildJokerCard(context, products[index]),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildZoomSlider(
    List<ProductModel> products,
    bool isDark, {
    bool isJoker = false,
  }) {
    return B2BZoomSlider(
      products: products,
      isDark: isDark,
      isJoker: isJoker,
      onAddToCart: (p) => context.read<CartProvider>().addItem(p),
    );
  }

  // 🃏 بطاقة خاصة بالجوكر - صورة تملأ البطاقة بالكامل مع تنقل للمنتج
  Widget _buildJokerCard(BuildContext context, ProductModel product) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.goRoute(
          context,
          '/product-details/${product.id}',
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: product.images.isNotEmpty
              ? Image.network(
                  product.mainImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
        ),
      ),
    );
  }

  Widget _buildOffersSection(bool isDark, {String mode = "slider"}) {
    return BlocBuilder<OffersBloc, FeaturDataSourceState<OfferModel>>(
      builder: (context, state) {
        return state.listState.maybeWhen(
          success: (offers) {
            if (offers == null || offers.isEmpty)
              return const SizedBox.shrink();

            if (mode == B2bHomeConfig.modeSlider ||
                mode == "slider" ||
                mode == "slide") {
              return B2BPromoSlider(
                offers: offers,
                isDark: isDark,
                onTap: _onOfferTap,
              );
            }

            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _onOfferTap(offer),
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? DarkColors.surface
                              : LightColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? DarkColors.primary
                                              : LightColors.primary)
                                          .withOpacity(0.05),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                ),
                                child:
                                    offer.imageUrl != null &&
                                        offer.imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                        child: Image.network(
                                          offer.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.local_offer),
                                        ),
                                      )
                                    : const Icon(Icons.local_offer),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                offer.name.ar,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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
    );
  }

  Widget _buildCategoriesSection(
    bool isDark, {
    String mode = "horizontal_list",
  }) {
    return BlocBuilder<CategoriesBloc, FeaturDataSourceState<CategoryModel>>(
      builder: (context, state) {
        return state.listState.maybeWhen(
          success: (categories) {
            if (categories == null || categories.isEmpty)
              return const SizedBox.shrink();
            return SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () =>
                          widget.goRoute(context, '/products/${category.id}'),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DarkColors.surface
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? Colors.black : Colors.grey)
                                        .withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withOpacity(0.05),
                                ),
                              ),
                              child: Hero(
                                tag: 'category_${category.id}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      // Background Color / Placeholder
                                      Positioned.fill(
                                        child: Container(
                                          color:
                                              (isDark
                                                      ? DarkColors.primary
                                                      : LightColors.primary)
                                                  .withOpacity(0.05),
                                        ),
                                      ),
                                      // Image
                                      Positioned.fill(
                                        child:
                                            category.imageUrl != null &&
                                                category.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                category.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _buildCategoryIconPlaceholder(
                                                      isDark,
                                                    ),
                                              )
                                            : _buildCategoryIconPlaceholder(
                                                isDark,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              category.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
    );
  }

  Widget _buildCategoryIconPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.category_outlined,
        color: (isDark ? DarkColors.primary : LightColors.primary).withOpacity(
          0.5,
        ),
        size: 30,
      ),
    );
  }

  Widget _buildCustomBanner(Map<String, dynamic> config) {
    final imageUrl = config['imageUrl'] ?? "";
    if (imageUrl.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return BlocBuilder<ProductsBloc, FeaturDataSourceState<ProductModel>>(
      builder: (context, state) {
        final allProducts = state.listState.maybeWhen(
          success: (products) => products ?? [],
          orElse: () => <ProductModel>[],
        );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark ? DarkColors.surface : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _suggestions = [];
                                _isSearching = false;
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final query = value.toLowerCase();
                      setState(() {
                        _isSearching = true;
                        _suggestions = allProducts
                            .where((p) {
                              return p.name.ar.toLowerCase().contains(query) ||
                                  p.name.en.toLowerCase().contains(query);
                            })
                            .take(5)
                            .toList();
                      });
                    } else {
                      setState(() {
                        _isSearching = false;
                        _suggestions = [];
                      });
                    }
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _isSearching = false;
                        _suggestions = [];
                      });
                      widget.goRoute(
                        context,
                        '${AppRoutes.products}?searchQuery=$value',
                      );
                    }
                  },
                ),
              ),
              if (_isSearching && _suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: isDark ? DarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                    itemBuilder: (context, index) {
                      final product = _suggestions[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: product.images.isNotEmpty
                              ? Image.network(
                                  product.mainImage,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        title: Text(
                          product.name.ar,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${product.price} ج.م',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? DarkColors.primary
                                : LightColors.primary,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _isSearching = false;
                            _suggestions = [];
                            _searchController.clear();
                          });
                          widget.goRoute(
                            context,
                            '/product-details/${product.id}',
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartAction(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CartScreen(organizationId: organizationId),
                ),
              ),
            ),
            if (cart.itemCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
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

  Widget _buildPremiumHeader(BuildContext context, bool isDark) {
    final user = context.watch<AppChangesValues>().user;
    final configBloc = context.watch<OrganizationConfigBloc>();
    final orgConfig = configBloc.state.itemState.maybeWhen(
      success: (data) => data,
      orElse: () => null,
    );
    final title = orgConfig?.layout?.appTitle ?? AppStrings.appName;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? DarkColors.surface.withOpacity(0.9)
            : Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        top: true,
        child: Row(
          children: [
            // Mobile Menu Hamburger Button (Dropdown Popup)
            if (isMobile)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.menu,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 24,
                  ),
                  tooltip: 'قائمة التنقل',
                  onSelected: (value) {
                    if (value == 'home') {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    } else if (value == 'products') {
                      widget.goRoute(context, AppRoutes.allProducts);
                    } else if (value == 'offers') {
                      _scrollToOffers();
                    } else if (value == 'contact') {
                      _scrollToBottom();
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'home',
                      child: Row(
                        children: [
                          Icon(Icons.home_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('الرئيسية'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'products',
                      child: Row(
                        children: [
                          Icon(Icons.grid_view_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('كل المنتجات'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'offers',
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('العروض الحصرية'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'contact',
                      child: Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('اتصل بنا'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Logo & Title
            GestureDetector(
              onTap: () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        AppAsset.logo,
                        width: isMobile ? 32 : 38,
                        height: isMobile ? 32 : 38,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.storefront, size: isMobile ? 32 : 38),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Navigation Links (Desktop only)
            if (!isMobile) ...[
              _buildNavLink(
                label: 'الرئيسية',
                onTap: () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                isDark: isDark,
              ),
              const SizedBox(width: 20),
              _buildNavLink(
                label: 'كل المنتجات',
                onTap: () => widget.goRoute(context, AppRoutes.allProducts),
                isDark: isDark,
              ),
              const SizedBox(width: 20),
              _buildNavLink(
                label: 'العروض الحصرية',
                onTap: _scrollToOffers,
                isDark: isDark,
              ),
              const SizedBox(width: 20),
              _buildNavLink(
                label: 'اتصل بنا',
                onTap: _scrollToBottom,
                isDark: isDark,
              ),
              const Spacer(),
            ],

            // Actions: Cart, Search, User profile
            _buildCartAction(context),
            const SizedBox(width: 12),

            // User Profile or Login button
            if (user != null)
              PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark
                      ? DarkColors.primary.withOpacity(0.15)
                      : LightColors.primary.withOpacity(0.15),
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: isDark ? DarkColors.primary : LightColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    context.read<AuthBloc>().signOut();
                    setState(() {});
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20),
                        const SizedBox(width: 10),
                        Text(user.name),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_outlined,
                          size: 20,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'تسجيل الخروج',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  widget.goRoute(context, AppRoutes.logIn);
                },
                icon: const Icon(Icons.login_outlined, size: 14),
                label: const Text('دخول'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? DarkColors.primary
                      : LightColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFooter(BuildContext context, bool isDark) {
    final currentYear = DateTime.now().year;
    final configBloc = context.watch<OrganizationConfigBloc>();
    final orgConfig = configBloc.state.itemState.maybeWhen(
      success: (data) => data,
      orElse: () => null,
    );
    final title = orgConfig?.layout?.appTitle ?? AppStrings.appName;

    final primaryColor = isDark ? DarkColors.primary : LightColors.primary;
    final footerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final footerText = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final headingColor = isDark ? Colors.white : Colors.black87;

    return Container(
      color: footerBg,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Column 1: Store Bio
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            AppAsset.logo,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.storefront),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: headingColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'أهلاً بك في متجرنا الرقمي المميز. نسعى لتقديم أفضل المنتجات وأعلى جودة من الخدمات لعملائنا في كل مكان.',
                      style: TextStyle(
                        color: footerText,
                        height: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildSocialIcon(Icons.facebook_outlined, primaryColor),
                        const SizedBox(width: 10),
                        _buildSocialIcon(
                          Icons.alternate_email_outlined,
                          primaryColor,
                        ),
                        const SizedBox(width: 10),
                        _buildSocialIcon(Icons.wechat_outlined, primaryColor),
                      ],
                    ),
                  ],
                ),
              ),

              // Column 2: Quick Links
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'روابط سريعة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('الرئيسية', () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    }, footerText),
                    _buildFooterLink('منتجاتنا', () {
                      widget.goRoute(context, AppRoutes.allProducts);
                    }, footerText),
                    _buildFooterLink(
                      'عروضنا الحصرية',
                      _scrollToOffers,
                      footerText,
                    ),
                    _buildFooterLink('شروط الاستخدام والخصوصية', () {
                      // Navigate to privacy policy page
                    }, footerText),
                  ],
                ),
              ),

              // Column 3: Contact Info
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اتصل بنا',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterContactItem(
                      Icons.mail_outline,
                      'support@delta.com',
                      footerText,
                    ),
                    _buildFooterContactItem(
                      Icons.phone_android_outlined,
                      '+20 100 200 300',
                      footerText,
                    ),
                    _buildFooterContactItem(
                      Icons.location_on_outlined,
                      'القاهرة، جمهورية مصر العربية',
                      footerText,
                    ),
                  ],
                ),
              ),

              // Column 4: Secure Delivery & Service Policy
              SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدفع والتوصيل الآمن',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ندعم الدفع النقدي عند الاستلام (كاش) لضمان أعلى مستويات الأمان والموثوقية، مع شحن سريع وموثوق لكافة المحافظات.',
                      style: TextStyle(
                        color: footerText,
                        height: 1.4,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPaymentBadge('الدفع عند الاستلام', primaryColor),
                        _buildPaymentBadge('شحن سريع للمحافظات', primaryColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© $currentYear جميع الحقوق محفوظة لـ $title.',
                style: TextStyle(color: footerText, fontSize: 11),
              ),
              Text(
                'صنع بكل حب بواسطة zeftawyapps',
                style: TextStyle(color: footerText, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildFooterLink(String text, VoidCallback onTap, Color textColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterContactItem(IconData icon, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class B2BPromoSlider extends StatefulWidget {
  final List<OfferModel> offers;
  final bool isDark;
  final Function(OfferModel) onTap;

  const B2BPromoSlider({
    super.key,
    required this.offers,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<B2BPromoSlider> createState() => _B2BPromoSliderState();
}

class _B2BPromoSliderState extends State<B2BPromoSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % widget.offers.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.offers.length,
            itemBuilder: (context, index) {
              final offer = widget.offers[index];
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onTap(offer),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          offer.imageUrl != null && offer.imageUrl!.isNotEmpty
                              ? Image.network(
                                  offer.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: widget.isDark
                                      ? DarkColors.surface
                                      : Colors.grey[200],
                                  child: const Icon(
                                    Icons.local_offer,
                                    size: 50,
                                  ),
                                ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Text(
                              offer.name.ar,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.offers.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? (widget.isDark ? DarkColors.primary : LightColors.primary)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class B2BZoomSlider extends StatefulWidget {
  final List<ProductModel> products;
  final bool isDark;
  final bool isJoker;
  final Function(ProductModel) onAddToCart;

  const B2BZoomSlider({
    super.key,
    required this.products,
    required this.isDark,
    this.isJoker = false,
    required this.onAddToCart,
  });

  @override
  State<B2BZoomSlider> createState() => _B2BZoomSliderState();
}

class _B2BZoomSliderState extends State<B2BZoomSlider> {
  late PageController _controller;
  double _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.7, initialPage: 0);
    _controller.addListener(() {
      setState(() {
        _currentPage = _controller.page ?? 0;
      });
    });
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_controller.hasClients && widget.products.isNotEmpty) {
        int nextPage = (_currentPage.round() + 1) % widget.products.length;
        _controller.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.products.length,
        itemBuilder: (context, index) {
          double relativePosition = index - _currentPage;
          double scale = (1 - (relativePosition.abs() * 0.2)).clamp(0.8, 1.0);
          double opacity = (1 - (relativePosition.abs() * 0.3)).clamp(0.5, 1.0);

          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: widget.isJoker
                  ? _buildJokerSlide(widget.products[index])
                  : _buildZoomCard(widget.products[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJokerSlide(ProductModel product) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/product-details/${product.id}'),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: product.images.isNotEmpty
                ? Image.network(
                    product.mainImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDark ? DarkColors.surface : LightColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color:
                    (widget.isDark ? DarkColors.primary : LightColors.primary)
                        .withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: product.images.isNotEmpty
                    ? Image.network(product.mainImage, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 50),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name.ar,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${product.price} ج.م',
                    style: TextStyle(
                      color: widget.isDark
                          ? DarkColors.primary
                          : LightColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


}
