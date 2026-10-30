# Design decisions

Short decision records for Singgah. Each entry states the context, the choice,
and the trade-off we accepted.

---

## 1. Local-first with Hive, not Drift

**Context:** The app must work on a crowded train with no signal and still keep
Missions editable. The brief allowed Drift as an example but did not require it.

**Decision:** Use Hive CE boxes as the local source of truth, wrapped by
`LocalStore`. Every repository reads Hive first; writes are synchronous to the
device and then queued in an outbox.

**Consequences:** Very fast startup and no SQL schema migrations. Complex ad-hoc
queries are not available; the app only needs id lookups, full-table reads, and
watched snapshots, which Hive handles well.

---

## 2. Outbox + Last-Write-Wins sync

**Context:** Two devices can edit the same Mission or Titipan while offline.

**Decision:** `SyncEngine` pulls before pushing. Conflicts resolve by
`updated_at` (LWW); tombstones are ordinary rows so a delete is not resurrected by
a stale edit. An exact timestamp tie prefers a local `is_pending` row, otherwise
the server wins.

**Consequences:** Simple, deterministic, and easy to test. Clock skew is the
accepted weakness; pulling first bounds the damage. A future CRDT or field-level
merge can replace `ConflictResolver` without changing repositories.

---

## 3. Native Android geofences, not a Flutter plugin

**Context:** Battery-efficient geofencing needs `GeofencingClient`, a
manifest-declared receiver, and work while the Flutter engine is asleep.

**Decision:** Implement the bridge in Kotlin behind a single MethodChannel
(`dev.singgah/geofencing`). Dart only sees `GeofencingService`.

**Consequences:** Android background behavior stays in Android’s hands and
survives process death. The cost is platform code and a separate test boundary;
geofence planning and evaluation remain pure Dart and are heavily unit-tested.

---

## 4. Cap registration at 90 geofences

**Context:** Android allows roughly 100 geofences per app, and the OS reserves
some. Registering everything silently drops reminders.

**Decision:** `GeofencePlanner` builds a candidate list scored by:
1. scheduled today and inside its window,
2. runs today but outside the window,
3. does not run today,
then distance from the current location and recency. The default cap is 90.

**Consequences:** The user may not see a “registered” geofence for a far-away
Place until they move closer. The UI explains this and shows the registered count.
Re-planning happens after a 2 km move or any data change.

---

## 5. The native receiver re-checks schedule and cooldown

**Context:** The app may be closed when a transition fires. Dart cannot be relied
on to evaluate the time window.

**Decision:** Registration metadata includes `repeat_days`,
`window_start_minutes`, `window_end_minutes`, and the target transition. The
receiver evaluates them with the device clock and applies a 5-minute cooldown
before posting. It queues the transition for Dart to record in history.

**Consequences:** Missions stay quiet outside their window even when the app is
not running. The Dart and Kotlin rules must stay in sync; both are documented and
covered by tests on the Dart side, with the Kotlin path kept small and explicit.

---

## 6. History is device-only

**Context:** Arrival/departure history is sensitive and not needed for sync.

**Decision:** `singgah_events` never enters the outbox or Appwrite. It is cleared
on sign-out and can be manually cleared. `SyncEngine.syncTables` excludes it.

**Consequences:** Reinstalling loses history. That is an explicit privacy promise,
shown in Home, History, and Settings.

---

## 7. Titipan invites use a Function

**Context:** A recipient must become a member of a note atomically, but they
cannot grant themselves read access to a note they were not invited to.

**Decision:** The `accept-titipan` Function validates the caller from the
`x-appwrite-user-id` header, looks the token up with a server key, handles an
existing accepted row idempotently, upgrades an email invite if one exists, and
returns the note plus recipient metadata. It then adds
`read("user:<recipient>")` to the note and writes a recipient row that both the
sender and recipient can read.

**Consequences:** Tokens are capabilities, so they must be treated like secrets.
Acceptance is a single round trip and cannot half-succeed. A leaked token can be
accepted once per account but never grants access to other notes.

---

## 8. Row permissions are the only privacy boundary

**Context:** Local caches and client-side visibility helpers are not security.

**Decision:** Enforce ownership and recipient rules with Appwrite row
permissions. Every client-created row carries explicit
`read/update/delete("user:<owner>")` permissions; shared notes add a read
permission for each accepted recipient. The client mirrors the same rules in
`TitipanVisibility` only to keep local caches honest. No server key ships in the
app; the Functions own the privileged tables (`rate_limits`, `geocode_cache`).

**Consequences:** A compromised client still cannot read another user’s Places,
Missions, or notes. Permissions must be written on every create/upsert, so the
gateway centralises them in `_permissionsFor` and the invite Function.

---

## 9. AI through Gemini + Appwrite Function, with a review gate

**Context:** The brief requires a free provider, backend-only keys, a per-user
rate limit, and manual fallback.

