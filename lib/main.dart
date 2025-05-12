import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pasada_passenger_app/authentication/createAccount.dart';
import 'package:pasada_passenger_app/authentication/createAccountCred.dart';
import 'package:pasada_passenger_app/authentication/loginAccount.dart';
import 'package:pasada_passenger_app/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/authentication/authGate.dart';
import 'package:pasada_passenger_app/utils/memory_manager.dart';
import 'package:pasada_passenger_app/services/notificationService.dart';
import 'package:pasada_passenger_app/services/backendConnectionTest.dart';
import 'package:pasada_passenger_app/screens/introductionScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize MemoryManager singleton
  final memoryManager = MemoryManager();

  // Add error handling for env file
  try {
    await dotenv.load(fileName: ".env");
    // Cache env variables for faster access
    memoryManager.addToCache('SUPABASE_URL', dotenv.env['SUPABASE_URL']);
    memoryManager.addToCache(
        'SUPABASE_ANON_KEY', dotenv.env['SUPABASE_ANON_KEY']);
  } catch (e) {
    debugPrint("Failed to load environment variables: $e");
    return;
  }

  // Use cached values
  final supabaseUrl = memoryManager.getFromCache('SUPABASE_URL');
  final supabaseKey = memoryManager.getFromCache('SUPABASE_ANON_KEY');

  if (supabaseUrl == null || supabaseKey == null) {
    debugPrint("Missing required Supabase configuration");
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 3, // Reduced from 10 for security
      ),
    );
  } catch (e) {
    debugPrint("Failed to initialize Supabase: $e");
    return;
  }

  // Test backend connection
  if (kDebugMode) {
    final tester = BackendConnectionTest();
    await tester.runAllTests();
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
    statusBarBrightness: Brightness.light, // For iOS light mode
  ));

  runApp(const PasadaPassenger());
}

final supabase = Supabase.instance.client;

class PasadaPassenger extends StatefulWidget {
  const PasadaPassenger({super.key});

  @override
  State<PasadaPassenger> createState() => _PasadaPassengerState();
}

class _PasadaPassengerState extends State<PasadaPassenger> {
  final ThemeController _themeController = ThemeController();
  final MemoryManager _memoryManager = MemoryManager();

  @override
  void initState() {
    super.initState();
    _themeController.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.showAvailabilityNotification();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _memoryManager.addToCache('isDarkMode', _themeController.isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Pasada',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: _themeController.isDarkMode
                ? const Color(0xFF121212)
                : const Color(0xFFF5F5F5),
            fontFamily: 'Inter',
            useMaterial3: true,
            brightness: _themeController.isDarkMode
                ? Brightness.dark
                : Brightness.light,
            textTheme: TextTheme(
              bodyLarge: TextStyle(
                  color: _themeController.isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212)),
              bodyMedium: TextStyle(
                  color: _themeController.isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212)),
              bodySmall: TextStyle(
                  color: _themeController.isDarkMode
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF121212)),
            ),
          ),
          // screens: const PasadaHomePage(title: 'Pasada'),
          home: const AuthGate(),
          routes: <String, WidgetBuilder>{
            'introduction': (BuildContext context) =>
                const IntroductionScreen(),
            'createAccount': (BuildContext context) =>
                const CreateAccountPage(),
            'cred': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return CreateAccountCredPage(
                title: 'Create Account',
                email: args['email'],
              );
            },
            'loginAccount': (BuildContext context) => const LoginAccountPage(),
          },
        );
      },
    );
  }
}

// make the app run
class PasadaHomePage extends StatefulWidget {
  const PasadaHomePage({super.key});

  @override
  State<PasadaHomePage> createState() => PasadaHomePageState();
}

// application content
class PasadaHomePageState extends State<PasadaHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args?['accountCreated'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        ModalRoute.of(context)?.settings.arguments != null;
      }
    });
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: _getTimeBasedGradient(),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildPage(
                      title: _getTimeBasedGreeting(),
                      subtitle: 'Welcome sa Pasada!',
                      content: 'Swipe to learn more about our app',
                      icon: _getTimeBasedIcon(),
                    ),
                    _buildPage(
                      title: 'Easy Booking',
                      subtitle: 'Book your ride in seconds',
                      content:
                          'Select your route, set your preferences, and you\'re ready to go!',
                      icon: Icons.book,
                    ),
                    _buildPage(
                      title: 'Get Started',
                      subtitle: 'Create an account or log in',
                      content:
                          'Join our community of passengers for a better commuting experience',
                      icon: Icons.person,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _totalPages,
                        (index) => _buildDotIndicator(index),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Navigation buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back button (hidden on first page)
                          _currentPage > 0
                              ? IconButton(
                                  icon: const Icon(Icons.arrow_back_ios,
                                      color: Colors.white),
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                )
                              : const SizedBox(width: 48),

                          // Next button or Get Started button with fade animation
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                            child: _currentPage < _totalPages - 1
                                ? IconButton(
                                    key: const ValueKey('next_button'),
                                    icon: const Icon(Icons.arrow_forward_ios,
                                        color: Colors.white),
                                    onPressed: () {
                                      _pageController.nextPage(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  )
                                : ElevatedButton(
                                    key: const ValueKey('get_started_button'),
                                    onPressed: () async {
                                      // Save that user has seen onboarding
                                      final prefs =
                                          await SharedPreferences.getInstance();
                                      await prefs.setBool(
                                          'hasSeenOnboarding', true);

                                      if (mounted) {
                                        Navigator.pushNamed(
                                            context, 'introduction');
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFF5F5F5),
                                      foregroundColor: const Color(0xFF00CC58),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 3,
                                    ),
                                    child: const Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Set status bar to white icons
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // White icons
      statusBarBrightness: Brightness.dark, // Dark background (for iOS)
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    MemoryManager().dispose();
    super.dispose();
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Magandang Umaga!';
    } else if (hour >= 12 && hour < 18) {
      return 'Magandang Hapon!';
    } else if (hour >= 18 && hour < 22) {
      return 'Magandang Gabi!';
    } else {
      return 'Magandang Gabi!';
    }
  }

  LinearGradient _getTimeBasedGradient() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      // Morning
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF236078), Color(0xFF439464)],
        transform: GradientRotation(21 * 3.14159 / 180),
      );
    } else if (hour >= 12 && hour < 18) {
      // Afternoon
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFCFA425), Color(0xFF26AB37)],
        transform: GradientRotation(21 * 3.14159 / 180),
      );
    } else if (hour >= 18 && hour < 22) {
      // Evening
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFB45F4F), Color(0xFF705776)],
        transform: GradientRotation(21 * 3.14159 / 180),
      );
    } else {
      // Night
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E3B4E), Color(0xFF1C1F2E)],
        transform: GradientRotation(21 * 3.14159 / 180),
      );
    }
  }

  IconData _getTimeBasedIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return Icons.wb_sunny_rounded; // Morning sun
    } else if (hour >= 12 && hour < 18) {
      return Icons.wb_twilight_rounded; // Afternoon
    } else {
      return Icons.nightlight_round; // Evening and night
    }
  }

  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Color(0xFFF5F5F5) : Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required String content,
    IconData? icon,
  }) {
    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 80,
                    color: const Color(0xFFF5F5F5),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5F5F5),
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Color(0xFFF5F5F5),
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFFF5F5F5),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
