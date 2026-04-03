# Tests de charge avec k6

Ce dossier contient la mise en place des tests de charge du storefront GrandNode avec [k6](https://k6.io).

## Presentation

L'objectif du projet est de disposer d'une methode reproductible pour mesurer le comportement du site e-commerce sous charge, d'abord en local, puis depuis AWS.

Nous avons mis en place deux modes d'execution :

- un mode local pour valider rapidement le script, verifier les routes et obtenir une premiere baseline ;
- un mode AWS avec une instance EC2 dediee aux tests afin de lancer la charge depuis le cloud plutot que depuis un poste developpeur.

Cette approche permet de comparer :

- le comportement de l'application en environnement local ;
- le comportement du site une fois deployee derriere son load balancer AWS ;
- l'impact de differentes charges utilisateurs sur la navigation, la recherche, l'ajout au panier et le debut du checkout.

## Ce que nous avons mis en place

### 1. Un script k6 unique

Le script principal est [`storefront.js`](/mnt/c/Users/tobit/Projets/ecommerce-Terraform/load-test/storefront.js).

Il simule plusieurs parcours utilisateurs representatifs du storefront :

- navigation sur la page d'accueil ;
- ouverture d'une categorie ;
- consultation d'une fiche produit ;
- recherche via autocomplete et page de recherche ;
- ajout au panier ;
- debut de checkout en invite.

Le script charge aussi des produits reels au demarrage avec `setup()`, afin d'utiliser de vrais identifiants produit pendant les scenarios.

### 2. Des profils de charge predefinis

Le script accepte un `TEST_PROFILE` pour eviter de modifier le code entre chaque campagne.
Le mode actuel utilise une execution `per-vu-iterations` avec `1` iteration par VU, afin de se rapprocher d'un modele "1 utilisateur virtuel = 1 visite".

Profils disponibles :

- `200`
- `1000`
- `5000`
- `20000`
- `50000`
- `70000`
- `90000`

La repartition de la charge reste constante :

- `browse_catalog` : 60 %
- `search_products` : 25 %
- `add_to_cart` : 10 %
- `checkout_guest` : 5 %

Nous pouvons aussi surcharger manuellement la charge avec `TOTAL_VUS`.

### 3. Une infrastructure Terraform dediee au load testing

Le dossier [`infra/load-testing`](/mnt/c/Users/tobit/Projets/ecommerce-Terraform/infra/load-testing) permet de provisionner une EC2 dediee au load test.

Cette infrastructure comprend :

- une instance EC2 Ubuntu ;
- un security group avec SSH limite a notre IP publique ;
- l'installation automatique de `k6` via `user_data.sh` ;
- la copie automatique du script `storefront.js` sur la machine ;
- un output Terraform avec l'IP publique de l'instance.

L'objectif etait d'avoir une execution simple :

- `terraform apply`
- connexion SSH sur l'EC2
- lancement de `k6` contre l'URL du site deploye

### 4. Une execution possible en local et sur AWS

En local, le site est lance avec `docker compose`, puis `k6` cible `http://127.0.0.1:8080`.

Sur AWS, le test est lance depuis l'EC2 vers l'URL publique du load balancer du site.

Cela nous permet :

- de verifier d'abord le script et les routes ;
- puis de mesurer le comportement du vrai deploiement cloud.

## Variables d'environnement

| Variable | Defaut | Description |
| --- | --- | --- |
| `BASE_URL` | `http://127.0.0.1:8080` | URL de base du storefront a tester |
| `TEST_PROFILE` | `200` | Profil predefini a lancer |
| `TOTAL_VUS` | vide | Nombre total de VUs personnalise, prioritaire sur `TEST_PROFILE` |

## Lancer les tests en local

### 1. Demarrer le site

Depuis la racine du projet :

```bash
docker compose up -d --build
```

Le storefront est alors accessible sur :

```text
http://127.0.0.1:8080
```

### 2. Lancer k6 en local

Depuis le dossier `load-test/` :

```bash
k6 run -e BASE_URL=http://127.0.0.1:8080 storefront.js
```

Exemples :

```bash
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=200 storefront.js
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=1000 storefront.js
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TEST_PROFILE=5000 storefront.js
```

Charge libre :

```bash
k6 run -e BASE_URL=http://127.0.0.1:8080 -e TOTAL_VUS=1500 storefront.js
```

## Lancer les tests depuis AWS

### 1. Deployer l'infrastructure de load testing

Depuis le dossier `infra/load-testing/` :

```bash
terraform init
terraform apply
```

### 2. Recuperer l'IP publique

```bash
terraform output load_test_public_ip
```

### 3. Se connecter a l'instance EC2

```bash
ssh -i /home/tanel/.ssh/ecommerce-loadtest-key.pem ubuntu@<IP_PUBLIQUE>
```

### 4. Lancer les tests sur l'instance

```bash
cd /opt/load-tests
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=200 storefront.js
```

Exemples :

```bash
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=1000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=5000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=20000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=50000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=70000 storefront.js
k6 run -e BASE_URL="http://your-alb-or-site-url" -e TEST_PROFILE=90000 storefront.js
```

## Lecture des resultats

Les metriques principales que nous utilisons sont :

- `http_req_failed` : taux de requetes en echec ;
- `http_req_duration` : temps de reponse HTTP ;
- `p(95)` : latence observee pour 95 % des requetes ;
- `iterations` : nombre total de parcours executes ;
- `vus` / `vus_max` : nombre d'utilisateurs virtuels actifs.

Nous surveillons particulierement :

- le comportement des pages categories et produits ;
- la recherche ;
- les appels d'ajout au panier ;
- la stabilite de l'application sous charge ;
- l'apparition de timeouts ou d'erreurs en masse.

## Limitations et points d'attention

- Un test local mesure aussi les limites de la machine locale, pas uniquement celles de l'application.
- Une seule EC2 de load testing peut devenir elle-meme un goulet d'etranglement sur les profils les plus eleves.
- Les tests a tres forte charge doivent etre interpretes avec les metriques AWS du deploiement cible : pods, base de donnees, load balancer, timeouts, erreurs 5xx.
- Les profils `50000+` doivent etre lances de maniere progressive, apres validation des profils plus petits.
- Ce mode consomme moins de ressources qu'un test en `ramping-vus` avec boucle continue, mais il mesure moins agressivement la tenue sous charge soutenue.

## Commandes utiles

Arreter un test k6 proprement :

- `Ctrl + C` une fois pour laisser k6 afficher son resume final

Arreter le site local :

```bash
docker compose down
```

Detruire l'infrastructure de load testing :

```bash
terraform destroy
```

## Avec Docker pour k6

Depuis la racine du projet :

```bash
docker run --rm -v "${PWD}/load-test:/scripts" grafana/k6 run -e BASE_URL=http://host.docker.internal:8080 -e TEST_PROFILE=1000 /scripts/storefront.js
```

Sous Linux, utiliser `--network host` avec `BASE_URL=http://127.0.0.1:8080`.
