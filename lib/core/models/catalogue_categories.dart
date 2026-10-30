const Map<String, List<String>> sousCategoriesParBoutique = {
  'Mode': [
    'Vêtements',
    'Chaussures',
    'Sacs et accessoires',
    'Autres articles de mode'
  ],
  'Artisanat': ['Poterie', 'Tissage', 'Vannerie', 'Artisanat divers'],
  'Bijoux': [
    'Colliers',
    'Bracelets',
    'Bagues',
    'Boucles d’oreilles',
    'Bijoux divers'
  ],
  'Maison': [
    'Décoration',
    'Mobilier',
    'Cuisine',
    'Linge de maison',
    'Autres articles maison'
  ],
  'Beauté': ['Soins du visage', 'Soins du corps', 'Maquillage', 'Parfums'],
  'Électronique': [
    'Téléphones et tablettes',
    'Audio',
    'Informatique',
    'Accessoires électroniques',
    'Électroménager',
  ],
  'Alimentation': [
    'Céréales et légumineuses',
    'Huiles et condiments',
    'Boissons',
    'Produits frais',
    'Épicerie',
  ],
};

List<String> sousCategoriesPour(String? categorieBoutique) =>
    sousCategoriesParBoutique[categorieBoutique] ?? const [];
