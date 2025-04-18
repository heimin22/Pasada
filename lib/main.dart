import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/authentication/createAccount.dart';
import 'package:pasada_passenger_app/authentication/createAccountCred.dart';
import 'package:pasada_passenger_app/authentication/loginAccount.dart';
import 'package:pasada_passenger_app/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/authentication/authGate.dart';
import 'package:pasada_passenger_app/utils/memory_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    // Cache the initial theme mode
    _memoryManager.addToCache('isDarkMode', _themeController.isDarkMode);
  }

  void _handleThemeChange() {
    // Throttle theme changes to prevent rapid toggles
    _memoryManager.throttle(() {
      setState(() {
        // Your theme change logic
      });
    }, const Duration(milliseconds: 300), 'theme_change');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeController,
      builder: (context, child) {
        return MaterialApp(
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
            'start': (BuildContext context) => const PasadaPassenger(),
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
class PasadaHomePageState extends State<PasadaHomePage> {
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
      // Force light background for this screen
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildHeader(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                buildCreateAccount(),
                buildLoginAccount(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
          height: 130,
          width: 130,
          child: SvgPicture.asset('assets/svg/Ellipse.svg'),
        ),
        Container(
          margin:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
          child: const Text(
            'Kumusta!',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Color(0xFF121212), // Force dark text
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.01,
          ),
          child: const Text(
            'Welcome sa Pasada!',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF121212), // Force dark text
            ),
          ),
        )
      ],
    );
  }

  Flexible buildCreateAccount() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.02,
          left: MediaQuery.of(context).size.height * 0.02,
          right: MediaQuery.of(context).size.height * 0.02,
        ),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, 'createAccount');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF121212),
            minimumSize: const Size(360, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text(
            'Create an Account',
            style: TextStyle(
              color: Color(0xFFF2F2F2),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  Flexible buildLoginAccount() {
    return Flexible(
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.02,
          left: MediaQuery.of(context).size.height * 0.02,
          right: MediaQuery.of(context).size.height * 0.02,
        ),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, 'loginAccount');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF2F2F2),
            minimumSize: const Size(360, 50),
            side: const BorderSide(
              color: Color(0xFF00CC58),
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text(
            'Log-in',
            style: TextStyle(
              color: Color(0xFF121212),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    MemoryManager().dispose();
    super.dispose();
  }
}
