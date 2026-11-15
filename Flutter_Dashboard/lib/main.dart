import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartSafetyApp());
}

class SmartSafetyApp extends StatelessWidget {
  const SmartSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Safety Device',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// =====================================================
// LOGIN PAGE
// =====================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      showMessage('Please enter email and password.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DashboardPage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';

      if (e.code == 'user-not-found') {
        message = 'No account found for this email.';
      } else if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }

      showMessage(message);
    } catch (e) {
      showMessage('Error: $e');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),

          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),

            child: Column(
              children: [

                const Icon(
                  Icons.health_and_safety,
                  size: 90,
                  color: Colors.blue,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Smart Safety Device',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Industrial Worker Safety Monitoring',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 52,

                  child: ElevatedButton(
                    onPressed: loading ? null : login,

                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// DASHBOARD
// =====================================================

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference sensorRef =
        FirebaseDatabase.instance.ref('sensorData');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Safety Device'),
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<DatabaseEvent>(
        stream: sensorRef.onValue,

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Database Error:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data?.snapshot.value;

          if (data == null) {
            return const Center(
              child: Text(
                'Waiting for sensor data...',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          final Map<dynamic, dynamic> sensorData =
              data as Map<dynamic, dynamic>;

          final double temperature =
              (sensorData['temperature'] ?? 0).toDouble();

          final double humidity =
              (sensorData['humidity'] ?? 0).toDouble();

          final int gas =
              (sensorData['gas'] ?? 0).toInt();

          final double accelX =
              (sensorData['accelX'] ?? 0).toDouble();

          final double accelY =
              (sensorData['accelY'] ?? 0).toDouble();

          final double accelZ =
              (sensorData['accelZ'] ?? 0).toDouble();

          final double accelMag =
              (sensorData['accelMag'] ?? 0).toDouble();

          final String status =
              sensorData['status']?.toString() ?? 'UNKNOWN';

          Color statusColor;

          if (status == 'DANGER') {
            statusColor = Colors.red;
          } else if (status == 'WARNING') {
            statusColor = Colors.orange;
          } else {
            statusColor = Colors.green;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              children: [

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Column(
                    children: [
                      const Text(
                        'CURRENT STATUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                sensorCard(
                  icon: Icons.thermostat,
                  title: 'Temperature',
                  value:
                      '${temperature.toStringAsFixed(1)} °C',
                ),

                sensorCard(
                  icon: Icons.water_drop,
                  title: 'Humidity',
                  value:
                      '${humidity.toStringAsFixed(1)} %',
                ),

                sensorCard(
                  icon: Icons.cloud,
                  title: 'Gas Level',
                  value: '$gas',
                ),

                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'Accelerometer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text(
                          'X: ${accelX.toStringAsFixed(2)} g',
                          style:
                              const TextStyle(fontSize: 17),
                        ),

                        Text(
                          'Y: ${accelY.toStringAsFixed(2)} g',
                          style:
                              const TextStyle(fontSize: 17),
                        ),

                        Text(
                          'Z: ${accelZ.toStringAsFixed(2)} g',
                          style:
                              const TextStyle(fontSize: 17),
                        ),

                        const Divider(),

                        Text(
                          'Magnitude: ${accelMag.toStringAsFixed(2)} g',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Live data from Smart Safety Device',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget sensorCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        leading: Icon(
          icon,
          size: 35,
          color: Colors.blue,
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}