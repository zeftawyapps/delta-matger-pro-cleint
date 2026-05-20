import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:JoDija_tamplites/tampletes/screens/routed_contral_panal/utiles/side_bar_navigation_router.dart';
import 'package:delta_mager_pro_client_app/consts/constants/values/routes.dart';
import 'package:delta_mager_pro_client_app/consts/constants/theme/app_colors.dart';
import 'package:delta_mager_pro_client_app/consts/constants/views/assets.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/organization_config_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/bloc/system_bloc.dart';
import 'package:delta_mager_pro_client_app/logic/providers/app_changes_values.dart';
import 'package:delta_mager_pro_client_app/consts/constants/values/strings.dart';
import 'package:delta_mager_pro_client_app/logic/model/organization_config_model.dart';
import 'package:delta_mager_pro_client_app/logic/model/system_models.dart';
import 'package:JoDija_tamplites/util/data_souce_bloc/feature_data_source_state.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget with AppShellRouterMixin {
  SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final systemBloc = context.read<SystemBloc>();
    final configBloc = context.read<OrganizationConfigBloc>();

    bool canLoadSystem = true;
    systemBloc.state.itemState.maybeWhen(
      loading: () => canLoadSystem = false,
      success: (_) => canLoadSystem = false,
      failure: (_, __) => canLoadSystem = false,
      orElse: () {},
    );

    if (canLoadSystem) {
      systemBloc.loadSystemInfo();
    }

    bool canLoadConfig = true;
    configBloc.state.itemState.maybeWhen(
      loading: () => canLoadConfig = false,
      success: (_) => canLoadConfig = false,
      failure: (_, __) => canLoadConfig = false,
      orElse: () {},
    );

    if (canLoadConfig) {
      configBloc.getOrganizationConfigByName(AppRoutes.activeOrgName);
    }

    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (!mounted) return;

    final systemState = context.read<SystemBloc>().state.itemState;
    final configState = context.read<OrganizationConfigBloc>().state.itemState;

    bool systemSuccess = false;
    bool configSuccess = false;

    systemState.maybeWhen(
      success: (_) => systemSuccess = true,
      orElse: () {},
    );

    configState.maybeWhen(
      success: (_) => configSuccess = true,
      orElse: () {},
    );

    if (systemSuccess && configSuccess && !_isNavigating) {
      _isNavigating = true;
      
      // Delay slightly before initiating the exit animation sequence
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isExiting = true;
          });
          // Wait for the exit animation duration (700ms) to complete before routing
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) {
              _proceedToNextScreen();
            }
          });
        }
      });
    }
  }

  void _proceedToNextScreen() {
    final appConfig = context.read<AppChangesValues>();
    final savedRoute = appConfig.savedTargetRoute;

    if (savedRoute != null && savedRoute.isNotEmpty) {
      debugPrint("Restoring saved deep link route via context.go: $savedRoute");
      appConfig.clearTargetRoute(); // Clear after reading to prevent loops
      context.go(savedRoute);
    } else {
      debugPrint("No saved target route. Navigating to standard B2B Home via context.go.");
      context.go(AppRoutes.b2bHome);
    }
  }

  void _updateTheme(OrganizationConfigModel config) {
    if (config.themes == null) return;
    final themes = config.themes!;
    final Map<String, Color> lightColors = {};
    final Map<String, Color> darkColors = {};

    if (themes.light != null) {
      final l = themes.light!;
      if (l.primary != null) {
        lightColors['primary'] = ColorUtils.fromHex(l.primary, LightColors.primary);
      }
      if (l.secondary != null) {
        lightColors['secondary'] = ColorUtils.fromHex(l.secondary, LightColors.secondary);
      }
    }

    if (themes.dark != null) {
      final d = themes.dark!;
      if (d.primary != null) {
        darkColors['primary'] = ColorUtils.fromHex(d.primary, DarkColors.primary);
      }
      if (d.secondary != null) {
        darkColors['secondary'] = ColorUtils.fromHex(d.secondary, DarkColors.secondary);
      }
    }

    AppColors.setDynamicColors(light: lightColors, dark: darkColors);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SystemBloc, FeaturDataSourceState<SystemInfoModel>>(
          listener: (context, state) {
            state.itemState.maybeWhen(
              success: (_) => _checkAndNavigate(),
              orElse: () {},
            );
          },
        ),
        BlocListener<OrganizationConfigBloc, FeaturDataSourceState<OrganizationConfigModel>>(
          listener: (context, state) {
            state.itemState.maybeWhen(
              success: (config) {
                if (config != null) _updateTheme(config);
                _checkAndNavigate();
              },
              orElse: () {},
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95), // بيضاء شفافة تظل ثابتة عند التحويل
          ),
          child: BlocBuilder<SystemBloc, FeaturDataSourceState<SystemInfoModel>>(
            builder: (context, systemState) {
              return BlocBuilder<OrganizationConfigBloc, FeaturDataSourceState<OrganizationConfigModel>>(
                builder: (context, configState) {
                  String? errorMessage;
                  VoidCallback? onRetry;

                  systemState.itemState.maybeWhen(
                    failure: (error, retry) {
                      errorMessage = error.message;
                      onRetry = retry;
                    },
                    orElse: () {},
                  );

                  if (errorMessage == null) {
                    configState.itemState.maybeWhen(
                      failure: (error, retry) {
                        errorMessage = error.message;
                        onRetry = retry;
                      },
                      orElse: () {},
                    );
                  }

                  if (errorMessage != null) {
                    return _buildErrorUI(errorMessage!, onRetry);
                  }

                  return _buildSplashUI();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSplashUI() {
    final systemInfo = context.read<SystemBloc>().systemInfo;
    final logoUrl = systemInfo?.logo;
    final primaryColor = AppColors.primary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. الأيقونة / الشعار مع تأثير التلاشي وتصغير الحجم (Scale) تدريجياً عند الخروج
          AnimatedOpacity(
            opacity: _isExiting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            child: AnimatedScale(
              scale: _isExiting ? 0.8 : 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      width: 130,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(AppAsset.logo, width: 130),
                    )
                  : Image.asset(AppAsset.logo, width: 130),
            ),
          ),
          const SizedBox(height: 24),
          // 2. اسم المنظومة والنص التوضيحي مع تأثير التلاشي والانزلاق للأسفل (Slide down)
          AnimatedOpacity(
            opacity: _isExiting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
            child: AnimatedSlide(
              offset: _isExiting ? const Offset(0, 0.15) : Offset.zero,
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeInOutCubic,
              child: Column(
                children: [
                  Text(
                    systemInfo?.appName ?? AppStrings.appName,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "جاري تهيئة المتجر والخدمات...",
                    style: TextStyle(
                      color: primaryColor.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          // 3. شريط مؤشر التقدم مع التلاشي السلس
          AnimatedOpacity(
            opacity: _isExiting ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            child: SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: LinearProgressIndicator(
                  color: primaryColor,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  minHeight: 6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI(String message, VoidCallback? onRetry) {
    final primaryColor = AppColors.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: primaryColor,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "حدث خطأ أثناء تحميل إعدادات المتجر",
              style: TextStyle(
                color: primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryColor.withValues(alpha: 0.7),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  "إعادة المحاولة",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
