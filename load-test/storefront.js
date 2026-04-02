import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = (__ENV.BASE_URL || 'http://127.0.0.1:8080').replace(/\/+$/, '');
const TEST_PROFILE = __ENV.TEST_PROFILE || '200';

const PROFILE_TOTAL_VUS = {
  200: 200,
  1000: 1000,
  5000: 5000,
  20000: 20000,
  50000: 50000,
  70000: 70000,
  90000: 90000,
};

function resolveTotalVus() {
  if (__ENV.TOTAL_VUS) {
    const parsed = Number.parseInt(__ENV.TOTAL_VUS, 10);
    if (!Number.isNaN(parsed) && parsed > 0) {
      return parsed;
    }
  }

  const mappedProfile = PROFILE_TOTAL_VUS[TEST_PROFILE];
  if (mappedProfile) {
    return mappedProfile;
  }

  throw new Error(
    `Unsupported TEST_PROFILE "${TEST_PROFILE}". Supported values: ${Object.keys(PROFILE_TOTAL_VUS).join(', ')}`
  );
}

function splitScenarioTargets(totalVus) {
  const browseCatalog = Math.floor(totalVus * 0.60);
  const searchProducts = Math.floor(totalVus * 0.25);
  const addToCart = Math.floor(totalVus * 0.10);
  const checkoutGuest = totalVus - browseCatalog - searchProducts - addToCart;

  return {
    browseCatalog,
    searchProducts,
    addToCart,
    checkoutGuest,
  };
}

const totalVus = resolveTotalVus();
const scenarioTargets = splitScenarioTargets(totalVus);

function createStages(target) {
  return [
    { duration: '1m', target },
    { duration: '2m', target },
    { duration: '1m', target: 0 },
  ];
}

/**
 * setup() - Récupère les IDs des produits spécifiques
 * Version optimisée : cible directement les produits connus
 * S'exécute en <5 secondes
 */
export function setup() {
  console.log(
    `Running TEST_PROFILE=${TEST_PROFILE}, TOTAL_VUS=${totalVus}, split=${JSON.stringify(scenarioTargets)}`
  );
  console.log('🔍 Loading specific products...');

  const products = [];
  const categories = [
    { seName: 'computers', url: `${BASE_URL}/computers` },
    { seName: 'smartphones', url: `${BASE_URL}/smartphones` }
  ];

  // Liste des produits à charger (slugs connus)
  const targetProducts = [
    'redmi-k30-ultra',
    'mi-notebook-14'
  ];

  // Charger chaque produit pour extraire son ID
  for (const productSlug of targetProducts) {
    const prodUrl = `${BASE_URL}/${productSlug}`;
    const prodRes = http.get(prodUrl);

    if (prodRes.status !== 200) {
      console.warn(`⚠️  Product not found: ${productSlug}`);
      continue;
    }

    // Extraire l'ID produit (essayer plusieurs patterns)
    let productId = null;

    // Pattern 1: data-productid
    let match = prodRes.body.match(/data-productid="([a-f0-9]{24})"/i);
    if (match) productId = match[1];

    // Pattern 2: input hidden ProductId
    if (!productId) {
      match = prodRes.body.match(/name="ProductId"\s+value="([a-f0-9]{24})"/i);
      if (match) productId = match[1];
    }

    // Pattern 3: addproducttocart URL
    if (!productId) {
      match = prodRes.body.match(/\/addproducttocart\/(?:catalog|details)\/([a-f0-9]{24})/i);
      if (match) productId = match[1];
    }

    if (productId) {
      products.push({
        id: productId,
        seName: productSlug,
        url: prodUrl
      });
      console.log(`✓ Product loaded: ${productSlug} (${productId})`);
    } else {
      console.warn(`⚠️  Could not extract ID for: ${productSlug}`);
    }
  }

  // Validation
  if (products.length === 0) {
    console.error('❌ No products loaded! Check product slugs and BASE_URL.');
    throw new Error('No products loaded. Verify that products exist: ' + targetProducts.join(', '));
  }

  console.log(`✅ Setup complete: ${products.length} products, ${categories.length} categories\n`);

  return { products, categories };
}

// =======================
// Helpers
// =======================

const searchTerms = ['laptop', 'phone', 'watch', 'book', 'shirt'];

function rand(min, max) {
  return Math.random() * (max - min) + min;
}

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

// =======================
// Scénarios k6
// =======================

