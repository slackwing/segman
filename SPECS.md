# Sentence Segmenter Specification

**Keep this document terse - only enough to capture every segmenter rule.**

---

## Core Principles

### Nesting Pattern (CRITICAL)

**Rule:** Any nested structure that begins at the top level stays as ONE sentence.

**Nested structures:**
- Parentheticals: `(text)`
- Editorial brackets: `[text]`
- Quotes: `"text"`
- Italicized thoughts: `*text*`

**Depth:** Only 1 level deep

**Implication:** No splitting within any nesting. Even if the nested content contains periods, exclamation points, or question marks, the entire structure (including surrounding context) remains one sentence.

**Examples:**
- `Sentence. (Parenthetical with period.) Continuation.` = ONE sentence
- `Text [editorial note.] more text.` = ONE sentence
- `Before "quote. Another sentence." after.` = ONE sentence

---

## Rule Categories

### 1. Structural Boundaries

| Pattern | Description | Test Scenarios | Priority |
|---------|-------------|----------------|----------|
| `\n\n` | Double newline always creates boundary (paragraphs, sections) | 001 | HIGH |
| `\n\t` | Tab-indented paragraph break always creates boundary | 012 | HIGH |
| `&`-commands (block) | `&title`/`&part`/`&chapter`/`&meta` — and `&anchor`/`&placeholder`/`&snippet`/`&end` when it is the sole non-whitespace content of its line — are separate segments (boundary before and after), like headers | 065, 066, 067, 068, 069, 072, 076, 079, 082, 084 | HIGH |
| `&`-commands (inline) | `&anchor`/`&placeholder`/`&snippet`/`&end` sharing its line with other content, and `&reference` always, stay inside the surrounding sentence (no boundary) | 070, 071, 073, 080, 085 | HIGH |
| `&end#slug` bare token | `end` is the one keyword complete with a bare `#slug` and no `{...}` groups; the slug self-terminates on `[a-z0-9-]`. `&end` without `#`/`{` stays prose | 082, 083 | HIGH |
| Literal `&` | A `&` not followed by an exact command keyword + `#`/`{` is ordinary prose (e.g. `Smith & Sons`, `R&D`, `A &chapter of accidents`) — never a boundary | 074, 075 | HIGH |
| `&`-command token atomic (RULE 10) | No boundary may land strictly inside a recognized command token — sentence punctuation inside a `{...}` arg (a `&placeholder`'s details, a `&reference`'s notes) never splits the token | 079, 080, 081 | HIGH |

### 2. Dialogue & Quotation Rules

| Pattern | Description | Test Scenarios | Priority |
|---------|-------------|----------------|----------|
| `"quote" <pronoun> <attribution_verb>` | Quote + attribution stays together (e.g., "Hello." he said.) BUT period after attribution ends sentence | 006 | HIGH |
| `\n"quote"` or `\n\t"quote"` | Quote starting on new line creates boundary before quote | 004, 005 | HIGH |
| `"quote!"` embedded in sentence | Quote with internal punctuation but embedded in sentence doesn't split | 003 | MEDIUM |
| Multi-sentence quote | Entire quote stays as ONE sentence, even with internal `.!?` | 031 | HIGH |
| `*italic thought*` | Italics used for internal thoughts follow SAME rules as quotes | 016 | HIGH |
| Split quote with attribution | `"part1," he said, "part2."` stays as ONE sentence - attribution search stops at next quote | 056 | HIGH |

**Attribution verbs:** said, asked, replied, stammered, shouted, whispered, muttered, continued, added, explained

**Pronouns:** he, she, I, they, we, you

**Italic thought patterns:** Internal monologue in italics treated identically to quoted dialogue for boundary detection.

### 3. Punctuation Context Rules

| Pattern | Description | Test Scenarios | Priority |
|---------|-------------|----------------|----------|
| `...` (ellipsis) | Ellipsis does NOT create sentence boundary | 002, 006 | HIGH |
| `. ` (period + space) | Default boundary unless in exception context | All | MEDIUM |
| `.\n` (period + newline) | Boundary at period followed by newline | Multiple | MEDIUM |
| `! `, `? ` | Exclamation/question + space creates boundary | 003 | MEDIUM |
| `!\n`, `?\n` | Exclamation/question + newline creates boundary | Multiple | MEDIUM |
| `:` (colon) | Colon does NOT create boundary (transparent) | TBD | MEDIUM |
| `;` (semicolon) | Semicolon does NOT create boundary (transparent) | TBD | LOW |
| `—` (em-dash) | Em-dash is transparent (ignore for boundaries) except at `\n\n` | TBD | HIGH |
| Abbreviations with `.` | Period after abbreviation does NOT create boundary | TBD | MEDIUM |

