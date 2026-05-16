# khaos

Command-line tools for system maintenance and daily focus. Pure bash — runs on any Linux.

---

## install

Pick whichever method works for you. All three end the same way — no folders left behind.

**Option 1 — SSH** (if you have a key set up)
```bash
git clone git@github.com:kwasikontor45/khaos.git ~/khaos
bash ~/khaos/install.sh
source ~/.bashrc
rm -rf ~/khaos
```

**Option 2 — HTTPS** (git, no SSH key needed)
```bash
git clone https://github.com/kwasikontor45/khaos.git ~/khaos
bash ~/khaos/install.sh
source ~/.bashrc
rm -rf ~/khaos
```

**Option 3 — ZIP** (no git, no SSH)
```bash
curl -L https://github.com/kwasikontor45/khaos/archive/refs/heads/main.zip -o khaos.zip
unzip khaos.zip
bash khaos-main/install.sh
source ~/.bashrc
rm -rf khaos.zip khaos-main
```

Installs `arc` and `lt` into `~/.local/bin` — nothing visible added to your home directory.

**To update:** repeat whichever method you used.

---

## lt — your daily lieutenant

Task and note tracker. Stays out of your way until you need it.

```
lt                        dashboard: focus, tasks, latest note
lt do "task"              add a task  (auto-sets focus if empty)
lt done                   mark focus complete, advance to next
lt focus                  show what you're supposed to be doing
lt set "task"             set focus without adding to task list
lt tasks                  list all pending and completed tasks
lt drop "partial"         remove a pending task by name
lt clear                  remove all completed tasks
lt note "text"            save a timestamped note
lt note drop "partial"    remove a note by partial text match
lt notes                  show last 10 notes
lt help                   full help
```

Data lives in `~/.local/share/lt/` — never touches your home directory.

---

## arc — your system architect

System maintenance, git oversight, and dev workflow automation.

```
arc                       status: disk + repo overview
arc day                   morning startup: USB check, backup status, repos
arc backup                sync USB → ~/.usb-bakup (additive, nothing deleted)
arc stop                  end-of-day: kill servers, backup, unmount USB safely

arc deploy                build + deploy Athena → Cloudflare Pages
arc expo                  expo dev server (tunnel mode) — set ARC_EXPO_DIR
arc expo lan              expo dev server — LAN mode (same Wi-Fi)
arc mirror                push current repo → contingency account

arc health                disks, RAM, all encryption layers
arc mount                 manual USB remount (PARTUUID-based, port-agnostic)
arc keys                  show SSH public keys for all GitHub accounts
arc auth                  launch Proton Authenticator

arc update                apt update + upgrade + clean
arc clean                 deep clean: user cache, tmp, apt
arc audit                 full git audit: fetch, status, ahead/behind
arc setup                 first-time git identity + ssh key
arc ref [name]            list or search archived references
arc help                  full help
```

Optional env vars — add to `~/.bashrc` to customise:
```bash
export ARC_EXPO_DIR="/path/to/your/expo/project"  # required for arc expo
export ARC_EXPO_MODE="tunnel"                      # tunnel (default) or lan
export ARC_REF_DIR="$HOME/.refs"                  # default: ~/archive
```

Scans for git repos in `~/` and `/mnt/storage/dev-lab/repos/` automatically.

---

## uninstall

```bash
rm ~/.local/bin/arc ~/.local/bin/lt
```

To also remove `lt`'s saved tasks and notes:
```bash
rm -rf ~/.local/share/lt/
```

---

## philosophy

Two tools. One for you, one for the machine.
Pure bash. No dependencies beyond standard Unix.
Runs anywhere Linux runs.
