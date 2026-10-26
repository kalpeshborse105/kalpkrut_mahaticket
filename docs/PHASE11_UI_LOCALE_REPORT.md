# PHASE 11 — Light UI, Locale Separation, TicketGhar Mobile Parity

**Date:** 2026-10-26  
**Project:** `kalpkrut_mahaticket`  
**Reference:** `ticketghar/mobile`

## 1. Confirmed problems (pre-change)

| Issue | Evidence |
|---|---|
| Dark theme vs TicketGhar light mobile | `app_theme.dart` used slate/black |
| Dual EN+MR labels with brackets | Widespread e.g. `माझे प्रोफाईल (Profile Hub)`, card `title` + `titleMr` |
| Language toggle local-only | Profile `_selectedLanguage` did not drive app copy |
| Ticket pass still dark-oriented | White-on-dark QR container after theme flip regressions |
| Seat conflict strings bilingual at once | Hold messages showed MR + EN parentheses |

Working flows preserved: nested Explore nav, home_sections CMS, Razorpay verify path, group QR preference, scanner API, reviews/gallery.

## 2. Changed files (important)

| File | Change |
|---|---|
| `lib/core/theme/app_theme.dart` | Light theme (`#FAFAFA` / `#EA580C` / white cards) |
| `lib/providers/locale_provider.dart` | EN/MR toggle + persistence |
| `lib/core/l10n/app_strings.dart` | Single-language UI strings |
| `lib/main.dart` | Light theme + LocaleProvider |
| `lib/data/models/event_model.dart` | `displayTitle/Description/Category/Venue` |
| `lib/data/models/home_section_model.dart` | `localizedTitle` |
| `lib/views/customer/home_screen.dart` | Locale tabs/rails; light surfaces |
| `lib/views/customer/widgets/event_card.dart` | One title language |
| `lib/views/customer/ticket_view_screen.dart` | Light perforated pass + group QR note |
| `lib/views/customer/seat_matrix_screen.dart` | Locale legend/stage/conflicts; InteractiveViewer kept |
| `lib/views/customer/event_detail_screen.dart` | Single title + about copy |
| `lib/views/customer/profile_screen.dart` | Real language switch |
| `lib/providers/booking_provider.dart` | Conflict codes for localized UI |
| `lib/providers/events_provider.dart` | `sectionTitle(..., marathi:)` |

## 3. UI improvements

- Light theme tokens (TicketGhar-aligned orange `#EA580C`).
- Profile → मराठी **or** English (never both in one label).
- Home rails / cards / tickets / seat map / event detail use one language.
- Ticket pass: orange header, date/time/seats, perforation, white QR, share/home actions.
- Seat map: stage label localized; zoom/pan InteractiveViewer retained (0.5–2.8).

## 4. Database status

No production SQL run this phase. Event/venue/session counts **not re-queried**. No fabricated catalogue imports. Scrapers untouched for live publish.

## 5. Seat-map status

Uses existing `seats` + `seat_inventory` for selected session. Zoom/pan via `InteractiveViewer`. Device pinch test: **not live-run this pass** (analyzer/unit only).

## 6. Admin status

Home Sections CMS from prior phase unchanged. No new event import feed (blocked without authorized source — rule 8).

## 7. Test results

| Check | Status |
|---|---|
| `flutter analyze` | No errors (minor `unnecessary_const` infos) |
| `flutter test` | **25 passed** |
| `flutter build web --release` | Not re-run this phase (prior PASS) |
| `flutter build apk --release` | Rebuild recommended after UI pass |

## 8. Remaining blockers

- Full bilingual sweep of **admin** screens still has some dual labels.
- Authorized live event feed for 25/50 catalogue targets not available → do not invent events.
- Live Razorpay test payment + Android pinch seat-map on device still required.
- PDF/email ticket attachment not wired in this UI pass.

## 9. Release recommendation

**Internal / closed testing** after `flutter build apk --release` and a device smoke of: language toggle, explore rails, seat hold conflict, test payment → group QR, gate scan. **Not production-complete** until live payment + device seat-map + remaining bilingual admin cleanup are signed off.
