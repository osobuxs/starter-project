const { before, beforeEach, after, describe, test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

const PROJECT_ID = 'demo-symmetry-news';
const FIRESTORE_HOST = process.env.FIRESTORE_EMULATOR_HOST;

if (!FIRESTORE_HOST) {
  throw new Error(
    'FIRESTORE_EMULATOR_HOST is not set. Run via `npm run test:rules` so emulator is booted automatically.',
  );
}

const rules = fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules,
      host: FIRESTORE_HOST.split(':')[0],
      port: Number(FIRESTORE_HOST.split(':')[1]),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

async function seedDoc(pathRef, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), pathRef), data);
  });
}

function articleBase(overrides = {}) {
  return {
    authorId: 'author-1',
    authorName: 'Author One',
    authorEmail: 'author1@example.com',
    authorPhotoUrl: null,
    title: 'A title',
    subtitle: 'A subtitle',
    description: 'A subtitle',
    category: 'Tech',
    content: 'A lot of content',
    urlToImage: 'https://img.example.com/pic.jpg',
    thumbnailUrl: 'https://img.example.com/pic.jpg',
    isPublished: false,
    isActive: true,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    publishedAt: null,
    favoritesVersion: 0,
    ...overrides,
  };
}

function profileBase(overrides = {}) {
  return {
    name: 'Ada',
    email: 'ada@example.com',
    age: 33,
    photoUrl: null,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    ...overrides,
  };
}

function favoriteFromArticle(articleId, overrides = {}) {
  return {
    articleId,
    favoritedAt: new Date('2026-01-01T01:00:00.000Z'),
    favoritesVersion: 0,
    firestoreId: articleId,
    authorId: 'author-1',
    author: 'Author One',
    authorPhotoUrl: null,
    title: 'A title',
    description: 'A subtitle',
    category: 'Tech',
    url: '',
    urlToImage: 'https://img.example.com/pic.jpg',
    publishedAt: '2026-01-01',
    content: 'A lot of content',
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    isPublished: true,
    isActive: true,
    ...overrides,
  };
}

describe('firestore.rules', () => {
  test('public can read published+active article', async () => {
    await seedDoc(
      'articles/article-public',
      articleBase({ isPublished: true, isActive: true }),
    );

    const anonDb = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(anonDb, 'articles/article-public')));
  });

  test('public cannot read draft article', async () => {
    await seedDoc(
      'articles/article-draft',
      articleBase({ isPublished: false, isActive: true }),
    );

    const anonDb = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anonDb, 'articles/article-draft')));
  });

  test('author can create own article', async () => {
    const authorDb = testEnv.authenticatedContext('author-1').firestore();
    await assertSucceeds(
      setDoc(doc(authorDb, 'articles/new-article'), articleBase()),
    );
  });

  test('authenticated user cannot create article for another authorId', async () => {
    const attackerDb = testEnv.authenticatedContext('attacker').firestore();
    await assertFails(
      setDoc(
        doc(attackerDb, 'articles/hijacked-article'),
        articleBase({ authorId: 'author-1' }),
      ),
    );
  });

  test('author can update own article and preserve immutable fields', async () => {
    await seedDoc('articles/article-own', articleBase());

    const authorDb = testEnv.authenticatedContext('author-1').firestore();
    await assertSucceeds(
      updateDoc(doc(authorDb, 'articles/article-own'), {
        title: 'Updated title',
        updatedAt: new Date('2026-01-02T00:00:00.000Z'),
      }),
    );
  });

  test('non-author cannot update article', async () => {
    await seedDoc('articles/article-own', articleBase());

    const attackerDb = testEnv.authenticatedContext('attacker').firestore();
    await assertFails(
      updateDoc(doc(attackerDb, 'articles/article-own'), {
        title: 'Malicious update',
        updatedAt: new Date('2026-01-02T00:00:00.000Z'),
      }),
    );
  });

  test('owner can read and update own user profile', async () => {
    await seedDoc('users/user-1', profileBase());

    const ownerDb = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(getDoc(doc(ownerDb, 'users/user-1')));
    await assertSucceeds(
      updateDoc(doc(ownerDb, 'users/user-1'), {
        name: 'Ada Updated',
        updatedAt: new Date('2026-01-03T00:00:00.000Z'),
      }),
    );
  });

  test('non-owner cannot read or update another profile', async () => {
    await seedDoc('users/user-1', profileBase());

    const attackerDb = testEnv.authenticatedContext('attacker').firestore();
    await assertFails(getDoc(doc(attackerDb, 'users/user-1')));
    await assertFails(
      updateDoc(doc(attackerDb, 'users/user-1'), {
        name: 'Hacked',
        updatedAt: new Date('2026-01-03T00:00:00.000Z'),
      }),
    );
  });

  test('owner can create favorite for active+published article', async () => {
    await seedDoc(
      'articles/article-public',
      articleBase({ isPublished: true, isActive: true }),
    );

    const ownerDb = testEnv.authenticatedContext('user-1').firestore();
    await assertSucceeds(
      setDoc(
        doc(ownerDb, 'users/user-1/favorites/article-public'),
        favoriteFromArticle('article-public'),
      ),
    );
  });

  test('owner cannot favorite draft article', async () => {
    await seedDoc(
      'articles/article-draft',
      articleBase({ isPublished: false, isActive: true }),
    );

    const ownerDb = testEnv.authenticatedContext('user-1').firestore();
    await assertFails(
      setDoc(
        doc(ownerDb, 'users/user-1/favorites/article-draft'),
        favoriteFromArticle('article-draft'),
      ),
    );
  });

  test('only owner can delete own favorite', async () => {
    await seedDoc(
      'articles/article-public',
      articleBase({ isPublished: true, isActive: true }),
    );
    await seedDoc(
      'users/user-1/favorites/article-public',
      favoriteFromArticle('article-public'),
    );

    const ownerDb = testEnv.authenticatedContext('user-1').firestore();
    const attackerDb = testEnv.authenticatedContext('attacker').firestore();

    await assertFails(
      deleteDoc(doc(attackerDb, 'users/user-1/favorites/article-public')),
    );
    await assertSucceeds(
      deleteDoc(doc(ownerDb, 'users/user-1/favorites/article-public')),
    );
  });

});
