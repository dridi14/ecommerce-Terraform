# Tests de charge avec k6

Tests de charge du storefront GrandNode avec [k6](https://k6.io).

## Prerequis

- GrandNode accessible via une URL de base.
- k6 installe localement, ou Docker pour executer k6 en conteneur.

## Profils disponibles

Le script supporte les profils suivants via `TEST_PROFILE` :

- `200`
- `1000`
- `5000`
- `20000`
- `50000`
- `70000`
- `90000`

La repartition entre scenarios reste fixe :

- `browse_catalog` : 60 %
- `search_products` : 25 %
- `add_to_cart` : 10 %
- `checkout_guest` : 5 %

## Variables d'environnement

| Variable | Defaut | Description |
| --- | --- | --- |
| `BASE_URL` | `http://127.0.0.1:8080` | URL de base du storefront a tester. |
| `TEST_PROFILE` | `200` | Profil predefini a lancer. |
| `TOTAL_VUS` | vide | Nombre total de VUs personnalise. Prioritaire sur `TEST_PROFILE`. |

## Lancer rapidement

Depuis le dossier `load-test/` :

```bash
k6 run -e BASE_URL=http://127.0.0.1:8080 storefront.js
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=1000 storefront.js
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=5000 storefront.js
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=20000 storefront.js
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=50000 storefront.js
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=70000 storefront.js
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=90000 storefront.js
```

Pour une charge libre :

```bash
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TOTAL_VUS=1500 storefront.js
```

## Depuis l'instance EC2 de load testing

```bash
cd /opt/load-tests
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=1000 storefront.js
```

Exemples :

```bash
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=5000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=20000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=50000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=70000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=90000 storefront.js
```

## Avec Docker

Depuis la racine du projet :

```bash
docker run --rm -v "${PWD}/load-test:/scripts" grafana/k6 run -e BASE_URL=http://host.docker.internal:8080 -e TEST_PROFILE=1000 /scripts/storefront.js
```

Sous Linux, utilise `--network host` et `BASE_URL=http://127.0.0.1:8080`.
