# Correction du conflit de routes

## 🐛 Problème identifié

L'erreur "ID d'équipe manquant" était causée par un **conflit de routes** dans le router.

### **Cause du problème :**
```
Route 1: /team/:id        (ligne 90)  → TeamProfileScreen
Route 2: /team/edit       (ligne 120) → EditTeamScreen
```

Quand vous cliquiez sur "Ajouter" et naviguiez vers `/team/edit`, le router interprétait "edit" comme un ID et appelait `TeamProfileScreen` au lieu de `EditTeamScreen`.

### **Logs de l'erreur :**
```
TeamProfileScreen _loadTeamData appelée avec teamId: edit
🔄 TeamProfileScreen: Chargement de l'équipe edit
TeamProfileScreen réponse API: {success: false, message: ID d'équipe manquant}
❌ TeamProfileScreen: Erreur API - ID d'équipe manquant
```

## ✅ Solution appliquée

### **Ordre des routes corrigé :**
```
Route 1: /team/edit       → EditTeamScreen (création)
Route 2: /team/edit/:id   → EditTeamScreen (édition)
Route 3: /team/:id        → TeamProfileScreen (profil)
```

### **Principe :**
Les routes **spécifiques** doivent être définies **AVANT** les routes **génériques** avec paramètres.

## 🎯 Résultat attendu

### **Navigation correcte :**
- ✅ `/team/edit` → `EditTeamScreen` (création d'équipe)
- ✅ `/team/edit/123` → `EditTeamScreen` (édition d'équipe)
- ✅ `/team/123` → `TeamProfileScreen` (profil d'équipe)

### **Logs attendus :**
```
EditTeamScreen initState: teamId = null, isEditing = false
✅ MODE CRÉATION - Aucun appel API, formulaire vide
EditTeamScreen build: teamId = null, isEditing = false, isLoading = false
```

## 🧪 Test à effectuer

### **1. Test de création d'équipe**
```
1. Aller dans le profil
2. Cliquer sur "Ajouter"
3. Vérifier que l'écran d'édition s'affiche
4. Vérifier la boîte verte "✅ MODE CRÉATION"
5. Vérifier que le formulaire est vide
```

### **2. Vérifier les logs**
Dans la console, vous devriez voir :
```
EditTeamScreen initState: teamId = null, isEditing = false
✅ MODE CRÉATION - Aucun appel API, formulaire vide
```

**Plus de logs `TeamProfileScreen` !**

## ✅ Problème résolu

Le conflit de routes est maintenant corrigé :
- ✅ Routes spécifiques avant routes génériques
- ✅ `/team/edit` appelle `EditTeamScreen`
- ✅ `/team/:id` appelle `TeamProfileScreen`
- ✅ Plus d'erreur "ID d'équipe manquant"

## 🎉 Testez maintenant !

Cliquez sur "Ajouter" dans le profil - l'écran d'édition d'équipe devrait s'afficher correctement avec la boîte verte "✅ MODE CRÉATION" ! 🎉
