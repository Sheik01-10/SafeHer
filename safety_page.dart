import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:telephony/telephony.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class SafetyPage extends StatefulWidget {
  @override
  _SafetyPageState createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  Position? currentPosition;
  StreamSubscription<Position>? positionStream;
  final Telephony telephony = Telephony.instance;

  // User Inputs
  final TextEditingController driverNameCtrl = TextEditingController();
  final TextEditingController cabNumberCtrl = TextEditingController();
  final TextEditingController familyNumberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startLiveLocation();
    _requestSmsPermission();
  }

  void _requestSmsPermission() async {
    await telephony.requestSmsPermissions;
  }

  // Live Location
  void _startLiveLocation() {
    LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    positionStream = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position pos) {
      setState(() {
        currentPosition = pos;
      });
    });
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  // WhatsApp
  Future<void> _shareOnWhatsApp() async {
    if (currentPosition == null) return;

    final lat = currentPosition!.latitude;
    final lon = currentPosition!.longitude;
    final driver = driverNameCtrl.text;
    final cab = cabNumberCtrl.text;
    final familyNo = familyNumberCtrl.text;

    final msg =
        "🚖 Cab Details:\nDriver: $driver\nCab No: $cab\nMy Location: https://maps.google.com/?q=$lat,$lon";

    final whatsappUrl = "whatsapp://send?phone=$familyNo&text=$msg";

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    }
  }

  // SMS
  void _sendSMS() async {
    if (currentPosition == null) return;

    final lat = currentPosition!.latitude;
    final lon = currentPosition!.longitude;
    final driver = driverNameCtrl.text;
    final cab = cabNumberCtrl.text;
    final familyNo = familyNumberCtrl.text;

    final msg =
        "🚨 Emergency Alert!\nDriver: $driver\nCab No: $cab\nLocation: https://maps.google.com/?q=$lat,$lon";

    await telephony.sendSms(to: familyNo, message: msg);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("📩 SMS Sent to Family")),
    );
  }

  // SOS
  Future<void> _sosEmergency() async {
    _sendSMS();
    const policeNumber = "100";
    final callUri = Uri(scheme: "tel", path: policeNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text("SafeHer - Travel Safety"),
        centerTitle: true,
        elevation: 5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Cab Details Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text("🚖 Enter Cab Details",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    TextField(
                      controller: driverNameCtrl,
                      decoration: InputDecoration(
                        labelText: "Driver Name",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: cabNumberCtrl,
                      decoration: InputDecoration(
                        labelText: "Cab Number",
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: familyNumberCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Family Number",
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // 🔹 Location Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text("📍 Live Location",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    currentPosition == null
                        ? Text("Fetching GPS location...",
                            style: TextStyle(color: Colors.grey))
                        : Text(
                            "Latitude: ${currentPosition!.latitude}\nLongitude: ${currentPosition!.longitude}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 25),

            // 🔹 Buttons
            ElevatedButton.icon(
              onPressed: _shareOnWhatsApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
              label: Text("Share on WhatsApp",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _sendSMS,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.sms, color: Colors.white),
              label: Text("Send SMS to Family",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 30),

            // 🔹 SOS Emergency
            ElevatedButton.icon(
              onPressed: _sosEmergency,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              icon: Icon(Icons.sos, color: Colors.white, size: 28),
              label: Text("🚨 SOS Emergency",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
