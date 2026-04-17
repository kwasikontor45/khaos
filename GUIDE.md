# kripts guide
## lt + arc — how to actually use these

---

## the philosophy first

These tools exist to reduce friction, not add ceremony.

`lt` is a focus anchor — it holds the one thing you are supposed to be doing right now so your brain doesn't have to.  
`arc` is a maintenance layer — it keeps the machine and repos in a known state without you having to think about it.

Neither tool replaces your calendar, your project tracker, your GitHub issues, or your brain.  
They replace the mental overhead of "wait, what was I doing?" and "when did I last clean this machine?"

**The cardinal rule:** if using the tool takes longer than the thing it helps with, don't use the tool.

---

## lt — your daily lieutenant

### what it is

A single-focus task runner and timestamped note log. Lives entirely in `~/.local/share/lt/` — three plain text files:

- `~/.local/share/lt/tasks` — all tasks, one per line, prefixed `pending` or `done`
- `~/.local/share/lt/focus` — the single task you are doing right now
- `~/.local/share/lt/notes` — timestamped notes, one per line

Nothing encrypted, nothing proprietary. You can read, edit, and back these up with any text tool.

---

### daily flow — the intended loop

**Morning (or start of a session):**
```bash
lt                          # see dashboard: what's in focus, how many tasks, last note
lt do "fix HoldToConfirm"   # add today's first task — it auto-sets as focus
lt do "test cover screen"   # add the next one
lt do "push to main"        # and the next
lt tasks                    # confirm the list looks right
```

**While working:**
```bash
lt focus                    # quick reminder of what you're supposed to be doing
lt note "tried disabling ScrollView — still flaky"   # capture a thought without losing flow
```

**When you finish a task:**
```bash
lt done                     # marks focus complete, auto-advances to next task
```

**End of session:**
```bash
lt notes                    # review what you captured during the session
lt clear                    # remove completed tasks to keep the list clean
```

---

### use case scenarios

**Scenario 1 — deep work session**
You sit down to do bug surgery. Three known bugs.
```bash
lt do "fix Override pill animation loop"
lt do "fix HoldToConfirm inside ScrollView"
lt do "investigate ECG/wave conflict"
lt focus        # → fix Override pill animation loop
```
Work. Fix the bug. Test it.
```bash
lt done         # → HoldToConfirm is now in focus
```
You don't have to remember what's next. lt does.

**Scenario 2 — interrupted mid-task**
Someone messages you. You handle it. Twenty minutes pass.
```bash
lt focus        # → fix HoldToConfirm inside ScrollView
```
You're back.

**Scenario 3 — capturing a decision mid-flow**
You're in the middle of coding and realize something important.
```bash
lt note "ScrollView needs scrollEnabled=false during hold — not just Pressable"
```
One line. No app-switching. No lost thought. Continue.

**Scenario 4 — end of day review**
```bash
lt tasks        # see what got done and what's still pending
lt notes        # review every thought you captured today
lt clear        # clear the done items
```

---

### mistakes to avoid

**Adding too many tasks**  
lt is not a backlog. If you add 15 tasks, the focus concept collapses. Keep it to what you can realistically do today — 3 to 6 items maximum. Everything else lives in your project tracker (GitHub issues, Notion, wherever).

**Using it as a calendar**  
lt has no dates, no deadlines, no scheduling. It only knows "pending" and "done." If a task has a specific due date, put it in your calendar too.

**Never running `lt clear`**  
Completed tasks accumulate and the list becomes noise. Clear after each session or at the end of each day.

**Setting focus manually when you should let it flow**  
`lt done` advances focus automatically. Trust it. Only use `lt set` when you genuinely need to jump out of order — not as a habit.

**Using notes as a substitute for real documentation**  
Notes are ephemeral captures — thoughts you want to keep for the session. If a note contains a decision that matters long-term, move it somewhere permanent (git commit message, CLAUDE.md, etc.).

---

### how not to do too much

lt enforces one focus at a time. That is the point.

If you find yourself checking `lt tasks` constantly and anxious about the queue length, your task list is too long. Cut it. The rule: if you wouldn't do it today, it doesn't belong in lt today.

The dashboard shows one focus, one count, one note. That is intentional. You should be able to read it in two seconds and get back to work.

---

### full command reference

```
lt                    dashboard: focus, tasks, latest note
lt do "task"          add a task — sets focus if empty
lt done               mark focus complete, advance to next
lt focus              show what you're supposed to be doing
lt set "task"         override focus without adding to list
lt tasks              list all pending and completed tasks
lt drop "partial"     remove a pending task by name match
lt clear              remove all completed tasks
lt note "text"        save a timestamped note
lt notes              show last 10 notes
lt help               this in the terminal
```

---

---

## arc — your system architect

### what it is

System maintenance and repository oversight. It knows about your disks, your git repos, and (now) your Kataleya dev environment. It does not touch your code — it just tells you the state of things and handles housekeeping you'd otherwise forget.

---

### when to run each command

**`arc`** (no arguments) — run this whenever you sit down and want a quick health check. Shows disk usage and the status of every git repo in your home directory: branch, clean/uncommitted, commits ahead of remote, last commit time. Takes two seconds. Tells you if anything needs attention before you start working.

**`arc audit`** — deeper git check. Fetches from remote for every repo, then compares ahead/behind. Run this when you've been away for a day or more, or before starting a significant coding session. It will tell you if any repo is behind remote (needs a pull) or if you have unpushed commits sitting around.

