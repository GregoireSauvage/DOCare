import 'package:flutter/material.dart';
import 'package:docare/main.dart';

class MyFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 14.0),
      color: Colors.blue,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Adjusts child spacing
        children: <Widget>[
          Padding(
            padding:
                const EdgeInsets.only(right: 20.0), // Adjusts child spacing
            child: InkWell(
                  // InkWell pour rendre l'image cliquable
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const MyApp()), // Retour à la page d'accueil
                    );
                  },
                  child: Image.asset(
                    'assets/images/docare_logo.png',
                    width: 50,
                    height: 50,
                  ),
                ),
            
          ),
          const Expanded(
            child: Column(
              children: <Widget>[
                Text('À propos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('DOCare', style: TextStyle(color: Colors.white)),
                Text('Derniers ajouts', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const Expanded(
            child: Column(
              children: <Widget>[
                Text('Aide et service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Contactez-nous', style: TextStyle(color: Colors.white)),
                Text('Suivez-nous sur les réseaux', style: TextStyle(color: Colors.white)),
                // Add links or other text elements here
              ],
            ),
          ),
        ],
      ),
    );
  }
}
