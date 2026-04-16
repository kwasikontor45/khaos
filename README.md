# kripts

Personal command-line tools. Portable bash — runs on any Linux.

---

## install

```bash
git clone git@github.com:kwasikontor45/kripts.git ~/kripts
cp ~/kripts/lt ~/kripts/arc ~/bin/
chmod +x ~/bin/lt ~/bin/arc
```

Make sure `~/bin` is in your PATH. If not, add this to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/bin:$PATH"
```

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
arc help              full help
```

---

## philosophy

Two tools. One for you, one for the machine.  
Pure bash. No dependencies beyond standard Unix.  
Runs anywhere Linux runs.

---

*part of the kontor.studio toolkit*
