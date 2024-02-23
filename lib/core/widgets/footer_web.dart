import 'package:flutter/material.dart';
import 'package:docare/main.dart';
import 'package:docare/core/utils/hyperlink.dart';

import 'package:docare/core/utils/font_size.dart';

class MyFooter extends StatelessWidget {
  Widget _buildImage2() {
    if (ColorSettings.backgroundColor == Color.fromARGB(255, 28, 120, 205)) {
      return Image.asset(
        'assets/images/PFE_logo_bleu2.png',
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      );
    } else if (ColorSettings.backgroundColor ==
        Color.fromARGB(255, 43, 130, 119)) {
      return Image.asset(
        'assets/images/PFE_logo_vert2.png',
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      );
    } else {
      // Si aucune des conditions n'est vraie, vous pouvez retourner une image par défaut ou un widget vide
      return Image.asset(
        'assets/images/PFE_logo_violet2.png',
        width: 50,
        height: 50,
        fit: BoxFit.contain,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 14.0),
      color: ColorSettings.backgroundColor,
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
              child: _buildImage2(),
            ),
          ),
          const Expanded(
            child: Column(
              children: <Widget>[
                Text('À propos',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('DOCare', style: TextStyle(color: Colors.white)),
                Text('Derniers ajouts', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                const Text('Aide et service',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                // Directly use Hyperlink widget here
                Hyperlink('https://www.linkedin.com/in/grégoire-sauvage/','Contactez-nous'),
                Text('Suivez-nous sur les réseaux', style: TextStyle(color: Colors.white)),
                // Add more Hyperlink widgets or other text elements here as needed
              ],
            ),
          ),
        ],
      ),
    );
  }
}