**Decision:** `parse-reminder` calls Gemini with a plain JSON prompt, trying
`gemini-3.6-flash` and falling back to `gemini-3.5-flash` when a model is
capacity-limited. The Gemini key is an Appwrite Function variable. The
`rate_limits` table enforces 30 requests per user per day, keyed by a
deterministic hash of user/action/window. The app only ever stores a *reviewed*
draft. Demo mode uses `HeuristicNaturalParser` and never calls the network.

**Consequences:** Switching providers means changing one function, not the app.
If Gemini is down, the UI offers manual entry. Quota state is per project, not per
device, and survives reinstall.

---

## 10. Geocoding is proxied and cached

**Context:** Nominatim’s usage policy forbids heavy direct client traffic and
requires an identifying user agent.

**Decision:** The `geocode` Function proxies search/reverse, sets a real
User-Agent, serialises upstream calls per instance, enforces 60 requests/hour/user,
and caches results in the `geocode_cache` table for 30/90 days. The app never
calls Nominatim.

**Consequences:** Search still works if a user briefly exceeds the limit thanks to
cache hits. The public OSM tiles are loaded directly by `flutter_map`; a
high-traffic deployment should switch to a commercial tile provider.

---

## 11. Demo mode is a first-class path

**Context:** Reviewers and new users should see the product before joining a
shared Appwrite instance.

**Decision:** If the endpoint or project ID is absent, DI injects
`DemoCloudGateway` and `AuthRepositoryImpl(client: null)`. Demo data is seeded
locally, labelled in the UI, and discarded when a cloud account signs in. Search
uses a curated list, AI uses the heuristic parser.

**Consequences:** No fake network calls or hidden keys. Two code paths exist for
auth/cloud, but both share every repository and bloc.

---

## 12. Localization as a Dart dictionary

**Context:** The app only supports Indonesian and English, and tests need
translated strings without code generation.

**Decision:** Keep a single `AppLocalizations` class exposing `t(id, en)` getters.
Locale is stored in `AppSettings`.

**Consequences:** Compile-time safety and no ARB pipeline. Adding a third language
would mean touching every getter; the trade-off is acceptable for two locales.

---

## 13. Feature-first blocs + get_it + go_router

**Context:** The existing `dompetektif` codebase uses event/state blocs, feature
folders, and a composition root.

**Decision:** Mirror that architecture: domain interfaces, data implementations,
use cases, blocs per screen, and `getIt` factories for parameterized forms.
`go_router` owns auth, onboarding, invite, and shell redirects.

**Consequences:** Predictable structure and easy mocking. Parameterized blocs
(`PlaceFormBloc`, `MissionFormBloc`, `TitipanFormBloc`, `InviteBloc`) are
registered with `registerFactoryParam`.

---

## 14. Web is a management surface, not a fake geofence client

**Context:** Browsers cannot run reliable background geofences.

**Decision:** Hide location triggers on web and explain the limitation on Home,
Missions, Permissions, and Settings. Places, Missions, Titipan, Natural input, and
history remain available.

**Consequences:** Honest product behavior, no misleading “active” badges. The same
web build is the share target for invitation links.

---

## 15. Invitations survive the sign-in detour

**Context:** A recipient often opens an invite while signed out.

**Decision:** The router remembers the token in `InviteIntent` before redirecting
to auth, then consumes it once a session exists. `AppShell` also listens to live
deep links.

**Consequences:** One extra static holder, but no token lost during onboarding.
The token is cleared after use to avoid redirect loops.

---

## 16. Test the decisions, not the pixels

**Context:** Geofence, sync, and privacy rules are where bugs hurt.

**Decision:** Put pure logic behind small classes (`MissionEvaluator`,
`GeofencePlanner`, `ConflictResolver`, `TitipanVisibility`,
`NaturalDraft.fromAiJson`) and enforce 80% line coverage per core file and in
aggregate. Widget tests cover the three primary flows; bloc tests use mocks.

**Consequences:** Fast, deterministic tests with no platform channels. Rendering
regressions are caught by a small number of focused widget tests rather than
goldens.

---

## 17. Notifications have two delivery paths, intentionally

**Context:** A place transition can fire while the app is closed, and a new
Titipan can arrive while the app is open.

**Decision:** The Kotlin receiver posts place notifications and queues history.
`TitipanNotificationCoordinator` posts realtime inbox notifications and de-dupes
with a per-note local flag. `flutter_local_notifications` owns channels.

**Consequences:** No duplicate place notifications, and realtime notes still get
seen. If the notification permission is denied, history is still recorded.

---

## 18. Release signing is optional in CI

**Context:** Contributors should be able to build a release APK without owning the
production key.

**Decision:** `android/key.properties` enables a real release keystore. When it is
absent, Gradle falls back to debug signing. CD writes the file from GitHub Secrets
when `ANDROID_KEYSTORE_BASE64` is present.

**Consequences:** Local release builds work out of the box; production releases can
be properly signed without committing secrets.

---

## 19. Remote push goes through Appwrite Messaging

**Context:** A Titipan should reach the recipient's devices, including when the
app is closed, without putting Firebase credentials or a server key in the client.

