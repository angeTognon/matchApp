# ✅ Checklist : Installation du système de demandes de match

## 📋 Étapes à suivre

### 1. ⚠️ PRÉREQUIS IMPORTANT - Base de données

**Exécuter le script SQL pour ajouter la colonne `coach_id`**

Dans phpMyAdmin :
```sql
-- Ajouter la colonne coach_id
ALTER TABLE amicalclub_matches 
ADD COLUMN coach_id INT NOT NULL AFTER team_id;

-- Remplir avec les bonnes valeurs
UPDATE amicalclub_matches m
JOIN amicalclub_teams t ON m.team_id = t.id
SET m.coach_id = t.coach_id;

-- Ajouter la clé étrangère
ALTER TABLE amicalclub_matches 
ADD CONSTRAINT fk_matches_coach 
FOREIGN KEY (coach_id) REFERENCES amicalclub_users(id) ON DELETE CASCADE;

-- Ajouter l'index
ALTER TABLE amicalclub_matches 
ADD INDEX idx_coach (coach_id);
```

Ou utiliser le fichier : `backend/add_coach_id_to_matches.sql`

✅ **Vérification** : La colonne `coach_id` doit apparaître dans la table `amicalclub_matches`

---

### 2. 📂 Vérifier les fichiers Backend

✅ `backend/get_match_requests.php` - Créé
✅ `backend/respond_match_request.php` - Créé

**Ces fichiers doivent être accessibles via :**
- `http://votre-serveur/backend/get_match_requests.php`
- `http://votre-serveur/backend/respond_match_request.php`

---

### 3. 📱 Vérifier les fichiers Frontend

✅ `lib/models/match_request.dart` - Créé
✅ `lib/screens/match/match_requests_screen.dart` - Créé
✅ `lib/services/api_service.dart` - Modifié (2 nouvelles méthodes)
✅ `lib/screens/profile/profile_screen.dart` - Modifié (nouveau bouton)
✅ `lib/config/app_router.dart` - Modifié (nouvelle route)

---

### 4. 🔄 Recompiler l'application

```bash
# Dans le terminal
cd /Users/mac/Documents/amical_club
flutter clean
flutter pub get
flutter run
```

---

### 5. 🧪 Tests à effectuer

#### Test 1 : Vérifier le bouton dans le profil
- [ ] Ouvrir l'app
- [ ] Aller dans l'onglet "Profil"
- [ ] **Vérifier** : Bouton orange "Demandes de match" est visible
- [ ] Cliquer dessus
- [ ] **Vérifier** : Écran avec 2 onglets "Reçues" et "Envoyées" s'ouvre

#### Test 2 : Créer une demande
- [ ] Avec un compte A, créer un match
- [ ] Avec un compte B, trouver ce match
- [ ] Cliquer sur "Je suis intéressé"
- [ ] **Vérifier** : Message de succès
- [ ] **Pas d'erreur SQL** `Column not found: m.coach_id`

#### Test 3 : Voir les demandes reçues
- [ ] Avec le compte A (créateur du match)
- [ ] Aller dans Profil → "Demandes de match"
- [ ] Onglet "Reçues"
- [ ] **Vérifier** : La demande du compte B est visible
- [ ] **Vérifier** : Badge avec le nombre de demandes apparaît
- [ ] **Vérifier** : Infos complètes (équipe, date, lieu, message)

#### Test 4 : Accepter une demande
- [ ] Sur une demande en attente
- [ ] Cliquer sur "Accepter"
- [ ] **Vérifier** : Dialogue de confirmation s'affiche
- [ ] Confirmer
- [ ] **Vérifier** : Message de succès
- [ ] **Vérifier** : Statut change à "Acceptée"
- [ ] **Vérifier** : Badge disparaît (si c'était la dernière)

#### Test 5 : Voir les demandes envoyées
- [ ] Avec le compte B (qui a fait la demande)
- [ ] Aller dans Profil → "Demandes de match"
- [ ] Onglet "Envoyées"
- [ ] **Vérifier** : La demande est visible
- [ ] **Vérifier** : Statut "En attente" ou "Acceptée" selon l'action du compte A

#### Test 6 : Pull-to-refresh
- [ ] Dans l'écran des demandes
- [ ] Glisser vers le bas
- [ ] **Vérifier** : Indicateur de chargement
- [ ] **Vérifier** : Données se rafraîchissent

---

### 6. 🐛 Résolution de problèmes

#### Erreur : "Column not found: 1054 Unknown column 'm.coach_id'"
**Solution** : La colonne `coach_id` n'a pas été ajoutée à la base de données
→ Exécuter le script SQL de l'étape 1

#### Erreur : "Page non trouvée" en cliquant sur le bouton
**Solution** : La route n'a pas été ajoutée correctement
→ Vérifier `lib/config/app_router.dart` ligne 83-85

#### Erreur : "Cannot find constructor"
**Solution** : Problème d'import ou de syntaxe
→ Exécuter `flutter clean && flutter pub get`

#### Les demandes ne s'affichent pas
**Solutions possibles** :
1. Vérifier que les fichiers PHP sont accessibles
2. Vérifier les logs du backend PHP
3. Vérifier le token d'authentification
4. Vérifier qu'il y a bien des demandes dans la table `amicalclub_match_requests`

---

### 7. ✅ Checklist finale

Avant de considérer l'installation terminée :

- [ ] Script SQL exécuté sans erreur
- [ ] Colonne `coach_id` existe dans `amicalclub_matches`
- [ ] Tous les matchs ont un `coach_id` renseigné
- [ ] Backend accessible (tester avec Postman ou navigateur)
- [ ] Application recompilée
- [ ] Bouton visible dans le profil
- [ ] Écran s'ouvre sans erreur
- [ ] Peut créer une demande sans erreur SQL
- [ ] Demandes reçues s'affichent
- [ ] Demandes envoyées s'affichent
- [ ] Accepter/Refuser fonctionne
- [ ] Pull-to-refresh fonctionne
- [ ] Badge de notification s'affiche

---

## 🎯 Une fois tout validé

**Système opérationnel à 100% !** 🎉

Vous pouvez maintenant :
- Gérer toutes vos demandes de match
- Accepter/refuser des demandes
- Suivre l'état de vos demandes
- Avoir une vue d'ensemble complète

---

## 📚 Documentation

- **Guide complet** : `DEMANDES_MATCH_IMPLEMENTATION.md`
- **Récapitulatif rapide** : `RECAP_DEMANDES_MATCH.md`
- **Cette checklist** : `CHECKLIST_DEMANDES.md`
- **Fix coach_id** : `FIX_COACH_ID_ERROR.md`

---

## 🆘 Besoin d'aide ?

Si quelque chose ne fonctionne pas :
1. Vérifier cette checklist point par point
2. Consulter les logs d'erreur
3. Vérifier la documentation technique
4. Vérifier que le backend est accessible


