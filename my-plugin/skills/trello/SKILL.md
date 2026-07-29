---
name: trello
description: >
  Read and write a Trello board from a coding session: look up what a card
  actually says, find the card for the work in progress, create cards from
  findings, move them across lists, and comment progress back. Wraps the Trello
  REST API v1 through `scripts/trello` (no MCP server, no third party holding
  the token). Covers board/list/card lookup, search, create, move, label,
  checklist, and comment, plus the write-safety rules and the API's traps
  (archive vs. permanent delete, response bloat, rate limits, ID forms).
  Triggers: "what's on the board", "what does card X say", "find the Trello
  card for this", "make a card for that", "move it to Done", "comment the PR
  link on the card", any Trello URL or short link pasted into the session.
  Do NOT use for Jira or Confluence (different API, hosted Atlassian MCP).
---

# Trello from a coding session

The board is a work surface teammates watch. Reads are free; **every write is
visible to other people and most of them send a notification.** The safety
rules below are the load-bearing part of this skill.

## Setup (once, by the developer)

1. Get an API key from an existing Power-Up at
   <https://trello.com/power-ups/admin> (its **API key** tab), or create one.
   The key belongs to the Power-Up and is shared; the token is per person.
2. Mint your own token by visiting, with that key substituted in:
   `https://trello.com/1/authorize?expiration=30days&scope=read,write&response_type=token&key=YOUR_KEY`
   Approve it and copy the token. Prefer a real expiration over `never`.
3. Store both, readable only by you:

   ```bash
   mkdir -p ~/.config/trello
   cat > ~/.config/trello/credentials <<'EOF'
   TRELLO_API_KEY=...
   TRELLO_TOKEN=...
   EOF
   chmod 600 ~/.config/trello/credentials
   ```

The token is a bearer credential for the whole account, not one board. Revoke it
at <https://trello.com/my/account> under Applications if it leaks. Reusing a
shared team key means sharing its rate budget (see Traps).

## The wrapper

`scripts/trello` handles auth and URL-encoding. Method defaults to GET.

```bash
trello whoami                                              # which creds are live
trello /members/me/boards fields=name,shortLink            # GET
trello POST /cards idList=<listId> name="Fix the parser"   # POST
trello PUT /cards/<cardId> idList=<doneListId>             # PUT
```

Values are passed through `--data-urlencode`, so pass them raw: no manual `%20`,
and multi-line descriptions work as-is. Pipe through `jq` to trim output.

Never print the key or token, and never inline them into a command.

### Whichever credentials are active

Nothing about the key, the token, or the account is baked into this skill.
Credentials resolve at call time, in this order:

1. `TRELLO_API_KEY` and `TRELLO_TOKEN` from the environment, if both are set.
2. Otherwise the file at `TRELLO_CREDENTIALS`, defaulting to
   `~/.config/trello/credentials`.

So rotating a key, replacing an expired token, or pointing at a different
Power-Up means editing the file or exporting two variables. The skill needs no
change, and a one-off call can override the file inline:

```bash
TRELLO_API_KEY=... TRELLO_TOKEN=... trello whoami
```

**Run `trello whoami` before the first write of a session.** It prints the key's
last four characters and where they came from, the account the token belongs to,
whether that token actually has write scope, when it expires, and how many open
boards it can see. Confirm that account is the intended one rather than assuming
it. Exit status is nonzero if any probe fails, so it works as a gate.

## Write safety

These are not suggestions.

- **Know whose account you're writing as.** Run `trello whoami` before the
  session's first write and name the account in the confirmation. A token is
  account-wide, so the wrong active credential writes to a real board belonging
  to someone else's view of the world.
- **Confirm every write with the developer before running it.** State the exact
  call and the human meaning ("creates a card 'X' in list Done on board Y").
  Approval for one write is not approval for the next.
- **Never `DELETE /cards/<id>`.** Trello has no trash for cards; deletion is
  irreversible. Archive instead: `PUT /cards/<id> closed=true`.
- **Resolve the board explicitly before writing.** Confirm the board and list
  names against their IDs, and write only to the board you were pointed at.
  Never guess a list ID from a name you have not just looked up.
- **No bulk writes without a count.** If a request implies more than three
  writes, say how many and get explicit approval for the batch.
- **Comments notify people.** Treat a card comment like sending a message. Ask
  what it should say rather than composing on someone's behalf.
- **Don't reassign or unassign members.** Membership is a people decision.

## Reads

