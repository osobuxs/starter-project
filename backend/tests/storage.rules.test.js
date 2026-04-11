const { before, beforeEach, after, describe, test } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'demo-symmetry-news';
const STORAGE_HOST = process.env.FIREBASE_STORAGE_EMULATOR_HOST;

if (!STORAGE_HOST) {
  throw new Error(
    'FIREBASE_STORAGE_EMULATOR_HOST is not set. Run via `npm run test:rules` so emulator is booted automatically.',
  );
}

const rules = fs.readFileSync(path.resolve(__dirname, '../storage.rules'), 'utf8');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    storage: {
      rules,
      host: STORAGE_HOST.split(':')[0],
      port: Number(STORAGE_HOST.split(':')[1]),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearStorage();
});

describe('storage.rules', () => {
  function storageFor(context) {
    return context.storage();
  }

  test('owner can upload profile image', async () => {
    const storage = storageFor(testEnv.authenticatedContext('user-1'));
    const profileRef = storage.ref('media/users/user-1/profile.jpg');

    await assertSucceeds(
      profileRef.putString('fake-image-bytes', 'raw', {
        contentType: 'image/jpeg',
      }),
    );
  });

  test('non-owner cannot upload profile image', async () => {
    const storage = storageFor(testEnv.authenticatedContext('attacker'));
    const profileRef = storage.ref('media/users/user-1/profile.jpg');

    await assertFails(
      profileRef.putString('fake-image-bytes', 'raw', {
        contentType: 'image/jpeg',
      }),
    );
  });

  test('owner cannot upload non-image content', async () => {
    const storage = storageFor(testEnv.authenticatedContext('user-1'));
    const profileRef = storage.ref('media/users/user-1/profile.txt');

    await assertFails(
      profileRef.putString('plain-text', 'raw', {
        contentType: 'text/plain',
      }),
    );
  });

  test('author can upload article image in own path', async () => {
    const storage = storageFor(testEnv.authenticatedContext('author-1'));
    const articleRef = storage.ref('articles/author-1/123456.jpg');

    await assertSucceeds(
      articleRef.putString('fake-image-bytes', 'raw', {
        contentType: 'image/png',
      }),
    );
  });

  test('non-author cannot upload article image in someone else path', async () => {
    const storage = storageFor(testEnv.authenticatedContext('attacker'));
    const articleRef = storage.ref('articles/author-1/123456.jpg');

    await assertFails(
      articleRef.putString('fake-image-bytes', 'raw', {
        contentType: 'image/png',
      }),
    );
  });

  test('owner can delete own profile image after upload', async () => {
    const storage = storageFor(testEnv.authenticatedContext('user-1'));
    const profileRef = storage.ref('media/users/user-1/profile.jpg');

    await assertSucceeds(
      profileRef.putString('fake-image-bytes', 'raw', {
        contentType: 'image/jpeg',
      }),
    );
    await assertSucceeds(profileRef.delete());
  });
});
