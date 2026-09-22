# Tennis IQ question audit

All 1,584 entries were reviewed across the question, four choices, answer key and explanation. Bank version 7 contains 518 corrected entries, 1,046 entries verified without changes, and 20 contextual coaching entries. No factual items remain marked unresolved in the final ledger. This is a sourced review, not a guarantee of infallibility; contextual tactics are recommendations whose success depends on the player and situation.

## Changes

- Rewrote 232 negative winner questions that originally admitted multiple correct answers.
- Fixed seven reverse-year questions with multiple valid choices.
- Corrected 54 generated historical surface/location entries and explanations.
- Made 83 title-count questions explicit about era and cutoff; recomputed their totals from official champion tables, including the two Australian Opens in 1977.
- Corrected historical records, doubles achievements, rule exceptions, terminology and unsupported explanatory claims.
- Narrowed time-sensitive records and tour-format claims to named seasons or historical cutoffs.

The 518 changed entries include factual repairs, ambiguity fixes and explanation improvements; they are not 518 wrong answer keys. Changes affect 398 question texts, 34 choice arrays, 264 answer indices and 477 explanations, with overlap. Most answer-index changes belong to the rewritten negative-question family.

Both the web and native banks contain the same corrected data. The web service-worker cache version was increased so a future deployment can replace cached questions. Nothing was published by this audit.

## Evidence and method

The [final ledger](audit/final-ledger.json) records a source, verdict and rationale for every ID. The [change log](audit/changes.json) preserves exact before/after fields. The [original bank](audit/original-bank.json) is retained for comparison. Detailed review reports are in this directory; source extracts are in `audit-sources/`.

Rules were checked against the [2026 ITF Rules of Tennis](https://www.itftennis.com/media/7221/2026-rules-of-tennis-english.pdf) and USTA Friend at Court. Historical records use official ATP, WTA, tournament, ITF, Olympic and tennis-history institutional sources, linked individually in the ledger. Terminology uses governing-body glossaries and specialist sources; coaching heuristics retain their contextual status rather than being presented as guaranteed outcomes.

Generated champion questions were checked against official tables. Counts, reverse-year choices and negative-family replacements received additional programmatic checks. All 73 generated scoring cases were independently calculated. Manual questions received individual reviews, with a second pass on ambiguous terminology, tactics and correction compatibility.

## Verification

- Four Node validation tests pass: native/web parity and audit hash; valid IDs, choices, answer indices and complete sourced coverage; repaired negative family; exact correspondence with reviewed corrections.
- Native Swift model successfully decodes all 1,584 questions at version 7.
- Xcode iOS simulator build succeeds.
- The question file inside the built app is byte-identical to the audited bank.
- `git diff --check` passes.

These checks establish artifact integrity and build compatibility; they are not an automated proof of every historical fact. Re-audit date-sensitive content before extending its cutoff. Run the app again in Xcode to load the rebuilt bank.
