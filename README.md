# khaos

Personal command-line tools. Portable bash — runs on any Linux.

---

## install

```bash
git clone git@github.com:kwasikontor45/khaos.git ~/khaos
ln -s ~/khaos/arc ~/bin/arc
ln -s ~/khaos/lt ~/bin/lt
chmod +x ~/khaos/arc ~/khaos/lt
```

Make sure `~/bin` is in your PATH. If not, add this to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

After that, `~/bin/arc` and `~/bin/lt` are symlinks — edits in `~/khaos/` take effect immediately. No sync step needed.

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
arc expo              kataleya dev server — Expo tunnel + debug, one command
arc ref               list archived reference files
arc ref <name>        view archived file by name or keyword search
arc help              full help
```

---

## philosophy

Two tools. One for you, one for the machine.
Pure bash. No dependencies beyond standard Unix.
Runs anywhere Linux runs.