### 4. Exception Contexts (Boundary Inhibitors)

| Context | Rule | Test Scenarios | Priority |
|---------|------|----------------|----------|
| Inside quoted text | No splitting on internal punctuation | 003 | HIGH |
| Ellipsis pattern | `...` followed by space or punctuation is NOT boundary | 002, 006 | HIGH |
| Quote + attribution | Pattern `"..." <pronoun> <verb>` blocks split after quote punctuation | 006 | HIGH |

---

## Abbreviations List (Hardcoded)

**Common titles:**
- Mr., Mrs., Ms., Dr., Prof., Sr., Jr.

**Time expressions:**
- a.m., p.m., am, pm (no periods)

**Common abbreviations:**
- etc., vs., e.g., i.e., approx., govt.

**Single letters:**
- Single capital letter + period (e.g., `K.`, `A.`, `I.`) - context-dependent
- Exception: `I.` as Roman numeral at start of line IS a boundary

**Numbers/Measurements:**
- No., vol., ch., p., pp.

**Growing list:** Add to this as encountered in manuscript.

---

## Implementation Notes

### V3 Architecture (Current: 59/59 passing, v2.1.0)

**3-Phase Pipeline:**
1. **Mark Nested Structures** - Find all quotes, parens, brackets, italics (position ranges, 1-level only)
2. **Mark Boundaries** - Apply rules to identify split points (respecting nested regions)
3. **Split & Normalize** - Split at boundaries, normalize internal whitespace to spaces

**Critical details:**
- **Quote detection:** Straight quotes `"` toggle open/close; curly quotes `"` `"` explicit
- **Whitespace normalization:** Internal `\n` and `\t` → single space, collapse multiples
- **Attribution detection:** After `\n\t"quote"`, check for lowercase word OR "I <lowercase>" pattern OR period on same line; stop search at next quote to preserve split quotes
- **Abbreviation handling:** Skip sentence boundaries for common abbreviations (Dr., a.m., etc.) and when period is followed by lowercase word
- **Editorial brackets:** `[...]` inside quotes/parens/italics do NOT create boundaries (protected by nested region detection)
- **Paragraph breaks:** Both `\n\n` and `\n\t` (when not dialogue) create boundaries
- **Markdown headers:** REMOVED in v2.0.0 — a `#` line is now ordinary prose. Structure is expressed with `&`-commands.
- **`&`-commands:** A `&` begins a command only when immediately followed by an exact keyword (`title`, `part`, `chapter`, `anchor`, `reference`) and then `#` or `{`. `title`/`part`/`chapter` always boundary before and after (own segment); `anchor` boundaries only when it is the sole non-whitespace content of its line (leading indent / trailing spaces ignored), otherwise it stays inline; `reference` never boundaries. Any other `&` is literal prose. segman decides boundaries only — the command's fields are parsed by the consuming application.

### Quote Classification
- **Standalone dialogue**: Quote on own line (`\n\t"..."`) without attribution before
- **Embedded dialogue**: Quote within ongoing sentence (e.g., after "shouting,")
- **Attributed dialogue**: Quote followed by `<pronoun> <verb>` pattern (or verb before)

---

## Edge Cases Discovered from Manuscript

*Patterns found through manuscript analysis. Status: ✓ = handled, ⚠ = partial, ✗ = not handled, ? = TBD*

### Quotation Variations

| Pattern | Example from MS | Line(s) | Status | Scenario | Notes |
|---------|-----------------|---------|--------|----------|-------|
| Embedded quote mid-sentence | `shouting, "Yay! Home!"—except the purse` | 14 | ⚠ | 003 | After comma, em-dash continuation |
| Multiple quotes in attribution | `he said trailing off...then, "Not yet"` | 26 | ✗ | 006 | Continuing after first attribution |
| Quote with colon prefix | `you'd definitely remember, because: It was` | 14 | ✗ | - | Colon as quote introducer |
| Standalone dialogue line | `\t"Hello?"` | 15 | ✓ | 004 | Tab-indented dialogue |
| Action → newline → dialogue | `I yelled,\n\t"Ow! F—!"` | 18-19 | ✓ | 005 | Comma before newline quote |
| Dialogue with "I said" attribution | `\t"Terminal 4, please," I said.` | 250-251 | ✓ | 058 | Attribution using "I <verb>" pattern |
| Quote followed by question | `"I'm alright," and offered it` | 128 | ✗ | - | Quote in mid-action |
| Direct address in quote | `"Hey A—, sorry if I'm"` | 22 | ✗ | - | Em-dash for redacted name |

