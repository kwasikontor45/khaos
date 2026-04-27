# khaos

Command-line tools for system maintenance and daily focus. Pure bash — runs on any Linux.

---

## install

Pick whichever method works for you. All three end the same way — no folders left behind.

**Option 1 — SSH** (if you have a key set up)
```bash
git clone git@github.com:kwasikontor45/khaos.git ~/khaos
bash ~/khaos/install.sh
source ~/.zshrc
rm -rf ~/khaos
```

**Option 2 — HTTPS** (git, no SSH key needed)
```bash
git clone https://github.com/kwasikontor45/khaos.git ~/khaos
bash ~/khaos/install.sh
source ~/.zshrc
rm -rf ~/khaos
```

**Option 3 — ZIP** (no git, no SSH)
```bash
curl -L https://github.com/kwasikontor45/khaos/archive/refs/heads/main.zip -o khaos.zip
unzip khaos.zip
bash khaos-main/install.sh
source ~/.zshrc
rm -rf khaos.zip khaos-main
```

Installs `arc` and `lt` into `~/.local/bin` — a hidden folder, nothing visible added to your home directory.

**To update:** repeat whichever method you used.

---

## lt — your daily lieutenant

Task and note tracker. Stays out of your way until you need it.

```
lt                    dashboard: focus, tasks, latest note
lt do "task"          add a task  (auto-sets focus if empty)
lt done               mark focus complete, advance to next
lt focus              show what you're supposed to be doing
lt set "task"         set focus without adding to task list
lt tasks              list all pending and completed tasks
lt drop "partial"     remove a pending task by name
lt clear              remove all completed tasks
lt note "text"        save a timestamped note
lt notes              show last 10 notes
lt help               full help
```

Data lives in `~/.local/share/lt/` — never touches your home directory.

---

## arc — your system architect

System maintenance and git repo oversight.

```
arc                   status: disk usage + repo overview
arc update            apt update + upgrade + clean
arc clean             deep clean: user cache, tmp, apt
arc audit             full git audit: fetch, status, ahead/behind
arc setup             first-time git identity + ssh key
arc expo              expo dev server — set ARC_EXPO_DIR in your shell config
arc ref               list archived reference files
arc ref <name>        view archived file by name or keyword search
arc help              full help
```

Optional env vars — add to your shell config to customise:
```bash
export ARC_EXPO_DIR="/path/to/your/expo/project"  # required for arc expo
export ARC_REF_DIR="$HOME/.refs"                  # default: ~/archive
```

---

## uninstall

```bash
rm ~/.local/bin/arc ~/.local/bin/lt
```

If you also want to remove `lt`'s saved tasks and notes:
```bash
rm -rf ~/.local/share/lt/
```

---

## philosophy

Two tools. One for you, one for the machine.
Pure bash. No dependencies beyond standard Unix.
Runs anywhere Linux runs.
