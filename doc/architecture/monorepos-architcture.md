```
your-app/
├── packages/                            # 📦 Packages Dart réutilisables
│   ├── shared_models/                  # Modèles de données partagés entre client & serveur
│   │   ├── lib/
│   │   │   ├── models/
│   │   │   │   ├── price_promotion.dart
│   │   │   │   ├── store_price.dart
│   │   │   │   ├── product_statistics.dart
│   │   │   │   ├── price_point.dart
│   │   │   │   └── promotion_type.dart
│   │   │   ├── services/
│   │   │   │   └── statistics_calculator.dart
│   │   │   ├── utils/
│   │   │   │   └── price_validator.dart
│   │   │   └── shared_models.dart
│   │   └── pubspec.yaml
│   │
│   ├── api_contracts/                  # Interfaces de requêtes/réponses pour l'API
│   │   ├── lib/
│   │   │   ├── requests/
│   │   │   │   ├── product_search_request.dart
│   │   │   │   └── price_update_request.dart
│   │   │   ├── responses/
│   │   │   │   ├── product_search_response.dart
│   │   │   │   └── price_statistics_response.dart
│   │   │   └── api_contracts.dart
│   │   └── pubspec.yaml
│   │
│   └── shared_utils/                   # ← optionnel : fonctions utilitaires ou constantes communes
│       ├── lib/
│       │   ├── constants/
│       │   └── utils/
│       └── pubspec.yaml

├── apps/                               # 📱 Applications principales
│   ├── client/                         # Flutter mobile app
│   │   ├── lib/
│   │   │   ├── pages/
│   │   │   ├── widgets/
│   │   │   ├── database/               # base SQLite ou Isar locale
│   │   │   └── services/
│   │   │       └── api_client.dart     # communication avec le backend
│   │   ├── test/                       # ← ajouté : tests unitaires de l'app
│   │   └── pubspec.yaml
│   │
│   ├── gateway_server/                # 🌐 Serveur API barcode
│   │   ├── lib/
│   │   │   ├── handlers/
│   │   │   │   └── barcode_handler.dart
│   │   │   ├── services/
│   │   │   │   └── external_api_service.dart
│   │   │   ├── middlewares/           # ← ajouté : future auth, logging, rate limiting
│   │   │   └── server.dart
│   │   ├── test/                      # ← ajouté
│   │   └── pubspec.yaml
│   │
│   ├── data_server/                   # 💾 Serveur principal : prix, stats, historique
│   │   ├── lib/
│   │   │   ├── handlers/
│   │   │   │   ├── statistics_handler.dart
│   │   │   │   └── price_handler.dart
│   │   │   ├── database/
│   │   │   │   └── server_database.dart
│   │   │   ├── middlewares/          # ← ajouté : auth, cache, logs
│   │   │   └── server.dart
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   └── admin_portal/                  # ← optionnel : interface web admin (Flutter Web ou React)
│       └── (à définir)

├── scrapers/                           # 🕷️ Scripts Python de collecte (offline ou régulière)
│   └── price_scraper/
│       ├── carrefour.py
│       ├── metadata_parser.py
│       └── README.md

├── devops/                             # 🛠️ Déploiement & environnement
│   ├── docker/
│   │   ├── Dockerfile.gateway
│   │   ├── Dockerfile.data
│   │   └── docker-compose.yml
│   ├── scripts/
│   │   └── init_db.sh
│   └── README.md

├── docs/                               # 📚 Documentation
│   ├── architecture.md
│   ├── data_flow.md
│   └── tech_choices.md

├── .gitignore
├── README.md
└── pubspec.yaml                        # Racine : éventuellement un mono-repo géré via `melos`
```
