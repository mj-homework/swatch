import { readFileSync } from 'node:fs';
import { before, after, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, collection, query, limit, getDocs, serverTimestamp } from 'firebase/firestore';
let env;
before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-shopwatch', firestore: {
    rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8080
  }});
});
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const db = uid => env.authenticatedContext(uid).firestore();
const player = async (uid = 'alice') => setDoc(doc(db(uid), 'players/alice'), {uid, createdAt: serverTimestamp()});
const score = (overrides = {}) => ({uid: 'alice', nickname: 'Alice', normalizedNickname: 'alice', averageDiffMs: 125.5,
  itemCount: 2, difficulty: 'normal', createdAt: serverTimestamp(), ...overrides});
test('authenticated owner reservation, read/reuse, collision and immutable owner', async () => {
  await assertSucceeds(player());
  await assertSucceeds(getDoc(doc(db('alice'), 'players/alice')));
  await assertFails(player('bob'));
  await assertFails(updateDoc(doc(db('alice'), 'players/alice'), {uid: 'bob'}));
});
test('reject anonymous and forged ownership', async () => {
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'players/alice'), {uid: 'alice', createdAt: serverTimestamp()}));
  await assertFails(setDoc(doc(db('bob'), 'players/alice'), {uid: 'alice', createdAt: serverTimestamp()}));
});
test('valid score, bounded reads, immutable score and foreign score', async () => {
  await player();
  await assertSucceeds(setDoc(doc(db('alice'), 'scores/a'), score()));
  await assertSucceeds(getDocs(query(collection(db('bob'), 'scores'), limit(10))));
  await assertFails(getDocs(collection(db('bob'), 'scores')));
  await assertFails(updateDoc(doc(db('alice'), 'scores/a'), {averageDiffMs: 0}));
  await assertFails(setDoc(doc(db('bob'), 'scores/b'), score({uid: 'bob'})));
});
test('malformed and out of range scores rejected', async () => {
  await player();
  for (const change of [{averageDiffMs: -1}, {averageDiffMs: 86400001}, {averageDiffMs: '1.5'}, {itemCount: 0},
    {itemCount: 101}, {difficulty: 'cheat'}, {extra: true}, {createdAt: new Date(0)}, {normalizedNickname: '../alice'}]) {
    await assertFails(setDoc(doc(db('alice'), 'scores/bad'), score(change)));
  }
  const missing = score(); delete missing.nickname;
  await assertFails(setDoc(doc(db('alice'), 'scores/missing'), missing));
});
