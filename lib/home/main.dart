import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pasada_passenger_app/authenticationAccounts/createAccount.dart';
import 'package:pasada_passenger_app/authenticationAccounts/loginAccount.dart';
// import 'package:flutter/foundation.dart';
// import 'package:pasada_passenger_app/databaseSetup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://otbwhitwrmnfqgpmnjvf.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90YndoaXR3cm1uZnFncG1uanZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMzOTk5MzQsImV4cCI6MjA0ODk3NTkzNH0.f8JOv0YvKPQy8GWYGIdXfkIrKcqw0733QY36wJjG1Fw';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ensure initialization for async tasks
  await dotenv.load(fileName: ".env");

  // call the database tester before running the app

  // initialize supabase
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
      retryAttempts: 10,
    ),
  );

  runApp(const PasadaPassenger());
}

final supabase = Supabase.instance.client;
  
class PasadaPassenger extends StatelessWidget {
  const PasadaPassenger({super.key});

  // root of the application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const PasadaHomePage(title: 'Pasada'),
      routes: <String, WidgetBuilder>{
        'start': (BuildContext context) => const PasadaPassenger(),
        'createAccount': (BuildContext context) => const CreateAccountPage(),
        'loginAccount': (BuildContext context) => const LoginAccountPage(),
      },
    );
  }
}

// make the app run
class PasadaHomePage extends StatefulWidget {
  const PasadaHomePage({super.key, required this.title});

  final String title;

  @override
  State<PasadaHomePage> createState() => PasadaHomePageState();
}

// application content
class PasadaHomePageState extends State<PasadaHomePage> {
  @override
  Widget build(BuildContext context) {
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
          margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
          height: 130,
          width: 130,
          child: SvgPicture.asset('assets/svg/Ellipse.svg'),
        ),
        Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
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
              fontSize: 20
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
                fontSize: 20
            ),
          ),
        ),
      ),
    );
  }
}