### Punctuation Context

| Pattern | Example from MS | Line(s) | Status | Scenario | Notes |
|---------|-----------------|---------|--------|----------|-------|
| Ellipsis mid-sentence | `because... well, I'm writing` | 8 | ✓ | 002 | Does NOT end sentence |
| Ellipsis in dialogue | `"No... I mean, yeah. Or..."` | 26 | ✓ | 006 | Multiple ellipses in one quote |
| Em-dash parenthetical | `the other hand—the other hand holding` | 18 | ✗ | - | Mid-sentence dash |
| Em-dash continuation | `Home!"—except the purse` | 14 | ✗ | - | After punctuation |
| Question mark in context | `why in your house to put it?` | 7 | ✗ | - | Question within sentence |
| Possessive + period | `Carmella's and have` | 14 | ✗ | - | Don't split on 's. |
| Numbers with comma | `2,638 miles away` | 8 | ✗ | - | Comma in numbers |
| Abbreviations | `2am`, `Mr.`, `Dr.` | 128 | ✗ | - | Period not boundary |

### Structural Elements

| Pattern | Example from MS | Line(s) | Status | Scenario | Notes |
|---------|-----------------|---------|--------|----------|-------|
| Markdown H1 | `# The Wildfire` | 1 | ✓ | 001 | Standalone segment |
| Markdown H2 | `## Chapter 1` | 3 | ✓ | 001 | Standalone segment |
| Markdown H3 | `### I.` | 5 | ✓ | 001 | Roman numeral header |
| Paragraph break | `\n\n` | Multiple | ✓ | 001 | Always boundary |
| Tab-indented line | `\tAh well, who` | 8 | ✗ | - | Continues from previous |
| Section marker | `II.` at start of line | 10, 115 | ✗ | - | Roman numeral paragraph |
| Placeholder text | `[A little more dialogue here.]` | 65 | ✗ | - | Editorial placeholder |
| Bracketed narrative | `[Placeholder. Kostya throws...]` | 136 | ✗ | - | Author notes |

### Complex Attribution Patterns

| Pattern | Example from MS | Line(s) | Status | Scenario | Notes |
|---------|-----------------|---------|--------|----------|-------|
| Simple attribution | `"Hello?" he said.` | - | ✓ | 006 | pronoun + verb |
| Attribution with adverb | `he said calmly` | 83 | ✗ | - | verb + adverb |
| Attribution + continuation | `he said trailing off...then,` | 26 | ✗ | 006 | Multiple parts |
| Attribution with laugh | `unconvincing laugh, then,` | 26 | ✗ | 006 | Non-verb action |
| Past participle action | `he stammered` vs `he was stammering` | 26 | ✓ | 006 | Tense variation |
| Multiple dialogue verbs | `he said, "I'm"` + continuation | - | ✗ | - | Nested structure |

### Italic/Emphasis Patterns

| Pattern | Example from MS | Line(s) | Status | Scenario | Notes |
|---------|-----------------|---------|--------|----------|-------|
| Italic with period inside | `*upon a time*.` | 8 | ✓ | 002 | Period before asterisk |
| Italic emphasis mid-sentence | `I *couldn't* tell you` | 8 | ✗ | - | Internal emphasis |
| Italic phrase | `*So it was*—the epidemic` | 7 | ✗ | - | Em-dash after italic |

### Abbreviations & Proper Nouns

| Pattern | Example from MS | Line(s) | Status | Scenario | Notes |
|---------|-----------------|---------|--------|----------|-------|
| Redacted names | `K—,`, `A—,`, `A—.` | 7, 17, 22 | ✗ | - | Em-dash after initial |
| Highway numbers | `highway 101` | 7 | ✗ | - | No period |
| Time expressions | `2am`, `eleven o'clock` | 24, 128 | ✗ | - | Various formats |
| Initials | `J.` or `K.` | - | ✗ | - | Single letter + period |
| Terminal number | `Terminal 4, please` | 125 | ✗ | - | Number in name |

### Sentence-Internal Structures

