# Backend Amical Club - Instructions d'installation

## Problème actuel
L'erreur `<!DOCTYPE html>` indique que le serveur retourne une page HTML au lieu de JSON. Cela signifie que les fichiers PHP ne sont pas accessibles à l'URL configurée.

## Solutions possibles

### Option 1: Serveur local (Recommandé pour le développement)
1. **Installer XAMPP ou WAMP** sur votre machine
2. **Copier les fichiers PHP** dans le dossier `htdocs` (XAMPP) ou `www` (WAMP)
3. **Démarrer Apache et MySQL**
4. **Modifier l'URL** dans `lib/constant.dart`:
   ```dart
   String baseUrl = "http://localhost/amicalclub/";
   ```

### Option 2: Serveur en ligne
1. **Uploader les fichiers PHP** sur votre serveur web
2. **Créer la base de données** en exécutant le script `database.sql`
3. **Modifier les paramètres** dans `db.php` si nécessaire
4. **Tester l'accès** via navigateur: `http://votre-serveur.com/amicalclub/test.php`

### Option 3: Utiliser un service de test
1. **Tester la connectivité** en allant sur `/test` dans l'app
2. **Vérifier les logs** dans la console Flutter
3. **Ajuster l'URL** selon les résultats

## Fichiers à uploader sur le serveur
- `db.php` - Configuration base de données
- `register.php` - Inscription
- `login.php` - Connexion
- `logout.php` - Déconnexion
- `verify_token.php` - Vérification token
- `test.php` - Test de connectivité

## Configuration base de données
1. Créer une base de données MySQL
2. Exécuter le script `database.sql`
3. Modifier les paramètres dans `db.php`:
   ```php
   $host = 'localhost';
   $db   = 'votre_base_de_donnees';
   $user = 'votre_utilisateur';
   $pass = 'votre_mot_de_passe';
   ```

## Test de fonctionnement
1. Accéder à `http://votre-serveur.com/amicalclub/test.php`
2. Vous devriez voir du JSON, pas du HTML
3. Tester l'inscription via l'app Flutter

## Dépannage
- **Erreur 404**: Fichier PHP non trouvé
- **Erreur 500**: Problème de configuration PHP/MySQL
- **HTML au lieu de JSON**: Fichier PHP non accessible ou erreur de syntaxe
- **CORS**: Ajouter les headers dans les fichiers PHP
