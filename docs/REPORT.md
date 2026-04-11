# Final Challenge Report

## 1. Delivery Summary

This repository started as a **news app starter** with an existing Flutter structure, a prebuilt public news browsing flow, architectural guidelines, and a Firebase-oriented backend folder. The challenge was not to create a product from zero, but to **turn that starter into a technically defensible application where users can own and publish their own articles through a real Firebase backend**.

The final implementation does that, and goes beyond the minimum in a controlled way. The current system is no longer just a starter with small edits: it is a coherent Firebase-backed article platform with public reading flows, authenticated authoring flows, user profiles, favorites, hardened route access, and updated backend contracts.

Canonical implementation documentation now lives in `DocsV2/`. This report focuses on evaluator-facing context: what the original challenge asked for, what already existed, what was implemented, what was added as overdelivery, and what should matter during technical evaluation.

## 2. What the Original Challenge Asked For

Based on the original repository brief and challenge instructions, the core request was:

1. Design and document a Firebase-backed article schema.
2. Implement that schema in Firestore/Storage.
3. Enforce the schema with security rules.
4. Connect the Flutter frontend to Firebase.
5. Allow a user to create and manage their own articles.
6. Preserve the architectural direction of the starter.
7. Deliver documentation explaining the work.

The core of the assignment was therefore **ownership and publication of user-generated articles**, not merely cosmetic UI work.

## 3. What the Starter Already Had

The starter provided real value and should be evaluated honestly as pre-existing work:

- a Flutter codebase already organized around `data / domain / presentation`
- BLoC/Cubit usage patterns
- an existing public dashboard/detail news experience
- a Firebase-oriented `backend/` folder and deployment-oriented artifacts
- legacy documentation explaining the intended architecture and challenge framing
- local favorites/database remnants from the original news app baseline

In other words, the delivery did **not** begin from an empty repository. The important question is whether the implementation meaningfully transformed that base into the required product. It did.

## 4. What Was Implemented for the Challenge

The final system now supports the challenge's core publishing workflow with real backend integration:

### Backend

- Firestore collections for `articles`, `users`, and per-user `favorites`
- Storage paths for article images and profile images
- Firestore rules that distinguish between:
  - public reads of active/published articles
  - private author access to drafts/archived content
  - owner-only access to user profile documents
  - owner-only access to favorites subcollections
- Storage rules that restrict writes by authenticated resource owner and enforce image uploads
- required Firestore composite index for public dashboard queries

### Frontend

- public dashboard backed by Firestore published articles
- public article detail flow
- authenticated article creation/editing
- draft save flow
- publish flow
- my notes listing for author-owned content
- archive/reactivate flow through logical state changes instead of destructive deletes
- authenticated profile management
- persistent favorites per user
- protected route handling and post-auth redirect behavior

### Documentation

- canonical technical documentation consolidated under `DocsV2/`
- evaluator guide documenting suggested review order
- implementation matrix separating starter vs challenge vs delivered scope
- this final report for hiring/evaluation context

## 5. Clear Overdelivery Beyond the Original Minimum

The original challenge clearly justified article authoring and Firebase integration. The following pieces go beyond that minimum and should be treated as intentional overdelivery, not as retroactive baseline requirements:

- email/password authentication
- Google Sign-In
- editable user profile with photo upload
- synchronization of updated profile data into existing authored articles
- persistent user favorites stored in Firestore
- stale favorite invalidation when article visibility changes
- route hardening around protected and auth-only screens
- stronger evaluator-oriented documentation split by scope, frontend, backend, and delivery

These additions were not included as feature inflation for its own sake. They solve practical ownership, demo coherence, and reviewability problems that appear once the app becomes a real user-authored article system.

## 6. Key Architectural Decisions

### 6.1 Keep the starter architecture, but move real infrastructure into the data layer

The implementation keeps the original clean-architecture intent instead of collapsing logic directly into UI. Domain remains free from Flutter/Firebase imports, while Firebase access is concentrated in data sources and repositories.

**Why it matters:** this preserves the most important design constraint of the starter while still allowing the system to evolve from remote demo content into real application data.

### 6.2 Treat public reading and authenticated authoring as different access modes

The final app allows public access to the dashboard and article detail, while authoring, profile, notes, and favorites are authenticated flows.