**`arc update`** — system package update. Run weekly, or whenever you notice system packages feeling stale. Does `apt update && apt upgrade && autoremove && clean`. Takes 2–5 minutes. No decisions required from you.

**`arc clean`** — deep clean. Clears `~/.cache`, `/tmp`, and apt debris. Run monthly or when disk is tight. Check `arc` first to see current disk usage, then run `arc clean`, then `arc` again to see what was reclaimed.

**`arc expo`** — Kataleya dev server. Run this instead of manually managing ngrok and Expo. It handles everything: kills stale processes, starts ngrok, waits for the tunnel URL, launches Expo with the URL wired in. See dedicated section below.

**`arc setup`** — first-time only. Git identity + SSH key generation. Only needed on a fresh machine.

---

### arc expo — how it works and when to use it

The problem it solves: Expo's built-in `--tunnel` uses an old version of ngrok that conflicts with the system-installed ngrok v3. The two can't run together. `arc expo` bypasses Expo's tunnel entirely and manages ngrok directly.

**What it does, in order:**
1. Kills any stale Metro process on port 8081
2. Kills any running ngrok tunnel
3. Starts a fresh ngrok tunnel pointing at port 8081
4. Polls the ngrok local API (at `127.0.0.1:4040`) until it gets the public HTTPS URL
5. Starts Expo with `EXPO_PACKAGER_PROXY_URL` set to that URL
6. Expo generates a QR code using the ngrok URL — scan it in Expo Go

**Normal session flow:**
```bash
arc expo              # one command — wait ~10 seconds for "tunnel: https://..."
                      # QR appears — scan with Expo Go
                      # done
```

**When the tunnel URL changes between sessions:**  
Every time you run `arc expo`, ngrok generates a new random URL (free plan). That is expected. Expo Go needs to rescan the new QR each session. There is no way around this on the free plan without a paid ngrok account with static domains.

**If it hangs waiting for ngrok:**  
The script waits up to 20 seconds. If it prints "ngrok failed to start," check:
- `ngrok` is installed: `which ngrok`
- ngrok authtoken is set: `cat ~/.ngrok2/ngrok.yml` or `cat ~/.config/ngrok/ngrok.yml`
- Port 4040 (ngrok's local API) isn't blocked: `curl http://127.0.0.1:4040/api/tunnels`

**Do not run `pnpm expo start --tunnel` directly.** That path uses `@expo/ngrok` which conflicts with the system ngrok. Always use `arc expo`.

---

### regular maintenance schedule

| Frequency | Command | Why |
|---|---|---|
| Every session start | `arc` | Health check — catch uncommitted work, dirty repos |
| Weekly | `arc update` | Keep system packages current |
| After a day away | `arc audit` | Make sure no repo drifted from remote |
| Monthly | `arc clean` | Reclaim disk from cache and tmp accumulation |
| When developing Kataleya | `arc expo` | Start the dev server cleanly |

---

### use case scenarios

**Scenario 1 — start of a development day**
```bash
arc             # check disk + repo status
                # → kataleya [main] clean · 2 ahead · 3h ago
                # → khaos [main] clean · 0 ahead · 1d ago
arc audit       # quick fetch to make sure nothing has drifted
arc expo        # start kataleya dev server
```

**Scenario 2 — disk is feeling full**
```bash
arc             # → disk: 18.2G used / 22G total (83%)
arc clean       # clear cache and tmp
arc             # → disk: 15.1G used / 22G total (69%)
                # → +3.1 GB reclaimed
```

**Scenario 3 — coming back after a week away**
```bash
arc audit       # fetch all repos, check ahead/behind
                # → kataleya: 0 ahead, 3 behind — consider pulling
cd ~/kataleya && git pull
arc             # clean bill of health
```

**Scenario 4 — expo won't start, port is busy**
```bash
arc expo        # handles it automatically — clears 8081 before starting
```

---

### mistakes to avoid

**Running `arc update` in the middle of active development**  
Updates can restart services or cause unexpected package state changes. Run it at the start or end of a session, not mid-flow.

**Running `arc clean` without checking disk first**  
`arc clean` deletes `~/.cache` entirely. Most of it is safe to remove, but if you're mid-build and have cached dependencies that took a long time to download, you'll rebuild them. Check `arc` first and only clean when disk pressure is real.

**Trusting `arc audit` as a substitute for reading your diffs**  
`arc audit` tells you whether changes exist, not what they are. It is a signal to go look, not a replacement for `git diff` and `git log`.

**Running `arc expo` while another Metro instance is open in a different terminal**  
The script kills port 8081, so it will terminate any running Metro process. If you have two terminal sessions, one will die. Close other Metro instances before running `arc expo`.

---

### is it safe on a public repo?

Yes. Neither file contains credentials, tokens, API keys, or personal data. The only project-specific content is the hardcoded path `$HOME/kataleya/artifacts/kataleya-app` in `arc expo` — which is a file path, not a secret. Safe to push and share.

The data `lt` stores (`~/.local/share/lt/`) never touches the repo — it's local-only.

---

## installing on a new machine

```bash
git clone git@github.com:kwasikontor45/kripts.git ~/khaos
cp ~/khaos/lt ~/khaos/arc ~/bin/
chmod +x ~/bin/lt ~/bin/arc
```

Make sure `~/bin` is in PATH. If not, add to `~/.zshrc`:
```bash
export PATH="$HOME/bin:$PATH"
```

Then:
```bash
arc setup       # git identity + SSH key if needed
lt              # dashboard should show clean state
```

---

*lt: one focus at a time. arc: one machine in a known state.*