export const options = {
  scenarios: {
    browse_catalog: {
      executor: 'ramping-vus',
      exec: 'browseCatalog',
      startVUs: 0,
      stages: createStages(scenarioTargets.browseCatalog),
    },

    search_products: {
      executor: 'ramping-vus',
      exec: 'searchProducts',
      startVUs: 0,
      stages: createStages(scenarioTargets.searchProducts),
    },

    add_to_cart: {
      executor: 'ramping-vus',
      exec: 'addToCart',
      startVUs: 0,
      stages: createStages(scenarioTargets.addToCart),
    },

    checkout_guest: {
      executor: 'ramping-vus',
      exec: 'checkoutGuest',
      startVUs: 0,
      stages: createStages(scenarioTargets.checkoutGuest),
    },
  },

  thresholds: {
    http_req_failed: ['rate<0.05'],

    'http_req_duration{scenario:browse_catalog}': ['p(95)<1500'],
    'http_req_duration{scenario:search_products}': ['p(95)<6000'],
    'http_req_duration{scenario:add_to_cart}': ['p(95)<2500'],
    'http_req_duration{scenario:checkout_guest}': ['p(95)<5000'],
  },
};

// =======================
// Scénarios utilisateurs
// =======================

export function browseCatalog(data) {
  // Homepage
  let res = http.get(`${BASE_URL}/`, {
    tags: { endpoint: 'home', scenario: 'browse_catalog' }
  });
  check(res, { 'home 200': (r) => r.status === 200 });
  sleep(rand(0.5, 2));

  // Category (utilise les catégories découvertes)
  const category = pick(data.categories);
  res = http.get(`${BASE_URL}/${category.seName}`, {
    tags: { endpoint: 'category', scenario: 'browse_catalog' }
  });
  check(res, { 'category reachable': (r) => r.status < 500 });
  sleep(rand(1, 3));

  // Product (utilise les produits découverts)
  const product = pick(data.products);
  res = http.get(`${BASE_URL}/${product.seName}`, {
    tags: { endpoint: 'product', scenario: 'browse_catalog' }
  });
  check(res, { 'product 200': (r) => r.status === 200 });
  sleep(rand(2, 4));
}

export function searchProducts() {
  const term = pick(searchTerms);

  // Autocomplete
  let res = http.get(
    `${BASE_URL}/catalog/searchtermautocomplete?term=${term.substring(0, 3)}`,
    {
      tags: {
        endpoint: 'autocomplete',
        scenario: 'search_products',
      },
    }
  );
  check(res, { 'autocomplete <500': r => r.status < 500 });
  sleep(rand(0.3, 1));

  // Search
  res = http.get(
    `${BASE_URL}/search/?q=${term}`,
    {
      tags: {
        endpoint: 'search',
        scenario: 'search_products',
      },
    }
  );
  check(res, { 'search <500': r => r.status < 500 });
  sleep(rand(1, 3));
}


export function addToCart(data) {
  const product = pick(data.products);

  // Initialiser la session
  http.get(`${BASE_URL}/`);

  sleep(rand(1, 2));

  // Add to cart (FORM)
  const payload = {
    ProductId: product.id,
    ShoppingCartTypeId: 1,
    Quantity: 1,
    EnteredQuantity: 1,
  };

  const res = http.post(
    `${BASE_URL}/addproducttocart/details/${product.id}/1`,
    payload,
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      tags: {
        scenario: 'add_to_cart',
        endpoint: 'add_to_cart',
      },
      timeout: '30s',
    }
  );

  check(res, {
    'add to cart success': r => r.status === 200 && r.json('success') === true,
  });

  sleep(rand(1, 2));

  const cartRes = http.get(`${BASE_URL}/cart/`);
  check(cartRes, { 'cart reachable': r => r.status === 200 });
}


export function checkoutGuest(data) {
  const product = pick(data.products);

  // Add to cart
  http.post(
    `${BASE_URL}/addproducttocart/catalog/${product.id}/1`,
    JSON.stringify({
      ProductId: product.id,
      ShoppingCartTypeId: 1,
      Quantity: 1,
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  sleep(1);

  // Start checkout
  let res = http.get(`${BASE_URL}/checkout/`, {
    tags: { endpoint: 'checkout_start' },
  });

  // Peut rediriger vers login
  check(res, { 'checkout reachable': r => r.status === 200 || r.status === 302 });

  sleep(rand(2, 4));
}
