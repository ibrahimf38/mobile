# MaliMall — App mobile (Flutter)

Application mobile du parcours **Market** de MaliMall (catalogue, panier,
commande, livraison à deux codes, portefeuille MMC) — consomme le backend
Spring Boot du dossier `backend/` à côté de celui-ci.

Ce code a été écrit et relu attentivement (imports, noms de champs cohérents
avec les DTO du backend, gestion d'état, navigation), mais **n'a pas pu être
compilé ni exécuté dans l'environnement cloud où il a été rédigé** : ni
Flutter ni Dart SDK n'y sont installés, et le réseau y est bloqué pour les
télécharger (même situation que pour le backend au premier lot). Il doit donc
être compilé et testé une première fois sur votre machine, où Flutter est déjà
installé.

## Démarrer en local

Ce dossier contient uniquement le code Dart (`lib/`) et `pubspec.yaml` — les
dossiers `android/` et `ios/` générés par Flutter (config native, gradle,
Info.plist...) ne sont **pas** inclus, pour rester léger et parce qu'ils sont
générés automatiquement. Pour les créer :

```bash
cd mobile
flutter create . --project-name malimall --org com.malimall
```

Cette commande ne touche à aucun fichier de `lib/` ni à `pubspec.yaml` : elle
ajoute seulement les dossiers de plateforme manquants autour du code déjà
présent (elle demandera confirmation avant d'écraser quoi que ce soit —
répondez "oui" si elle propose de compléter `pubspec.yaml`, elle fusionne les
champs manquants sans supprimer les dépendances déjà listées).

Puis :

```bash
flutter pub get
flutter analyze      # doit être propre (0 erreur)
flutter run          # sur un émulateur/téléphone déjà configuré
```

## Logo & icône de l'app

Le logo (vectorisé à partir de votre capture d'écran) est dans
`assets/branding/` :

- `logo_full.svg` / `logo_full.png` — logo complet (icône + "MaliMall" +
  tagline), fond transparent.
- `logo_icon.svg` / `logo_icon.png` — icône seule, carrée, fond transparent.

Ces fichiers sont déclarés dans `pubspec.yaml` (`assets/branding/`), donc
utilisables n'importe où dans l'app avec
`Image.asset('assets/branding/logo_full.png')` si vous voulez l'afficher sur
un écran (Connexion/Inscription, à-propos, etc.) — je ne l'ai placé nulle
part dans l'UI moi-même pour l'instant, dites-moi si vous voulez que je
l'intègre à un écran précis.

**Icône de l'app** (celle affichée sous le nom de l'app sur le téléphone,
remplace l'icône Flutter par défaut) : déjà configurée dans `pubspec.yaml`
(section `flutter_launcher_icons`) à partir de deux fichiers désormais
présents dans `assets/icon/` (générés depuis le vrai logo
`assets/branding/logo_mark.png`) — `icon_ios.png` (fond blanc plein, pour
iOS/l'icône "legacy" Android) et `icon_adaptive_fg.png` (fond transparent,
logo réduit au centre pour respecter la "safe zone" des icônes adaptatives
Android, fond blanc défini séparément dans la config). Pour générer réellement
l'icône native, **après** avoir lancé `flutter create .` (étape
"Démarrer en local" ci-dessus, car ça crée les dossiers `android/`/`ios/`
que la commande modifie) :

```bash
flutter pub get
dart run flutter_launcher_icons
```

(Sur d'anciennes versions du package la commande est
`flutter pub run flutter_launcher_icons:main` — utilisez celle que
`flutter pub get` vous indique si `dart run flutter_launcher_icons` ne
fonctionne pas.) Cette commande écrit directement dans
`android/app/src/main/res/mipmap-*/` et `ios/Runner/Assets.xcassets/` — à
relancer si vous changez `logo_icon.png`. Comme pour tout le reste de ce
projet, je n'ai pas pu exécuter cette commande moi-même dans cet
environnement (pas de Flutter SDK ni d'accès réseau à pub.dev) : dites-moi
l'erreur exacte si `dart run flutter_launcher_icons` échoue.

## Adapter l'URL du backend

Une seule constante à changer selon où l'app tourne, dans
`lib/core/api/api_client.dart` (`ApiClient.baseUrl`) :

| Où tourne l'app | Valeur |
|---|---|
| Émulateur Android | `http://10.0.2.2:8080` (déjà la valeur par défaut) |
| Simulateur iOS | `http://localhost:8080` |
| Téléphone physique (USB/WiFi) | `http://<IP-locale-de-votre-PC>:8080` |

Le backend doit être démarré (`mvn spring-boot:run`, profil `local`,
PostgreSQL lancé) avant de lancer l'app.

## Photos (upload)

L'app utilise `image_picker` pour choisir une photo (produit, boutique,
profil) depuis la galerie, puis l'envoie au backend qui la retransmet à
Supabase Storage (voir `backend/README.md`, section "Photos (Supabase
Storage)" pour la configuration du bucket côté serveur).

**iOS uniquement** — après `flutter create .`, ajoutez ces deux clés dans
`ios/Runner/Info.plist` (sans elles, l'app plante dès qu'on essaie
d'ouvrir la galerie) :

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>MaliMall a besoin d'accéder à vos photos pour ajouter une image à votre produit, boutique ou profil.</string>
```

**Android** : aucune permission supplémentaire à déclarer — `image_picker`
utilise le sélecteur de photos système (API 21+), qui ne requiert pas
`READ_EXTERNAL_STORAGE`.

Tant que le backend n'a pas ses variables `SUPABASE_URL`/
`SUPABASE_SERVICE_KEY` définies, l'upload échoue avec un message d'erreur
explicite ("service de stockage non configuré") — le reste de l'app
fonctionne normalement.

## Onboarding (photos)

L'écran d'onboarding (3 slides plein cadre) utilise 3 images déclarées dans
`pubspec.yaml` (`assets/images/`) :

- `assets/images/onboarding_1.jpg` — Market
- `assets/images/onboarding_2.jpg` — Livraison
- `assets/images/onboarding_3.jpg` — Portefeuille

Les 3 fichiers livrés dans ce dossier sont des **placeholders** (fond bleu
uni + texte, générés automatiquement) pour que l'app compile et se lance
sans étape supplémentaire. **Remplacez-les par vos propres photos en gardant
exactement ces 3 noms de fichier** — aucune autre modification n'est
nécessaire, `onboarding_screen.dart` les référence déjà par leur nom
(`Image.asset(...)`, avec un repli sur un fond bleu uni si un fichier venait
à manquer, plutôt qu'un écran cassé).

## Publicité (bannière Market)

Un vendeur peut payer pour diffuser une bannière sur l'accueil Market
(Compte → Mes espaces → Publicité) : 20 MMC/jour, débité immédiatement à la
demande, diffusion activée après validation manuelle. Ce lot ne construit
**pas** d'interface admin dédiée dans l'app — la validation/le refus se
font via Swagger (`POST /api/admin/publicites/{id}/valider` ou `/refuser`),
cohérent avec le périmètre académique de ce lot ; dites-le-moi si vous
préférez un vrai écran admin dans l'app, ce serait un petit ajout.

## Parcours de bout en bout à tester

1. Onboarding → Créer un compte (acheteur par défaut).
2. Compte → Ma boutique → Devenir vendeur → se reconnecter → créer la
   boutique → ajouter un produit.
3. Se reconnecter avec un autre compte (ou revenir à l'acheteur) → Market →
   ajouter le produit au panier → valider la commande.
4. Compte → Espace livreur → Devenir chauffeur → se reconnecter → Livraisons
   disponibles → prendre en charge la commande → saisir le code de retrait
   (donné par le vendeur, visible sur son écran Détail commande → onglet
   Ventes).
5. Repasser sur le compte acheteur → Mes commandes → la commande affiche
   maintenant le code de livraison → Confirmer la réception.
6. Vérifier le Wallet des trois comptes (acheteur débité, vendeur et
   chauffeur crédités à 92 %, plateforme créditée de la commission).
7. Compte → Publicité → Nouvelle publicité (le solde vendeur doit baisser
   immédiatement) → valider via Swagger (`/api/admin/publicites`) → revenir
   sur l'accueil Market : la bannière doit apparaître.

## Écarts assumés avec les maquettes (voir le plan)

- Les écrans "scanner" (retrait, réception) sont une saisie numérique à 6
  chiffres, pas une caméra/QR code : le backend ne vérifie qu'une chaîne à 6
  chiffres, il n'y a aucune génération de QR code côté serveur.
- Le code de livraison n'est **jamais** montré au chauffeur (modèle de
  sécurité à deux codes du backend) : côté chauffeur, l'écran de suivi
  s'arrête à "en route", la confirmation finale de réception se fait
  uniquement depuis le compte de l'acheteur.
- L'écran de confirmation de commande n'affiche pas de code immédiatement
  (le backend ne le génère/révèle qu'une fois le colis récupéré chez le
  vendeur) — il renvoie vers le détail de la commande, où le code apparaît
  dès qu'il est réellement disponible.
- Les 3 boutons Wallet (Dépôt/Retrait/Envoyer) sont affichés pour respecter la
  charte visuelle mais annoncent "bientôt disponible" : le backend n'expose
  aucun endpoint de recharge/retrait pour un compte non-admin ce lot.
- Le module MotoTaxis affiche un écran "à venir" : aucune API MotoTaxis
  (Course, Avis) n'existe côté backend ce lot.
- La carte produit affiche un badge "🔥 X vendu(s)" uniquement quand
  `quantiteVendue > 0` — un vrai total calculé côté serveur (somme des
  lignes de commande), jamais un chiffre inventé. Le badge "❤ likes" de la
  maquette reste volontairement absent : aucun système de favoris n'existe
  dans ce lot.
- La bannière promo de l'accueil Market est alimentée par de vraies
  publicités (module Publicité, voir plus bas) — jamais un "-20 %" fabriqué.

## Fidélité à la maquette Figma

Un passage dédié a été fait sur les ~19 écrans pour se rapprocher au plus
près de la charte (la maquette Figma MaliMall) : bouton retour rond
34×34 (`AppHeaderBar`, remplace l'AppBar Material par défaut sur tous les
écrans empilés), couleurs de badges de statut, bandeau onboarding, chips
catégorie, suivi de livraison à 4 étapes sur le détail commande, avatar +
badge appareil-photo sur le hero du compte (pastille "Compte vérifié" et
date d'inscription réelles, jamais simulées). Deux écarts d'architecture
restent assumés (pas des oublis) : "Ma boutique" est un écran combiné
header+stats+liste plutôt qu'un hub à menu, et "Commandes" utilise un
écran de détail adaptatif par rôle plutôt que le flux de la maquette —
détaillé dans les commentaires du code concerné.

## Si `flutter analyze` ou `flutter run` échoue

Dites-moi l'erreur exacte et je corrige : n'ayant pas pu compiler ce code
moi-même dans cet environnement, il est probable qu'il reste une ou deux
erreurs de syntaxe, d'import ou de type que je n'ai pas vues à la relecture
manuelle.
