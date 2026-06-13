# BloodConnect

Plateforme mobile intelligente de gestion des dons de sang connectant les donneurs aux centres de transfusion sanguine.

---

## Stack technique

| Couche | Technologie |
|---|---|
| Mobile | Flutter 3.x · flutter_bloc · go_router · Dio |
| Backend | NestJS 10 · TypeScript · Mongoose 8 · JWT |
| Base de données | MongoDB 7 |
| Infrastructure | Docker Compose · Nginx reverse proxy |

---

## Architecture

```
bloodconnect/
├── backend/          # API REST NestJS
│   └── src/
│       ├── modules/
│       │   ├── auth/
│       │   ├── users/
│       │   ├── appointments/
│       │   ├── donations/
│       │   ├── blood-centers/
│       │   ├── blood-inventory/
│       │   └── notifications/
│       └── common/
├── frontend/         # Application Flutter
│   └── lib/
│       ├── core/
│       ├── features/
│       │   ├── auth/
│       │   ├── donations/
│       │   ├── home/
│       │   ├── map/
│       │   ├── alerts/
│       │   └── profile/
│       └── shared/
├── nginx/            # Configuration reverse proxy
└── docker-compose.yml
```

---

## Roles

| Role | Capacités |
|---|---|
| `donor` | Soumettre / annuler des demandes de don, voir l'historique |
| `center_admin` | Confirmer / rejeter / compléter les demandes du centre |
| `admin` | Accès global, gestion des stocks et des alertes |

---

## Règle d'éligibilité

Un donneur **ne peut pas soumettre de demande** si :
- Son statut médical est marqué **non éligible** (`medicallyEligible = false`)
- Il a effectué un don **il y a moins de 56 jours** (8 semaines)

Cette règle est vérifiée à deux niveaux :
1. **Frontend** : le bouton "New Request" est bloqué avec un message explicite
2. **Backend** : l'endpoint `POST /appointments` retourne une erreur 400 si la contrainte n'est pas respectée

---

## Cycle d'une demande de don

```
PENDING ──► CONFIRMED ──► COMPLETED
   │              │
   └──────────────┴──► REJECTED
   │
   └──► CANCELLED  (par le donneur)
```

---

## Installation et démarrage

### Prérequis

- Docker & Docker Compose
- Flutter SDK ≥ 3.1.0
- Node.js ≥ 18 (optionnel, pour développement backend sans Docker)

### 1. Cloner le projet

```bash
git clone https://github.com/<votre-username>/bloodconnect.git
cd bloodconnect
```

### 2. Configurer les variables d'environnement

```bash
cp .env.example .env
```

Modifier `.env` :

```env
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=changeme
MONGO_DB_NAME=bloodconnect
MONGO_URI=mongodb://admin:changeme@mongodb:27017/bloodconnect?authSource=admin
JWT_SECRET=<secret_aléatoire_long>
JWT_REFRESH_SECRET=<secret_aléatoire_long>
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
PORT=3000
NODE_ENV=production
```

### 3. Démarrer le backend

```bash
docker compose up -d
```

L'API est accessible sur `http://<IP_SERVEUR>/api`.

### 4. Configurer et lancer l'application Flutter

Modifier l'IP dans `frontend/lib/core/constants/api_endpoints.dart` :

```dart
static const baseUrl = 'http://<IP_SERVEUR>/api';
```

Puis :

```bash
cd frontend
flutter pub get
flutter run                     # développement
flutter build apk --release     # APK Android
```

---

## Endpoints principaux

```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh

GET    /api/users/me
PATCH  /api/users/me

GET    /api/blood-centers
GET    /api/blood-inventory/summary/global

POST   /api/appointments
GET    /api/appointments/my
GET    /api/appointments/center/:centerId
PATCH  /api/appointments/:id/confirm
PATCH  /api/appointments/:id/complete
PATCH  /api/appointments/:id/reject
PATCH  /api/appointments/:id/cancel

GET    /api/donations/my
GET    /api/donations/my/stats
```

---

## Comptes de test

> Ces comptes sont créés par le script de seed au premier démarrage.

| Email | Mot de passe | Rôle |
|---|---|---|
| `donor@test.com` | `password123` | donor |
| `admin@cnts.mr` | `password123` | center_admin |
| `admin@bloodconnect.mr` | `password123` | admin |

---

## Fonctionnalités clés

- Authentification JWT avec refresh token automatique
- Carte des centres de transfusion avec stocks en temps réel
- Alertes in-app de pénurie sanguine (notifications stockées en base)
- Moteur de détection automatique des pénuries (cron toutes les 30 min)
- Confirmation automatique des demandes lors d'une pénurie critique
- Règle d'éligibilité médicale et délai de 56 jours entre dons
- Interface dédiée admin centre : Pending / Confirmed / Completed / Rejected
