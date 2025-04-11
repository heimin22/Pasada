import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/authentication/createAccount.dart';
import 'package:pasada_passenger_app/authentication/createAccountCred.dart';
import 'package:pasada_passenger_app/authentication/loginAccount.dart';
import 'package:pasada_passenger_app/profiles/theme_preferences.dart';
import 'package:pasada_passenger_app/screens/selectionScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pasada_passenger_app/authentication/authGate.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // ensure initialization for async tasks
  await dotenv.load(fileName: ".env");

  // initialize supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
    storageOptions: const StorageClientOptions(
      retryAttempts: 10,
    ),
  );

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
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    loadThemeMode();
  }

  Future<void> loadThemeMode() async {
    final darkMode = await ThemePreferences.getDarkModeStatus();
    setState(() => isDarkMode = darkMode);
  }

  // root of the application
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
    ));

    return MaterialApp(
      title: 'Pasada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor:
            isDarkMode ? const Color(0xFF121212) : Color(0xFFF5F5F5),
        fontFamily: 'Inter',
        useMaterial3: true,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        textTheme: TextTheme(
          bodyLarge: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212)),
          bodyMedium: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212)),
          bodySmall: TextStyle(
              color: isDarkMode
                  ? const Color(0xFFF5F5F5)
                  : const Color(0xFF121212)),
        ),
      ),
      // screens: const PasadaHomePage(title: 'Pasada'),
      home: const AuthGate(),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
        'createAccount': (BuildContext context) => const CreateAccountPage(),
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
          SnackBar(content: Text('Account created successfully!')),
        );
        ModalRoute.of(context)?.settings.arguments != null;
      }
    });
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              color: Color(0xFF121212),
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
              color: Color(0xFF121212),
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
                fontSize: 20),
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
                fontSize: 20),
          ),
        ),
      ),
    );
  }
}