| Pattern | Example from MS | Line(s) | Status | Scenario | Notes |
|---------|-----------------|---------|--------|----------|-------|
| Parenthetical aside | `(didn't we feel ready` | 7 | ✗ | - | Parens mid-sentence |
| Nested em-dashes | `word—word—word` | Multiple | ✗ | - | Multiple dashes |
| Question within sentence | `What if...? We shrugged` | 7 | ✗ | - | ? mid-paragraph |
| List with semicolons | - | - | ? | - | Not seen yet |
| Colon introducing | `remember, because: It was` | 14 | ✗ | - | Colon not boundary |

---

## Scenario Coverage Map

*Which scenarios test which rules*

| Rule Category | Scenarios Testing This Pattern |
|---------------|--------------------------------|
| Literal `#` (no longer a header, v2.0.0) | 077 |
| `&`-commands (block) | 065, 066, 067, 068, 069, 072 |
| `&`-commands (inline) | 070, 071, 073 |
| Literal `&` (not a command) | 074, 075 |
| Double newline `\n\n` | 001 |
| Newline + tab `\n\t` | 004, 005 |
| Ellipsis `...` | 002, 006, 038, 039, 040, 042 |
| Em-dash transparent | 007, 009, 010, 011, 012, 013, 014, 015, 049 |
| Colon transparent | 029, 030, 031 |
| Semicolon transparent | 053, 055 |
| Parenthetical transparent | 030, 032, 035, 036 (034 pending) |
| Dialogue attribution | 006, 023, 024 |
| Multi-sentence quotes | 031 |
| Embedded dialogue | 003 |
| Italics (like quotes) | 016, 049 |
| Editorial placeholders | 021, 022, 063, 064 |
| Editorial `[...]` inside quotes | 062 |
| Abbreviations | 045, 047, 048, 059, 060, 061 |
| Numbers with commas | 002 |
| Possessives | 003 |

---

## Rule Modifications Log

*Track changes to rules and their rationale.*

| Date | Rule Modified | Reason | Related Scenarios |
|------|---------------|--------|-------------------|
| 2026-03-24 | Initial spec | V2 redesign | 001-006 |
| 2026-03-24 | Comprehensive extraction | Added 24 scenarios covering all patterns | 007-055 |
| 2026-03-24 | Italics = quotes | User confirmed italics follow quote rules | 016 |
| 2026-03-24 | Multi-sentence quotes | User confirmed entire quote = one sentence | 031 |
| 2026-03-24 | Period after attribution | Clarified period AFTER attribution ends sentence | 023, 024 |
| 2026-03-25 | V3 complete (100%) | 3-phase architecture with whitespace normalization | All 36 |
| 2026-03-27 | Editorial brackets protected | Fixed RULE 1: Brackets inside quotes/parens/italics don't create boundaries | 062, 063, 064 |
| 2026-07-24 | **v2.0.0 BREAKING**: removed RULE 8 (`#` headers) | `#` lines are now literal prose; structure via `&`-commands | 057, 077 |
| 2026-07-24 | RULE 9: `&`-commands | Added structural `&`-command boundaries (block/inline) alongside `#` headers; additive, `#` unchanged. Derived from reference/the-wildfire-v2.manuscript | 065-076 |
| 2026-07-25 | v2.2.0: `&placeholder` + RULE 10 | Added `placeholder` to the command keywords (block iff sole line content, like anchor). New RULE 10: command tokens are atomic — boundaries strictly inside a recognized token are suppressed, so punctuation in `{...}` args no longer splits `&placeholder` details or `&reference` notes | 079, 080, 081 |
| 2026-07-25 | v2.3.0: `&end#slug` | Added `end` to the command keywords (block iff sole line content, like anchor) — marks the end of a region opened by the slug's block command. Grammar: `end` alone may be a bare `#slug` token with no brace groups | 082, 083 |
| 2026-07-26 | v2.4.0: `&snippet` | Added `snippet` to the command keywords (block iff sole line content, like anchor). Opens a machine-managed canon region `&snippet#<id>{label}` closed by `&end#<id>` (manuscript-studio VARIATIONS_PLAN). Standard grammar: recognition needs `#` or `{` after the keyword and ≥1 brace group — a bare `&snippet#id` stays prose | 084, 085, 086 |
| 2026-03-27 | More abbreviations | Added comprehensive abbreviation list (time, titles, Latin, locations, months, days, business) | 059, 060, 061 |