**Decision:** The client registers its FCM token as an Appwrite push target
(`account.createPushTarget`) after sign-in and deletes it on sign-out. The
`notify-titipan` Function subscribes to `titipan_recipients` create events and
sends the push with the sender, title, and Place through the Appwrite Messaging
FCM provider. Provider credentials stay in Appwrite; the app only carries the
public Firebase values and the provider ID.

**Consequences:** Delivery works on the emulator and a physical device over FCM.
Push failures are swallowed so invite acceptance never breaks. A deployment
without a provider simply skips remote push and keeps local notifications.

---

## 20. Design tokens and one widget vocabulary

**Context:** The app has many small surfaces and must feel consistent on phone and
web.

**Decision:** Centralize colors, radii, and spacing in `app_theme.dart`; share
`AppCard`, `PageHeader`, `EmptyState`, `ToneChip`, `MetricTile`, etc. in
`app_surfaces.dart`. Status chips always pair color with text.

**Consequences:** New screens compose existing primitives. Theme changes are
one-file. Widget tests can assert shared state widgets directly.

---

## 21. Search and AI are optional, never blocking

**Context:** A reminder must still be creatable when the network or a provider is
down.

**Decision:** Both `parse-reminder` and `geocode` failures degrade to a manual
flow. Place creation accepts a map point without a reverse-geocoded address.
Natural input offers “Isi manual” and keeps the sentence intact.

**Consequences:** Slightly more UI states, but no dead ends. Error copy is specific
(rate limit vs unavailable vs no place) so users know what to do next.

---

## 22. One self-hosted Appwrite instance, one project per app

**Context:** Singgah needed auth, tables, realtime, storage, and server functions without per-project Supabase limits or Firebase Blaze billing. More apps (a portfolio, future products) need the same capabilities.

**Decision:** Run a single Appwrite instance with Docker on the developer's own machine or server. The instance lives outside every app repository and is intentionally not named after Singgah. Each app gets its own Appwrite **project** (`Singgah`, `Portfolio`, and so on) so users, keys, tables, and quotas stay isolated. The Singgah repo keeps only `APPWRITE_ENDPOINT`, `APPWRITE_PROJECT_ID`, `appwrite.config.json`, and the Function sources.

**Consequences:** One stack to patch and back up; new apps are a project plus a config file. A self-hosted instance is a single point of failure and needs its own backups, TLS, and upgrades, which are documented in the infrastructure repo rather than here. Admin credentials and API keys never enter the app repo.



---

## 23. Native sessions use an explicit session header

**Context:** Appwrite marks its modern session cookie `SameSite=None` and only adds
`Secure` when the request arrived over HTTPS. The Dart cookie jar used by the
Flutter SDK rejects a `SameSite=None` cookie that lacks `Secure`, and the rejection
aborts the whole `Set-Cookie` batch. On an HTTP development endpoint the session
was therefore created but never sent back, so the next `account.get()` returned
401.

**Decision:** On native builds the app creates the session over HTTP directly,
reads the session token from `Set-Cookie`, and passes it through
`Client.setSession` (`X-Appwrite-Session`). The token is kept in local metadata so
a restart restores the session. Web builds keep using the browser cookie flow.

**Consequences:** Local HTTP development works on the Android emulator without a
certificate. A production deployment should still expose Appwrite over HTTPS so
cookies carry `Secure` and the fallback becomes unnecessary. The fallback is
isolated in `AuthRepositoryImpl._createSession` and `_restoreSession`.

---

## 24. Friends and groups are server-mediated

**Context:** Sending a Titipan to a known person should not require copying an invitation link, but a client must not be able to enumerate accounts or grant itself access to a stranger's note.

**Decision:** Friendships are requested by email through the `social` Function: it resolves the account with a server key, stores a `friendships` row readable by both parties, and only the addressee can accept or delete it. Groups are owner-managed rows with a `member_ids` array; the owner and each member receive row read permission. `send-titipan` validates that every selected friend is accepted and every group includes the caller, upserts the note with read permission for all recipients, and creates the recipient rows. Those rows trigger `notify-titipan`, so the push path is identical to the invite flow.

**Consequences:** No client-side account lookup and no way to add a recipient without consent. The trade-off is three new Functions and two tables, plus a `groups` row that must be re-permissioned whenever membership changes. Direct sends and invite links coexist: a note can be both shared by link and delivered to friends.

---

## 25. Chat is conversation-scoped and server-validated

**Context:** Friends and groups need a message window that feels live, but a client must not be able to post into a conversation it does not belong to.

**Decision:** The `chat` Function derives membership from the friendship or group record and creates the message with read permission for every participant. 1:1 conversations use a deterministic FNV-1a id over the two user ids (`dm_…`), group conversations use `g_<groupId>`. The client subscribes to the `messages` table over Appwrite Realtime and reloads the thread on every event.

**Consequences:** Message history is protected by row permissions even if a conversation id leaks. The hash must stay identical in Dart and the Function; both use the same 32-bit FNV-1a loop. Group chat membership follows the current owner, co-admins, and members at send time.
