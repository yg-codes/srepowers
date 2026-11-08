# Shared writing rubric — reports and ticket drafts

Applies to human-facing prose: report bodies, ticket sections, summaries, Artifact text, and the comments inside code and config files. It governs the prose inside sections, not the section structure: producer-skill templates (section lists, appendices, Command & Query Log, checklists) stay as specified. Never apply it to code, queries, config values, commit messages, or verbatim appendices, and never to a commented-out block.

**Template-mandated formats are exempt.** Anything a template prescribes literally is out of the slop-check's reach: immutable section headers and their casing (e.g. tickets.md's "UAT Implementation", "Additional References"), prescribed label bullets (`- **Impact-contributing factors:**`), rating lines and their separators (`LOW — <explanation>` in AWS Cost Estimations), and checklist syntax (`- [ ] **Step N.**`). The rubric rewrites the sentences an author chose, never the scaffolding a template mandates.

## The recipe (what good output IS)

1. **Lead with the outcome.** The first sentence of any section states what is true, what happened, or what will be done. Context and framing come after, if at all.
2. **Plain sentences.** Use is/are/has/does. One idea per sentence. Mixed lengths: some short, some longer.
3. **Specifics over description.** Exact account names + IDs, resource IDs, counts, error strings, dates with timezone. "3 route tables in `<account-name>` (`<account-id>`)" beats "the relevant routing infrastructure". Specifics must be real: never invent a count, ID, or name to sound concrete — if a value is unknown, say it is unknown or look it up.
4. **Detail goes to the end.** Explanations that help understanding but are not needed to act move out of the main flow — not inline parentheticals, asides, or "this is because..." sentences woven through the main sections. Where they go depends on the format: in a free-form report, one `Notes` (or `Details`) section near the end; in a ticket whose template headers are immutable, an existing references section or a short paragraph at the end of the description. If a caveat changes what the reader must do, it stays inline; everything else moves.
5. **Stop when the information ends.** No recap sentence, no "in summary", no generic forward-looking closer.
6. **Counts are digits.** A count stated in a sentence is a digit: `3 route tables`, not `three route tables`. From 0 upward, sentence-initial included. `one` stays a word only as a pronoun or idiom (`one of the accounts`, `no one`). Ordinals stay words (`the third step`); numbered labels keep digits (`Step 3`).

## Soft budgets (guidance, not caps)

Exceed a budget only when cutting would change what the reader does next.

- Ticket **Description**: 2–4 plain sentences (plus the mandatory account/ID table or bullets when multiple accounts are affected).
- Ticket **Rationale**: 1–3 sentences. Name the driver (ticket, CI plan, incident, requirement) and stop.
- Ticket **Impact / Risk factors**: at most ~3 bullets per contributing/limiting list, one line each, no sub-explanations.
- Report **executive summary**: ≤5 bullets, each one finding or action.
- Any single paragraph: ≤4 sentences.

## Slop-check (adversarial pass)

After drafting, ask: **"What makes this read as AI-generated or padded?"** Check against:

- Rule-of-three lists and triple adjectives
- "not just X, but Y" / negative parallelisms
- Trailing clauses that restate or inflate the claim just made (", and that is the design", ", and it is an open one", ", and still is not", ", and that property is load-bearing"; also "X, not Y" where Y is either already excluded by X's own term, or already established earlier as the alternative being weighed, e.g. "correlational, not conclusive", "the leading hypothesis, not a ruled-out one"). Cut the clause or fold it into the sentence: "THEY GRANT NOTHING BY DESIGN", "That override is an open hole", "The evidence is correlational". Keep a trailing "not Y" only when Y is a fact the reader could not already derive and it changes what they do next, per recipe point 4 (worked examples and the two-part test: humanizer SKILL.md §9).
- "serves as / stands as / represents" instead of "is"
- Significance inflation ("pivotal", "crucial role", "underscores", "testament")
- Tacked-on "-ing" clauses ("...ensuring consistency", "...highlighting the need for")
- Hedging pile-ups ("it's worth noting", "arguably", "to some extent")
- AI vocabulary (delve, leverage, robust, seamless, comprehensive, landscape, foster, showcase, streamline)
- Coding-agent vocabulary in its AI-typical usage (figurative "load-bearing", "footgun", verb "surface", "fold into", abstract "shape", "push back", "honest take", "you're absolutely right" — humanizer §34; literal uses are fine)
- Paragraphs over ~4 sentences (split where the topic turns, or convert enumerations to bullets — humanizer §35)
- Bold-header bullet spam (`**Term:** explanation` chains standing in for prose)
- Em/en dashes (cut them all — humanizer §14; template-mandated separators exempt). **This is a literal character check, not a style judgment** — a holistic re-read misses it almost every time (recurred 3x: 2026-07-14, 2026-07-18 x2). Scan explicitly for the dash characters as its own pass, separate from the tone read-through, before considering the slop-check done.
- Inline explanatory asides that belong at the end (per recipe point 4), including explanatory parentheticals — "(i.e., ...)", "(this means ...)" — at more than about one per paragraph (humanizer §36)
- Closers that restate the section
- Vague attributions ("experts", "industry reports") and missing specifics
- Narrating an internal investigation that produced no number, where a citation answers the question directly

Revise and re-check, at most 2 iterations. If findings remain after the second pass, ship anyway and list the remaining findings for the user — do not keep polishing.

Full pattern catalog with before/after examples: the humanizer skill (`$HOME/.claude/skills/humanizer/SKILL.md`).