```bash
# Boards you can see
trello /members/me/boards fields=name,shortLink,url

# Lists on a board (the "columns")
trello /boards/<boardId>/lists fields=name,pos

# Cards in one list, trimmed
trello /lists/<listId>/cards fields=name,shortUrl,due,idMembers

# One card in full, with its labels and members resolved
trello /cards/<cardId> fields=name,desc,shortUrl,due,closed labels=true members=true

# Comments on a card, newest first
trello /cards/<cardId>/actions filter=commentCard limit=20 \
  | jq -r '.[] | "\(.memberCreator.fullName): \(.data.text)"'

# Search, scoped to one board
trello /search query="parser timeout" idBoards=<boardId> modelTypes=cards \
  card_fields=name,shortUrl

# The vocabulary you need before writing: label and member IDs
trello /boards/<boardId>/labels fields=name,color
trello /boards/<boardId>/members fields=fullName,username
```

A board's `shortLink` (the 8 characters in a `trello.com/b/<shortLink>` URL)
works anywhere a board ID does, so a pasted URL is enough to start. Card URLs
carry a short link too, and `GET /cards/<shortLink>` resolves it.

## Writes

```bash
# Create a card at the top of a list
trello POST /cards idList=<listId> name="Fix the parser timeout" \
  desc="Repro: ..." pos=top

# Move a card to another list (this is what "move to Done" means)
trello PUT /cards/<cardId> idList=<listId>

# Rename, re-describe, set a due date, mark it complete
trello PUT /cards/<cardId> name="..." desc="..." due=2026-08-05T17:00:00Z
trello PUT /cards/<cardId> dueComplete=true

# Archive (the reversible stand-in for delete)
trello PUT /cards/<cardId> closed=true

# Comment
trello POST /cards/<cardId>/actions/comments text="Shipped in #526."

# Labels, by ID from the board's label list
trello POST /cards/<cardId>/idLabels value=<labelId>
trello DELETE /cards/<cardId>/idLabels/<labelId>

# Checklists
trello POST /cards/<cardId>/checklists name="Rollout"
trello POST /checklists/<checklistId>/checkItems name="Migration deployed"
trello PUT /cards/<cardId>/checkItem/<checkItemId> state=complete

# Attach a URL (a PR link reads better as an attachment than in the desc)
trello POST /cards/<cardId>/attachments url=https://github.com/... name="PR #526"
```

## Traps

- **Archive is not delete.** `closed=true` is recoverable from the board's
  archive; `DELETE` is gone forever. Default to archiving, always.
- **Responses are enormous.** A bare `GET /cards/<id>` returns dozens of fields
  including badge counts and plugin data. Always pass `fields=` and pipe to
  `jq`, or the output swamps the context.
- **Two ID forms.** 24-character hex IDs work everywhere. Short links work for
  boards and cards only, not lists or labels.
- **Rate limits** are 300 requests per 10 seconds per key and 100 per 10 seconds
  per token. A loop over cards hits the token limit first; batch by fetching a
  list's cards in one call instead of per-card requests. On a key shared with
  teammates, the 300 is shared with them and with anything the Power-Up itself
  runs, so a burst can fail for reasons that have nothing to do with this
  session.
- **`pos`** takes `top`, `bottom`, or a float. Omitting it appends to the bottom.
- **Dates** are ISO 8601 UTC. A date with no time lands at midnight UTC, which
  reads as the previous evening in US time zones.
- **Custom fields use a different shape**: read them with
  `GET /boards/<boardId>/customFields`, but setting a value takes a JSON body on
  the singular path `PUT /card/<cardId>/customField/<fieldId>/item`, which this
  wrapper's form encoding does not produce. Use raw `curl` for that case.
- **`--fail-with-body`** means a 4xx prints Trello's error text and exits
  nonzero. The messages discriminate, so read them literally rather than
  assuming "auth is broken":
  - `invalid key` — the API key is wrong. The token is not the problem yet.
  - `invalid app token` — the key is **good**, the token is wrong or expired.
    Mint a new one; the key needs no change.
  - `unauthorized card permission requested` — valid token, but it was minted
    without `write` scope. Re-authorize with `scope=read,write`.
  - `invalid id` — an ID is malformed or belongs to a board this token can't
    see, which is the usual symptom of the wrong account being active. Run
    `trello whoami`.
- **Allowed origins on the Power-Up don't apply here.** They constrain the OAuth
  redirect flow for client-side apps. A manually generated token used
  server-side needs no origin entry.
