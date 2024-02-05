import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Hyperlink extends StatelessWidget {
  final String url;
  final String text;

  Hyperlink(this.url, this.text);

  Future<void> _launchURL() async {
    final Uri _url = Uri.parse(url);
    if (!await canLaunchUrl(_url)) {
      print('Could not launch $url');
      return;
    }
    try {
      await launchUrl(_url);
    } catch (e) {
      print('Failed to launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launchURL,
      child: Text(
        text,
        style: const TextStyle(
          decoration: TextDecoration.underline,
          color: Colors.blue,
        ),
      ),
    );
  }
}
