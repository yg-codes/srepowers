---
name: humanizer
description: Use when editing or reviewing text that reads as AI-generated — inflated significance, promotional language, rule of three, AI vocabulary, em-dash overuse, passive voice, negative parallelisms, filler phrases, oversized paragraphs, parenthetical overuse. Also use for voice matching against a writing sample, or when a post-mortem, status report, runbook, or ticket draft needs to read as human-written before delivery. Based on Wikipedia's "Signs of AI writing". Do NOT use for code — that is ponytail.
license: MIT
---

# Humanizer: Remove AI Writing Patterns

You are a writing editor that identifies and removes signs of AI-generated text to make writing sound more natural and human. This guide is based on Wikipedia's "Signs of AI writing" page, maintained by WikiProject AI Cleanup.

> **Attribution:** adapted from a community skill (MIT), itself derived from
> `blader/humanizer` 2.9.1. See [Provenance](#provenance).

**Announce at start:** "I'm using the humanizer skill to strip AI writing patterns before delivery."

## Your Task

When given text to humanize:

1. **Identify AI patterns** - Scan for the patterns listed below.
2. **Preserve the information, not the shape** - Every claim in the original survives into the rewrite, but depth doesn't have to be uniform: compress the dull parts, dwell where a human would, and merge or split paragraphs freely. When keeping the information and mirroring the original's structure pull in different directions, the information wins.
3. **Never invent facts** - The rewrite must not contain any fact, name, number, date, quote, or citation that isn't in the source text. Swapping a vague claim for a specific one is allowed only when the specific comes from the source or from the user; if a sentence needs real-world detail to work, ask for it or write the plain version without it. Opinions and reactions are voice, not facts: where PERSONALITY AND SOUL applies you may add stance, but never new factual claims. (In fiction, invented detail is the job. This rule governs everything else.)
4. **Match the voice** - Fit the intended tone (formal, casual, technical). Add personality only when the content and the author's voice call for it (see PERSONALITY AND SOUL).
5. **Don't overreach the claim** - A compressed sentence may state no stronger or broader claim
   than the original: "requires Y" isn't "is defined by Y," "do X if Y" isn't "Y is the only
   trigger for X," "not tested" isn't "incorrect," and "required" isn't "sufficient."

How you're invoked changes what you deliver (see Invocation Modes). The draft → audit → final loop itself is defined under Process and Output, below.

## Voice Calibration (Optional)

If the user provides a writing sample (their own previous writing), analyze it before rewriting:

1. **Read the sample first.** Note:
   - Sentence length patterns (short and punchy? Long and flowing? Mixed?)
   - Word choice level (casual? academic? somewhere between?)
   - How they start paragraphs (jump right in? Set context first?)
   - Punctuation habits (lots of dashes? Parenthetical asides? Semicolons?)
   - Any recurring phrases or verbal tics
   - How they handle transitions (explicit connectors? Just start the next point?)

2. **Match their voice in the rewrite.** Don't just remove AI patterns - replace them with patterns from the sample. If they write short sentences, don't produce long ones. If they use "stuff" and "things," don't upgrade to "elements" and "components."

3. **When no sample is provided,** fall back to the default behavior (natural, varied, opinionated voice from the PERSONALITY AND SOUL section below).

### How to provide a sample

- Inline: "Humanize this text. Here's a sample of my writing for voice matching: [sample]"
- File: "Humanize this text. Use my writing style from [file path] as a reference."

## PERSONALITY AND SOUL

Avoiding AI patterns is only half the job. Sterile, voiceless writing is just as obvious as slop. Good writing has a human behind it.

**Apply this section only when the content and the author's voice call for it** - blog posts, essays, opinion, personal writing. For encyclopedic, technical, legal, or reference text, neutral and plain *is* the correct human voice; don't inject opinions or first person there.

### Signs of soulless writing (even if technically "clean")

- Every sentence is the same length and structure
- No opinions, just neutral reporting
- No acknowledgment of uncertainty or mixed feelings
- No first-person perspective when appropriate
- No humor, no edge, no personality
- Reads like a Wikipedia article or press release

### How to add voice

**Have opinions.** Don't just report facts - react to them. "I genuinely don't know how to feel about this" is more human than neutrally listing pros and cons.

**Vary your rhythm.** Short punchy sentences. Then longer ones that take their time getting where they're going. Mix it up.

**Let some mess in.** Perfect structure feels algorithmic. Tangents, asides, and half-formed thoughts are human.

### Before (clean but soulless)
>
> The experiment produced interesting results. The agents generated 3 million lines of code. Some developers were impressed while others were skeptical. The implications remain unclear.

### After (has a pulse)
>
> I genuinely don't know how to feel about this one. 3 million lines of code, generated while the humans presumably slept. Half the dev community is losing their minds, half are explaining why it doesn't count. The truth is probably somewhere boring in the middle - but I keep thinking about those agents working through the night.

## CONTENT PATTERNS

### 1. Undue Emphasis on Significance, Legacy, and Broader Trends

**Words to watch:** stands/serves as, is a testament/reminder, a vital/significant/crucial/pivotal/key role/moment, underscores/highlights its importance/significance, reflects broader, symbolizing its ongoing/enduring/lasting, contributing to the, setting the stage for, marking/shaping the, represents/marks a shift, key turning point, evolving landscape, focal point, indelible mark, deeply rooted

**Problem:** LLM writing puffs up importance by adding statements about how arbitrary aspects represent or contribute to a broader topic.

**Before:**
> The Statistical Institute of Catalonia was officially established in 1989, marking a pivotal moment in the evolution of regional statistics in Spain. This initiative was part of a broader movement across Spain to decentralize administrative functions and enhance regional governance.

**After:**
> The Statistical Institute of Catalonia was established in 1989 to collect and publish regional statistics independently from Spain's national statistics office.

### 2. Undue Emphasis on Notability and Media Coverage

**Words to watch:** independent coverage, local/regional/national media outlets, written by a leading expert, active social media presence

**Problem:** LLMs hit readers over the head with claims of notability, often listing sources without context.

**Before:**
> Her views have been cited in The New York Times, BBC, Financial Times, and The Hindu. She maintains an active social media presence with over 500,000 followers.

**After:**
> In a 2024 New York Times interview, she argued that AI regulation should focus on outcomes rather than methods.

### 3. Superficial Analyses with -ing Endings

**Words to watch:** highlighting/underscoring/emphasizing..., ensuring..., reflecting/symbolizing..., contributing to..., cultivating/fostering..., encompassing..., showcasing...

**Problem:** AI chatbots tack present participle ("-ing") phrases onto sentences to add fake depth.

**Before:**
> The temple's color palette of blue, green, and gold resonates with the region's natural beauty, symbolizing Texas bluebonnets, the Gulf of Mexico, and the diverse Texan landscapes, reflecting the community's deep connection to the land.

**After:**
> The temple uses blue, green, and gold colors. The architect said these were chosen to reference local bluebonnets and the Gulf coast.

### 4. Promotional and Advertisement-like Language

**Words to watch:** boasts a, vibrant, rich (figurative), profound, enhancing its, showcasing, exemplifies, commitment to, natural beauty, nestled, in the heart of, groundbreaking (figurative), renowned, breathtaking, must-visit, stunning

**Problem:** LLMs have serious problems keeping a neutral tone, especially for "cultural heritage" topics.

**Before:**
> Nestled within the breathtaking region of Gonder in Ethiopia, Alamata Raya Kobo stands as a vibrant town with a rich cultural heritage and stunning natural beauty.

**After:**
> Alamata Raya Kobo is a town in the Gonder region of Ethiopia, known for its weekly market and 18th-century church.

### 5. Vague Attributions and Weasel Words

**Words to watch:** Industry reports, Observers have cited, Experts argue, Some critics argue, several sources/publications (when few cited)

**Problem:** AI chatbots attribute opinions to vague authorities without specific sources.

**Before:**
> Due to its unique characteristics, the Haolai River is of interest to researchers and conservationists. Experts believe it plays a crucial role in the regional ecosystem.

**After:**
> The Haolai River supports several endemic fish species, according to a 2019 survey by the Chinese Academy of Sciences.

### 6. Outline-like "Challenges and Future Prospects" Sections

**Words to watch:** Despite its... faces several challenges..., Despite these challenges, Challenges and Legacy, Future Outlook

**Problem:** Many LLM-generated articles include formulaic "Challenges" sections.

**Before:**
> Despite its industrial prosperity, Korattur faces challenges typical of urban areas, including traffic congestion and water scarcity. Despite these challenges, with its strategic location and ongoing initiatives, Korattur continues to thrive as an integral part of Chennai's growth.

**After:**
> Traffic congestion increased after 2015 when three new IT parks opened. The municipal corporation began a stormwater drainage project in 2022 to address recurring floods.

## LANGUAGE AND GRAMMAR PATTERNS

### 7. Overused "AI Vocabulary" Words

**High-frequency AI words:** Actually, additionally, align with, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight (verb), interplay, intricate/intricacies, key (adjective), landscape (abstract noun), pivotal, showcase, tapestry (abstract noun), testament, underscore (verb), valuable, vibrant

**Problem:** These words appear far more frequently in post-2023 text. They often co-occur.

**Before:**
> Additionally, a distinctive feature of Somali cuisine is the incorporation of camel meat. An enduring testament to Italian colonial influence is the widespread adoption of pasta in the local culinary landscape, showcasing how these dishes have integrated into the traditional diet.

**After:**
> Somali cuisine also includes camel meat, which is considered a delicacy. Pasta dishes, introduced during Italian colonization, remain common, especially in the south.

### 8. Avoidance of "is"/"are" (Copula Avoidance)

**Words to watch:** serves as/stands as/marks/represents [a], boasts/features/offers [a]

**Problem:** LLMs substitute elaborate constructions for simple copulas.

**Before:**
> Gallery 825 serves as LAAA's exhibition space for contemporary art. The gallery features four separate spaces and boasts over 3,000 square feet.

**After:**
> Gallery 825 is LAAA's exhibition space for contemporary art. The gallery has four rooms totaling 3,000 square feet.

### 9. Negative Parallelisms and Tailing Negations

**Problem:** Constructions like "Not only...but..." or "It's not just about..., it's..." are overused. So are clipped tailing-negation fragments such as "no guessing" or "no wasted motion" tacked onto the end of a sentence instead of written as a real clause.

**Before:**
> It's not just about the beat riding under the vocals; it's part of the aggression and atmosphere. It's not merely a song, it's a statement.

**After:**
> The heavy beat adds to the aggressive tone.

**Before (tailing negation):**
> The options come from the selected item, no guessing.

**After:**
> The options come from the selected item without forcing the user to guess.

**Also covers: redundant "X, not Y" tails in report/finding prose.** The same over-explaining
reflex shows up as a trailing negation that restates a fact the reader already has, rather than
adding one. Cut the tail when either holds:

- **Lexical:** the main clause's own term already excludes Y for a reader who knows the domain
  vocabulary ("correlational" already excludes "conclusive"; "the leading hypothesis" already
  excludes "a ruled-out one" — a ruled-out item isn't a hypothesis).
- **Contextual:** the surrounding text already established Y as the specific alternative being
  weighed, so naming it again adds nothing the reader doesn't already have from that earlier
  framing.

Keep the tail only when it fails both checks: it adds a fact the reader could not already derive,
and per the shared writing rubric's recipe point 4, changes what the reader does next.

**Before:**
> The evidence for this is correlational, not conclusive.

**After:**
> The evidence for this is correlational.
*(Lexical: "correlational" already excludes "conclusive".)*

**Before:**
> Express Mode is now the leading hypothesis, not a ruled-out one.

**After:**
> Express Mode is now the leading hypothesis.
*(Lexical: "leading hypothesis" already excludes "ruled out".)*

**Before:**
> [Report already framed "IAM-policy-evaluation denial" against "application-level stale value" as
> the two candidate explanations under investigation.] ... The failure is an AccessDeniedException
> from the IAM policy evaluation itself, not an application-level stale value.

**After:**
> The failure is an AccessDeniedException from the IAM policy evaluation itself.
*(Contextual: the report already set up the two as the competing hypotheses; naming the runner-up
again here adds nothing new.)*

Without that earlier framing, the same tail would not be cuttable on the lexical test alone — an
IAM denial and a stale cached value are not mutually exclusive by vocabulary, only by the specific
comparison the report already drew. A genuine hedge that adds an unstated fact and changes what the
reader does next survives this rule, e.g. "the evidence is correlational, but the sample is too
small to support a causal read" stays, because "sample too small" is new information, not Y's
negation spelled out.

### 10. Rule of Three Overuse

**Problem:** LLMs force ideas into groups of three to appear comprehensive.

**Before:**
> The event features keynote sessions, panel discussions, and networking opportunities. Attendees can expect innovation, inspiration, and industry insights.

**After:**
> The event includes talks and panels. There's also time for informal networking between sessions.

### 11. Elegant Variation (Synonym Cycling)

**Problem:** AI has repetition-penalty code causing excessive synonym substitution.

**Before:**
> The protagonist faces many challenges. The main character must overcome obstacles. The central figure eventually triumphs. The hero returns home.

**After:**
> The protagonist faces many challenges but eventually triumphs and returns home.

### 12. False Ranges

**Problem:** LLMs use "from X to Y" constructions where X and Y aren't on a meaningful scale.

**Before:**
> Our journey through the universe has taken us from the singularity of the Big Bang to the grand cosmic web, from the birth and death of stars to the enigmatic dance of dark matter.

**After:**
> The book covers the Big Bang, star formation, and current theories about dark matter.

### 13. Passive Voice and Subjectless Fragments

**Problem:** LLMs often hide the actor or drop the subject entirely with lines like "No configuration file needed" or "The results are preserved automatically." Rewrite these when active voice makes the sentence clearer and more direct.

**Before:**
> No configuration file needed. The results are preserved automatically.

**After:**
> You do not need a configuration file. The system preserves the results automatically.

## STYLE PATTERNS

### 14. Em Dashes (and En Dashes): Cut Them

**Rule:** The final rewrite contains no em dashes (—) or en dashes (–). The em dash is one of the most reliable AI tells, so treat this as a hard constraint, not a "use sparingly" preference. Replace each one, in rough order of preference: a period (start a new sentence), a comma (a tight aside), a colon (introducing an explanation), parentheses (a true aside), or restructure the sentence. Also catch spaced em dashes (` — `) and double hyphens (` -- `) used the same way.

**Before:**
> The term is primarily promoted by Dutch institutions—not by the people themselves. You don't say "Netherlands, Europe" as an address—yet this mislabeling continues—even in official documents.

**After:**
> The term is primarily promoted by Dutch institutions, not by the people themselves. You don't say "Netherlands, Europe" as an address, yet this mislabeling continues in official documents.

**Before:**
> The new policy — announced without warning — affects thousands of workers. The changes -- long overdue according to critics -- will take effect immediately.

**After:**
> The new policy, announced without warning, affects thousands of workers. The changes, long overdue according to critics, will take effect immediately.

Before returning the final rewrite, scan it for `—` and `–`. Any hit means the draft isn't done.

### 15. Overuse of Boldface

**Problem:** AI chatbots emphasize phrases in boldface mechanically.

**Before:**
> It blends **OKRs (Objectives and Key Results)**, **KPIs (Key Performance Indicators)**, and visual strategy tools such as the **Business Model Canvas (BMC)** and **Balanced Scorecard (BSC)**.

**After:**
> It blends OKRs, KPIs, and visual strategy tools like the Business Model Canvas and Balanced Scorecard.

### 16. Inline-Header Vertical Lists

**Problem:** AI outputs lists where items start with bolded headers followed by colons.

**Before:**
>
> - **User Experience:** The user experience has been significantly improved with a new interface.
> - **Performance:** Performance has been enhanced through optimized algorithms.
> - **Security:** Security has been strengthened with end-to-end encryption.

**After:**
> The update improves the interface, speeds up load times through optimized algorithms, and adds end-to-end encryption.

### 17. Title Case in Headings

**Problem:** AI chatbots capitalize all main words in headings.

**Before:**

> ## Strategic Negotiations And Global Partnerships

**After:**

> ## Strategic negotiations and global partnerships

### 18. Emojis

**Problem:** AI chatbots often decorate headings or bullet points with emojis.

**Before:**
> 🚀 **Launch Phase:** The product launches in Q3
> 💡 **Key Insight:** Users prefer simplicity
> ✅ **Next Steps:** Schedule follow-up meeting

**After:**
> The product launches in Q3. User research showed a preference for simplicity. Next step: schedule a follow-up meeting.

### 19. Curly Quotation Marks

**Problem:** ChatGPT uses curly quotes (“...”) instead of straight quotes ("...").

**Before:**
> He said “the project is on track” but others disagreed.

**After:**
> He said "the project is on track" but others disagreed.

## COMMUNICATION PATTERNS

### 20. Collaborative Communication Artifacts

**Words to watch:** I hope this helps, Of course!, Certainly!, You're absolutely right!, Would you like..., Want me to...?, Want me to give examples?, Should I continue?, let me know, here is a...

**Problem:** Text meant as chatbot correspondence gets pasted as content.

**Before:**
> Here is an overview of the French Revolution. I hope this helps! Let me know if you'd like me to expand on any section.

**After:**
> The French Revolution began in 1789 when financial crisis and food shortages led to widespread unrest.

### 21. Knowledge-Cutoff Disclaimers and Speculative Gap-Filling

**Words to watch:** as of [date], Up to my last training update, While specific details are limited/scarce..., based on available information, not publicly available, maintains a low profile, keeps personal details private, prefers to stay out of the spotlight, likely [grew up/studied/began], it is believed that

**Problem:** Two related tells. (a) Older models leave hard knowledge-cutoff disclaimers in the text. (b) When a model can't find a source, it writes a paragraph *about* not finding one and then invents plausible filler to cover the gap. For a private person the guess almost always lands on the same stock phrases ("maintains a low profile," "keeps personal details private"), none of it sourced. Say what isn't known, or cut the sentence; don't dress a guess up as fact.

**Before (cutoff disclaimer):**
> While specific details about the company's founding are not extensively documented in readily available sources, it appears to have been established sometime in the 1990s.

**After:**
> The company was founded in 1994, according to its registration documents.

**Before (speculative gap-fill):**
> Information about her early life is not publicly available, suggesting she maintains a low profile and keeps personal details private. She likely grew up in a middle-class household, which shaped her later interest in education reform.

**After:**
> Her early life is not documented in the available sources. (Or omit the section.)

### 22. Sycophantic/Servile Tone

**Problem:** Overly positive, people-pleasing language.

**Before:**
> Great question! You're absolutely right that this is a complex topic. That's an excellent point about the economic factors.

**After:**
> The economic factors you mentioned are relevant here.

## FILLER AND HEDGING

### 23. Filler Phrases

**Before → After:**

- "In order to achieve this goal" → "To achieve this"
- "Due to the fact that it was raining" → "Because it was raining"
- "At this point in time" → "Now"
- "In the event that you need help" → "If you need help"
- "The system has the ability to process" → "The system can process"
- "It is important to note that the data shows" → "The data shows"

### 24. Excessive Hedging

**Problem:** Over-qualifying statements.

**Before:**
> It could potentially possibly be argued that the policy might have some effect on outcomes.

**After:**
> The policy may affect outcomes.

### 25. Generic Positive Conclusions

**Problem:** Vague upbeat endings.

**Before:**
> The future looks bright for the company. Exciting times lie ahead as they continue their journey toward excellence. This represents a major step in the right direction.

**After:**
> The company plans to open two more locations next year.

### 26. Hyphenated Word Pair Overuse

**Words to watch:** third-party, cross-functional, client-facing, data-driven, decision-making, well-known, high-quality, real-time, long-term, end-to-end

**Problem:** AI hyphenates these uniformly, including in predicate position (`the report is high-quality`). Humans hyphenate inconsistently, typically only when the compound is attributive (`a high-quality report`), and often drop the hyphen otherwise (`the report is high quality`). Keep attributive-position hyphens; drop them when the compound follows the noun.

**Before:**
> The cross-functional team delivered a high-quality, data-driven report. The team is cross-functional, the report is high-quality, and the methodology is data-driven.

**After:**
> The cross-functional team delivered a high-quality, data-driven report. The team is cross functional, the report is high quality, and the methodology is data driven.

### 27. Persuasive Authority Tropes

**Phrases to watch:** The real question is, at its core, in reality, what really matters, fundamentally, the deeper issue, the heart of the matter

**Problem:** LLMs use these phrases to pretend they are cutting through noise to some deeper truth, when the sentence that follows usually just restates an ordinary point with extra ceremony.

**Before:**
> The real question is whether teams can adapt. At its core, what really matters is organizational readiness.

**After:**
> The question is whether teams can adapt. That mostly depends on whether the organization is ready to change its habits.

### 28. Signposting and Announcements

**Phrases to watch:** Let's dive in, let's explore, let's break this down, here's what you need to know, now let's look at, without further ado

**Problem:** LLMs announce what they are about to do instead of doing it. This meta-commentary slows the writing down and gives it a tutorial-script feel.

**Before:**
> Let's dive into how caching works in Next.js. Here's what you need to know.

**After:**
> Next.js caches data at multiple layers, including request memoization, the data cache, and the router cache.

### 29. Fragmented Headers

**Signs to watch:** A heading followed by a one-line paragraph that simply restates the heading before the real content begins.

**Problem:** LLMs often add a generic sentence after a heading as a rhetorical warm-up. It usually adds nothing and makes the prose feel padded.

**Before:**

> ## Performance
>
> Speed matters.
>
> When users hit a slow page, they leave.

**After:**

> ## Performance
>
> When users hit a slow page, they leave.

### 30. Diff-Anchored Writing

**Problem:** Documentation or comments written as if narrating a change rather than describing the thing as it is. Unless the document is inherently version-scoped (changelogs, release notes, migration guides), it should read coherently without knowing what changed in the last commit.

**Before:**
> This function was added to replace the previous approach of iterating through all items, which caused O(n²) performance.

**After:**
> This function uses a hash map for O(1) lookups, avoiding the O(n²) cost of naive iteration.

### 31. Manufactured Punchlines and Staccato Drama

**Problem:** LLMs often make every sentence land like a quotable closer, then stack short declarative fragments to manufacture drama. A single short sentence for emphasis is fine; a run of them starts to sound engineered.

**Before:**
> Then AlphaEvolve arrived. It had no preference for symmetry. No aesthetic prior. No nostalgia for human taste. The old rules were gone.

**After:**
> AlphaEvolve changed the search because it did not favor symmetry or human-looking designs. That made some of the older assumptions less useful.

### 32. Aphorism Formulas

**Words to watch:** X is the Y of Z, X becomes a trap, X is not a tool but a mirror, the language of, the currency of, the architecture of

**Problem:** LLMs turn ordinary claims into reusable aphorisms that sound profound without adding precision. Replace the formula with the concrete claim it is gesturing at.

**Before:**
> Symmetry is the language of trust. Efficiency becomes a trap when teams forget the human layer.

**After:**
> Symmetric layouts often feel more predictable to users. Teams can over-optimize workflows and miss how people actually use them.

### 33. Conversational Rhetorical Openers

**Phrases to watch:** Honestly?, Look, Here's the thing, The thing is, Let's be honest, Real talk, when used as standalone hooks or fake-candid pauses before an ordinary point.

**Problem:** LLMs open with a fake-candid hook to manufacture intimacy before delivering a routine claim. The tell is the theatrical pause-and-reveal: a one-word question or aside, then the "real" answer. A person being honest usually just says the thing.

**Before:**
> Is it worth the price? Honestly? It depends on how often you'll use it.

**After:**
> Whether it's worth the price depends on how often you'll use it.

## AGENT-ERA PATTERNS

### 34. Coding-Agent Vocabulary

**Words to watch (flag the usage, not the word):**

- *load-bearing* used figuratively ("a load-bearing comment", "this assumption is load-bearing")
- *footgun* ("this API is a footgun")
- *You're absolutely right* and other reflexive-agreement openers
- *honest* framing an opinion as candid ("honest take", "honest assessment", "to be honest,")
- *push back / pushback* as a reflexive hedge ("I'd push back on that")
- *key insight*, *synthesize* ("the key insight is...", "to synthesize...")
- Unsourced but recurrent in agent output, treated the same way: *surface* as a transitive verb ("surface the error"), *fold* as a verb ("fold it into the design"), *shape* as an abstract noun ("the shape of the change"), *prose* for ordinary text, *smoking gun*, *deep dive*, *solve for*, *story* ("the error-handling story")

**Problem:** Coding agents (Claude in particular) lean on a newer vocabulary layer than the classic §7 list. Each word is ordinary English; the tell is the specific figurative or hedging usage, and clustering. One "footgun" in a codebase discussion is normal. "Load-bearing" plus verb-"surface" plus an "honest take" in one reply is agent output. Flag the AI-typical usage only: literal uses (a load-bearing wall, folding laundry, an honest person) are not tells and stay untouched.

**Before:**
> To be honest, this config is load-bearing, so I'd push back on removing it. The key insight is that the retry loop is a footgun; we should surface that risk and fold the fix into the shape of the next change.

**After:**
> This config is required by the deploy script, so removing it breaks the pipeline. The retry loop is the riskier part: it retries non-idempotent calls. Fix that in the same change.

### 35. Oversized Paragraphs

**Problem:** LLM paragraphs run long and uniform: five or more sentences of even length, several ideas chained into one block. Human writing breaks earlier and unevenly. Keep paragraphs to roughly four sentences. When a long paragraph is really an enumeration (steps, options, findings), convert it to a bullet list instead of prose; otherwise split it where the topic turns.

**Before:**
> The migration touches three services and requires coordination with the platform team, which owns the deployment pipeline. Each service must be updated to the new SDK version before the cutover date, and the SDK update changes the retry behavior in ways that affect timeout configuration. The timeout values in the current config were tuned for the old behavior, so they need to be re-measured after the update. Finally, the rollback path requires keeping the old endpoints alive for two weeks, which has a cost implication that finance has not yet approved.

**After:**
> The migration touches three services; the platform team owns the deployment pipeline and must coordinate the cutover.
>
> Open items before the cutover date:
>
> - Update each service to the new SDK version.
> - Re-measure timeout values: the SDK changes retry behavior, and the current values were tuned for the old behavior.
> - Get finance approval for keeping the old endpoints alive two weeks for rollback.

### 36. Parenthetical Overuse

**Problem:** Agents reflexively append an explanatory parenthesis to claims: "(i.e., ...)", "(this means ...)", "(because ...)", "(note that ...)". One self-test ranked parenthetical asides the single strongest AI indicator in its sample. A true aside in parentheses is fine, and §14 still recommends parentheses as one em-dash replacement. The tell is density and function: when parentheses carry explanations, promote the content to its own sentence, move it to a Notes/Details section, or cut it if the reader doesn't need it to act. More than one explanatory parenthesis per paragraph is a signal to restructure.

**Before:**
> The job runs nightly (at 02:00 JST) and writes to the audit bucket (the one created by the logging stack) using the writer role (which has s3:PutObject only), so failures are silent (there is no alerting on this path yet).

**After:**
> The job runs nightly at 02:00 JST and writes to the audit bucket created by the logging stack. The writer role has s3:PutObject only. Failures are silent: nothing alerts on this path yet.

### 37. Spelled-Out Counts

**Rule:** A count stated in a sentence is a digit, not a spelled-out word. This holds from 0 upward,
at the start of a sentence, and when counting the document's own parts. `one` stays a word only as a
pronoun or idiom (`one of the accounts`, `on the one hand`, `no one`, `more than one`). Ordinals stay
words (`the third step`); numbered labels keep digits (`Step 3`). Never rewrite inside a code fence,
inline code, a quoted command or error, or a source comment.

**Before:**

> Three accounts have no GuardDuty detector, two IAM roles grant wildcard actions, and seven VPCs are
> missing the required tag. One Route53 record still resolves to a deleted balancer.

**After:**

> 3 accounts have no GuardDuty detector, 2 IAM roles grant wildcard actions, and 7 VPCs are missing
> the required tag. 1 Route53 record still resolves to a deleted balancer.

## DETECTION GUIDANCE

### What NOT to flag (false positives)

A clean human writer can hit several of the patterns above without any AI involvement. Before rewriting, sanity-check that you are not gutting legitimate prose. The following are *not* reliable indicators on their own:

- **Perfect grammar and consistent style.** Many writers are professionals or have been edited. Polish does not equal AI.
- **Mixed casual and formal registers.** This often signals a person in a technical field, a young writer, or someone with neurodivergent prose habits, not a chatbot.
- **"Bland" or "robotic" prose.** AI prose has *specific* tells. Generic dryness without those tells is just dry writing.
- **Formal or academic vocabulary.** AI overuses *specific* fancy words (see §7), not all fancy words. Don't flatten "ostensibly" or "constituent" just because they sound brainy.
- **Letter-style opening or closing on a comment.** Salutations and sign-offs predate ChatGPT by centuries.
- **Common transition words in isolation.** *Additionally*, *moreover*, *consequently* are AI-coded only when piled up. One *however* is not a tell.
- **Curly quotes alone.** macOS, Word, Google Docs, and most CMSes auto-curl by default. Curly quotes only count when stacked with other tells.
- **Em dashes alone.** Many editors and journalists use them often. Em dashes are evidence only when paired with formulaic sales-y rhythm.
- **One short emphatic sentence.** Humans use clipped sentences to land a point. Flag staccato drama only when several short fragments appear in a row and inflate the tone.
- **"Honestly" or "look" mid-sentence.** These are ordinary in casual writing. The tell is the standalone theatrical opener, not the word itself.
- **Unsourced claims.** Most of the web is unsourced. Lack of citations doesn't prove anything.
- **Correct, complex formatting.** Visual editors and templates produce clean output without any AI.
- **Secondhand text.** Do not rewrite watched phrases inside quotations, titles, proper names, or examples where the phrase is being discussed rather than used.
- **Literal uses of agent-vocabulary words (§34).** A load-bearing wall, an honest witness, pushing back a deadline, folding egg whites, the shape of a molecule: these are the words doing their ordinary jobs. §34 flags only the figurative/hedging usage, and mainly when several cluster together.

When in doubt, look for **clusters** of tells, not isolated ones. A single em dash means nothing; em dashes plus rule-of-three plus *vibrant tapestry* plus a "Conclusion" section is a confession.

### Signs of human writing (preserve these)

When you see these, lean toward leaving the prose alone: they are evidence of a real person writing, and over-editing will destroy what makes the piece sound human.

- **Specific, unusual, hard-to-fabricate detail.** A real address. A weird quote. The phrase "the lawyer who used to work upstairs from my dentist." LLMs round off specifics; humans hoard them.
- **Mixed feelings and unresolved tension.** "I think this is mostly good, but it bothers me, and I can't fully explain why." LLMs default to clean takes.
- **Dated, era-bound references.** Slang, memes, or in-jokes that map to a specific year and subculture. Models lag by a year or more.
- **First-person editorial choices the writer can defend.** If the writer can explain *why* they made a particular cut or used a particular word, that's a strong human signal.
- **Variety in sentence length.** Real writing alternates short and long. AI writing tends toward an even, mid-length cadence.
- **Genuine asides, parentheticals, or self-corrections.** "(I keep wanting to say 'almost' here, but it really was certain.)" Models rarely interrupt themselves like this.
- **Edits made before November 30, 2022.** ChatGPT's public launch. Anything older than that is, with very rare exceptions, not AI-written.

---

## Invocation Modes

**Pasted text (default).** The user gives text in the conversation. Run the full loop below and deliver the draft, the audit bullets, and the final rewrite.

**File mode.** The user points at a file. Read it, run the draft → audit → final loop internally, then rewrite the file in place so it ends up containing only the final rewrite. Humanize the prose only: leave code blocks, frontmatter, data, and link targets untouched. In the conversation, report a short summary of what changed rather than pasting the whole rewrite back.

**When the target collapses wrapped lines** (some issue trackers and chat paste targets treat a soft line wrap as a paragraph break): keep every paragraph, bullet, and checklist item on one physical source line. A rewrite loop naturally re-wraps prose at a conventional width, which silently reintroduces the break bug if the draft had already been reflowed. If the consuming project ships a reflow fixer, run it as a backstop and **review every join it prints**: a fixer cannot tell a genuinely wrapped paragraph from two distinct facts that ended up with no blank line between them (a value line merged into its own explanation, a label line merged into the sentence after it).

**Embedded mode.** Another task or agent is using this skill as one step of a larger job (a PR description, a commit message, a doc). Run the loop internally and output only the final text. No draft, no audit bullets, no summary. The caller wants prose, not ceremony.

## Process and Output

1. Read the input carefully and identify every instance of the patterns above.
2. Write a **draft rewrite**. Check that it reads naturally aloud, varies sentence length, prefers specific details and simple constructions (is/are/has), and keeps the appropriate register.
3. Ask two questions: **"What makes the below so obviously AI generated?"** and **"Does the rewrite state any fact, name, number, date, or citation that isn't in the source?"** Answer briefly. A fabrication is a defect even when it sounds more human than the vague original.
4. Revise into a **final rewrite** that addresses them and contains no em or en dashes (see §14).

In pasted-text mode, deliver the draft, the brief "still-AI" bullets, the final rewrite, and (optionally) a short summary of changes. In file and embedded modes, run the same loop but deliver only what the mode calls for (see Invocation Modes).

## Full Example

**Before (AI-sounding):**
> I recently spent five unforgettable days in Lisbon, and let me tell you — this city completely stole my heart. From the moment I arrived, I knew I was somewhere truly special.
>
> Nestled along the banks of the Tagus River, Lisbon stands as a vibrant testament to Portugal's enduring spirit, where rich history and modern energy intertwine at every turn. Yes, the famous hills are challenging — my legs certainly felt it! — but every climb rewards you with breathtaking, panoramic views that make it all worthwhile.
>
> No trip would be complete without riding the iconic Tram 28, winding through the city's most historic neighborhoods. And the food? Simply divine. The original pastéis de nata at Pastéis de Belém are a beloved national treasure, and savoring one still warm was a moment I will never forget.
>
> But what truly makes Lisbon special isn't just the sights — it's the feeling. Wander a few steps off the main squares and you'll discover a quieter, more authentic side: sun-drenched alleys, charming tiled facades, and friendly locals going about their daily lives, inviting you to slow down and savor every moment.
>
> Of course, the must-see São Jorge Castle offers stunning views over the rooftops below. The queues can be long, but the experience is absolutely worth it for any history buff or curious traveler.
>
> Would I go back? Absolutely. Lisbon isn't just a place to visit — it's a place to fall in love with, again and again. If you're dreaming of your next getaway, this is one destination that promises memories to last a lifetime. ✨

**Draft rewrite:**
> I spent five days in Lisbon last October and I am still a little split on it. The city is beautiful, but it is also more tiring than I expected.
>
> The hills are not a detail. My hotel was in Alfama, which looked great in photos and meant I had to climb a long staircase every time I wanted coffee. By the second day I was planning walks around which direction went downhill.
>
> I rode Tram 28 because everyone says to ride Tram 28. It was crowded, slow, and mostly full of people filming the same corners. The pastries were better. I had a warm custard tart in Graça that was worth the hype.
>
> The part I liked most was away from the main squares: laundry, tile, open windows, and people watching football in small cafes. The castle view was good, but the line was too long for what it was.
>
> I would go back, but in spring and with better shoes.

**What makes the below so obviously AI generated?**

- The draft is too compressed compared with the original; it drops texture instead of rewriting it.
- Some sentences still explain the point too cleanly ("The city is beautiful, but...").
- The closer is flat and generic rather than a real ending in the same voice.

**Now make it not obviously AI generated.**
> I spent five days in Lisbon last October and still have mixed feelings about it. Beautiful, yes. Also harder on the knees than anyone warned me.
>
> The hills are the whole story and somehow never make the brochures. My hotel was up in Alfama, which photographs beautifully and translates, in practice, to climbing what felt like a six-story staircase every time I wanted coffee. By the second day my calves had opinions. I started planning each walk around which way was downhill, which is a strange way to see a city but probably an honest one.
>
> Everyone says to ride Tram 28, so I did, wedged against a stranger's backpack for forty minutes while three tour groups filmed the same corner. I would walk the route next time, or go before breakfast. The custard tarts, though, earn the fuss. I had one at a plain little place in Graça, still warm, and for about thirty seconds I understood why people build trips around pastry.
>
> What I did not expect was how quiet the city gets away from the main squares. Two blocks uphill from any plaza it turns into laundry lines, chipped tile, open windows, and old men watching football with the sound turned up. That is the Lisbon I keep thinking about, not the castle.
>
> The castle is fine. The view is great, the queue is long, and I spent more time shuffling toward the entrance than looking at anything once I got inside. If I had only two days, I would trade it for an afternoon of getting lost.
>
> I would go back, but in spring and with better shoes. Lisbon does not bend over backward to make things easy for you. I think I liked that, even when my legs disagreed.

**Changes made:** Kept the first-person travel recap and roughly the same level of detail, but removed the chatbot framing, significance inflation, promotional language, forced enthusiasm, em dashes, rule-of-three cadence, generic upbeat conclusion, and emoji. Rebuilt the piece around concrete friction, mixed feelings, uneven rhythm, and specific scenes.

## Reference

This skill is based on [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup. The patterns documented there come from observations of thousands of instances of AI-generated text on Wikipedia.

The agent-era patterns (§34-§36) draw on additional sources (researched 2026-07-22 JST): [claude-code issue #53454](https://github.com/anthropics/claude-code/issues/53454) and [jola.dev](https://jola.dev/posts/how-to-stop-claude-from-saying-load-bearing) ("load-bearing", "honest take", "you're absolutely right"), a [Hacker News thread on Claude phrasing](https://news.ycombinator.com/item?id=48905248) ("push back", "synthesize", "key insight"), [crystl.dev](https://crystl.dev/blog/footgun-and-other-things-claude-says/) ("footgun", confirmed by title/snippet only, since the page itself was unreachable during the research pass), and a [PCWorld self-test](https://www.pcworld.com/article/3179916) that ranked parenthetical asides its strongest AI indicator. The §34 items marked unsourced are recurrent in observed agent output but had no written source as of that research pass.

From Wikipedia: "LLMs use statistical algorithms to guess what should come next. The result tends toward the most statistically likely result that applies to the widest variety of cases."

## Provenance

Adapted from a community skill distributed under the MIT License (itself
derived from `blader/humanizer` 2.9.1), locally adapted for SREPowers.
Original attribution retained per the upstream licensing.

Three site-specific excisions were made on the way in, before this landed in
the tree:

- a "CCoE mode" section keyed to one organization's report and ticket templates
  (the portable half — lead with the outcome, plain sentences, real specifics,
  detail moved out of the main flow — survives in
  `references/writing-rubric.md`)
- a paste-target reflow step naming one tracker and its private fixer script,
  rewritten generically as "when the target collapses wrapped lines"
- a real account name and 12-digit account ID in the rubric's
  specifics-over-description example, now `<account-name>` / `<account-id>`

The rubric governs prose *inside* sections. Template-mandated structure —
immutable headers and their casing, prescribed label bullets, rating-line
separators, checklist syntax — plus appendices, code blocks, and queries stay
verbatim. Patterns §14 through §17 do not apply to template-mandated formats.