**Why it matters:** the original starter behaved like a public news reader. Preserving that public read experience while adding protected authoring flows creates a more coherent product than forcing the entire app behind login.

### 6.3 Denormalize author metadata into article documents

Articles store author-facing fields such as `authorName`, `authorEmail`, and `authorPhotoUrl`, and profile updates synchronize those fields across existing authored articles.

**Why it matters:** public dashboard and detail views should not depend on reading private user profile documents. Denormalization keeps public reads simple and aligns with Firestore access patterns.

### 6.4 Use logical visibility state instead of physical deletion

Articles are controlled through `isPublished` and `isActive` instead of destructive delete flows.

**Why it matters:** this matches the challenge's “my notes” and logical removal intent better than permanent deletion, reduces accidental data loss, and keeps reviewer-visible state transitions easier to validate.

### 6.5 Store favorites under each user with article snapshots

Favorites live in `users/{uid}/favorites/{articleId}` and persist a denormalized snapshot plus `favoritesVersion`.

**Why it matters:** favorites can be listed without depending exclusively on fresh reads from the source article document, while versioning lets the system invalidate stale favorites when an article becomes archived or otherwise stops being publicly available.

## 7. Main Technical Challenges Solved

### 7.1 Converting a starter news app into an owned-content system

The hardest conceptual shift was that the starter was fundamentally a reader application, while the challenge required turning it into an authoring application. That affects backend modeling, permissions, navigation, state ownership, and UI behavior.

### 7.2 Reconciling public content with private profile data

Once profile editing exists, author information becomes part of the public reading experience. The implementation solved this by denormalizing author metadata into article documents and syncing profile updates to authored content.

### 7.3 Hardening route access without breaking the starter UX

Protected sections now redirect correctly through login/register and return the user to the intended destination after authentication. This is a small product detail but an important engineering detail because it removes dead-end navigation from evaluator flows.

### 7.4 Making favorites consistent with article lifecycle changes

Persistent favorites are easy to add superficially and easy to get wrong. This implementation explicitly handles stale favorite cleanup when an article is no longer active/published or when its visibility version changes.

### 7.5 Aligning rules with the real product, not the original assumptions

Security rules were written for the implemented system, not for an imagined generic CRUD app. Public reading, owner-only editing, private profile documents, and user-scoped favorites are all reflected in the backend contract.

## 8. Evaluation Notes for Reviewers

### What should be evaluated as the current source of truth

- `DocsV2/` for canonical implementation documentation
- `docs/REPORT.md` for challenge-level delivery context
- `frontend/` and `backend/` for the actual delivered system

### What should be treated as historical context

- the original root `README.md` challenge brief
- legacy challenge docs under `docs/` except this report
- starter-oriented assumptions that predate the final implementation
- `starterV2/` as a preserved historical artifact

### Recommended review path

1. Read `FINAL_DELIVERY_README.md`
2. Read `DocsV2/02-scope/IMPLEMENTATION_MATRIX.md`
3. Read `DocsV2/05-delivery/EVALUATOR_GUIDE.md`
4. Inspect `frontend/lib/config/routes/routes.dart`
5. Inspect `backend/firestore.rules` and `backend/storage.rules`

### Recommended functional walkthrough

1. Public dashboard and article detail
2. Authentication
3. Create draft and publish article
4. My Notes archive/reactivate flow
5. Favorites
6. Profile update and author metadata consistency

## 9. Honest Final Assessment

This delivery should be evaluated as a **substantial transformation of the provided starter**, not as a greenfield product and not as a superficial reskin.

Technically, the strongest parts of the submission are:

- coherent Firebase data contract
- rules aligned with actual ownership boundaries
- preservation of architectural layering
- meaningful extension beyond the minimum without collapsing maintainability
- reviewer-oriented documentation that distinguishes clearly between starter, requested scope, and overdelivery

The most important evaluation lens is whether the repository now demonstrates the ability to take an imperfect starter, understand its architectural intent, and evolve it into a more complete, more defensible product. The implemented system and supporting documentation provide strong evidence that it does.

## 10. Final Submission Note

This report intentionally avoids claiming unsupported work. It is based on the implementation currently present in `frontend/`, `backend/`, and `DocsV2/`.

If submission packaging requires proof media such as screenshots, video, or distributable mobile artifacts, those should be attached separately as final submission assets; they are not embedded in this document.
