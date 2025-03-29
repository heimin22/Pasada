/*

Authentication gate - this will continuously listen for auth changes

unauthenticated - login page
authenticated - main page

*/

import 'package:flutter/material.dart';
import 'package:pasada_passenger_app/home/homeScreen.dart';
// import 'package:pasada_passenger_app/home/selectionScreen.dart';
import 'package:pasada_passenger_app/main.dart';
// import 'package:pasada_passenger_app/authenticationAccounts/loginAccount.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/selectionScreen.dart';
import '../location/mapScreen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate ({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,

      // build appropriate page based on auth state
      builder: (context, snapshot) {

        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // check if there is a valid session currently
        // final session = snapshot.hasData ? snapshot.data!.session : null;

        final session = snapshot.data?.session;

        return session != null
            ? const selectionScreen()
            : const PasadaHomePage(title: 'Pasada');
      },
    );
  }
}
