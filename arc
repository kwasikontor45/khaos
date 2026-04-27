#!/bin/bash
# arc — your system architect
# usage: arc [command]

# ── Colors ─────────────────────────────────────────────────────────────────────
C='\033[0;36m'   # cyan
G='\033[0;32m'   # green
R='\033[0;31m'   # red
Y='\033[1;33m'   # yellow
D='\033[0;90m'   # dim
W='\033[0;37m'   # white
B='\033[1m'      # bold
N='\033[0m'      # reset

HR="${D}────────────────────────────────────────────────${N}"

# ── Helpers ────────────────────────────────────────────────────────────────────
disk_used()  { df -h / | awk 'NR==2 {print $3}'; }
disk_total() { df -h / | awk 'NR==2 {print $2}'; }
disk_free()  { df -h / | awk 'NR==2 {print $4}'; }
disk_pct()   { df /   | awk 'NR==2 {print $5}'; }
disk_kb()    { df /   | awk 'NR==2 {print $4}'; }

saved_mb() {
  local start="$1" end="$2"
  local diff=$(( end - start ))
  if (( diff > 0 )); then
    echo "scale=1; $diff / 1024" | bc 2>/dev/null || echo "?"
  else
    echo "0"
  fi
}

repo_info() {
  local dir="$1"
  local branch ahead behind short
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  short=$(git -C "$dir" status --short 2>/dev/null)
  ahead=$(git -C "$dir" rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
  behind=$(git -C "$dir" rev-list HEAD..@{u} 2>/dev/null | wc -l | tr -d ' ')
  echo "$branch|$short|$ahead|$behind"
}

# ── Status ─────────────────────────────────────────────────────────────────────
cmd_status() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc${N}  ${D}·${N}  ${W}$(whoami)@$(hostname)${N}"
  echo -e "$HR"
  echo -e "  ${C}disk${N}    $(disk_used) used  ${D}·${N}  $(disk_free) free  ${D}/  $(disk_total)  ($(disk_pct))${N}"
  echo -e "$HR"
  echo -e "  ${C}repos${N}"

  local found=0
  for d in "$HOME"/*/; do
    [[ -d "$d/.git" ]] || continue
    found=1
    local name branch short ahead last status_str ahead_str
    name=$(basename "$d")
    branch=$(git -C "$d" branch --show-current 2>/dev/null)
    short=$(git -C "$d" status --short 2>/dev/null)
    ahead=$(git -C "$d" rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    last=$(git -C "$d" log -1 --format="%cr" 2>/dev/null || echo "no commits")

    if [[ -n "$short" ]]; then
      status_str="${Y}uncommitted${N}"
    else
      status_str="${G}clean${N}"
    fi

    ahead_str=""
    (( ahead > 0 )) && ahead_str="  ${D}·${N}  ${C}${ahead} ahead${N}"

    printf "  ${D}·${N}  %-20s  ${D}[%s]${N}  %b%b  ${D}%s${N}\n" \
      "$name" "$branch" "$status_str" "$ahead_str" "$last"
  done

  (( found == 0 )) && echo -e "  ${D}no repos found${N}"
  echo -e "$HR"
}

# ── Update ─────────────────────────────────────────────────────────────────────
cmd_update() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc update${N}  —  system refresh"
  echo -e "$HR\n"

  local start
  start=$(disk_kb)

  echo -e "${C}packages...${N}"
  sudo apt update && sudo apt upgrade -y

  echo -e "\n${C}cleanup...${N}"
  sudo apt autoremove -y && sudo apt clean

  local end mb
  end=$(disk_kb)
  mb=$(saved_mb "$start" "$end")

  echo -e "\n$HR"
  echo -e "  ${G}done${N}  ${D}·${N}  ${G}+${mb} MB reclaimed${N}"
  echo -e "  ${C}disk${N}    $(disk_used) used  ${D}·${N}  $(disk_free) free"
  echo -e "$HR"
}

# ── Clean ──────────────────────────────────────────────────────────────────────
cmd_clean() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc clean${N}  —  deep clean"
  echo -e "$HR\n"

  local start
  start=$(disk_kb)

  echo -e "${C}user cache...${N}"
  rm -rf ~/.cache/*

  echo -e "${C}tmp...${N}"
  sudo rm -rf /tmp/*

  echo -e "${C}apt...${N}"
  sudo apt autoremove -y && sudo apt clean

  local end mb
  end=$(disk_kb)
  mb=$(saved_mb "$start" "$end")

  echo -e "\n$HR"
  echo -e "  ${G}done${N}  ${D}·${N}  ${G}+${mb} MB reclaimed${N}"
  echo -e "  ${C}disk${N}    $(disk_used) used  ${D}·${N}  $(disk_free) free"
  echo -e "$HR"
}

# ── Audit ──────────────────────────────────────────────────────────────────────
cmd_audit() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc audit${N}  —  git repository audit"
  echo -e "$HR"

  local found=0
  for d in "$HOME"/*/; do
    [[ -d "$d/.git" ]] || continue
    found=1
    local name branch short ahead behind last
    name=$(basename "$d")
    branch=$(git -C "$d" branch --show-current 2>/dev/null)
    last=$(git -C "$d" log -1 --format="%cr" 2>/dev/null || echo "no commits")
    short=$(git -C "$d" status --short 2>/dev/null)

    echo -e "\n${C}fetching ${name}...${N}" >&2
    git -C "$d" fetch --prune &>/dev/null

    ahead=$(git -C "$d" rev-list @{u}..HEAD 2>/dev/null | wc -l | tr -d ' ')
    behind=$(git -C "$d" rev-list HEAD..@{u} 2>/dev/null | wc -l | tr -d ' ')

    if [[ -n "$short" ]]; then
      echo -e "\n  ${Y}⚠${N}  ${W}${name}${N}  ${D}[${branch}]${N}  ${D}·  ${last}${N}"
      echo "$short" | while IFS= read -r line; do
        echo -e "       ${D}${line}${N}"
      done
    else
      echo -e "\n  ${G}✓${N}  ${W}${name}${N}  ${D}[${branch}]${N}  ${D}·  ${last}${N}"
    fi

    (( ahead  > 0 )) && echo -e "       ${C}${ahead} commit(s) ahead of remote — push when ready${N}"
    (( behind > 0 )) && echo -e "       ${R}${behind} commit(s) behind remote — consider pulling${N}"
  done

  (( found == 0 )) && echo -e "  ${D}no repos found in home${N}"
  echo -e "\n$HR"
}

# ── Setup ──────────────────────────────────────────────────────────────────────
cmd_setup() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc setup${N}  —  git + ssh first-time configuration"
  echo -e "$HR\n"

  echo -e "${C}installing git...${N}"
  sudo apt update && sudo apt install git -y

  echo ""
  read -rp "  github username: " git_user
  read -rp "  github email:    " git_email

  git config --global user.name  "$git_user"
  git config --global user.email "$git_email"
  git config --global core.excludesfile ~/.gitignore_global
  git config --global init.defaultBranch main

  echo -e "\n${C}global gitignore...${N}"
  for entry in '.env' '*.log' 'node_modules/' '.DS_Store' '__pycache__/' '*.pyc' '.expo/'; do
    grep -qxF "$entry" ~/.gitignore_global 2>/dev/null || echo "$entry" >> ~/.gitignore_global
  done

  local key_is_new=0
  if [[ ! -f ~/.ssh/id_ed25519 ]]; then
    echo -e "\n${C}generating ssh key (ed25519)...${N}"
    ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519 -N ""
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    key_is_new=1
  else
    echo -e "\n${D}ssh key already exists — skipping keygen${N}"
  fi

  echo -e "\n$HR"
  if (( key_is_new )); then
    echo -e "  ${C}add this key to github.com › Settings › SSH keys${N}"
  else
    echo -e "  ${D}your existing key — only add to GitHub if not already done${N}"
  fi
  echo -e "$HR"
  cat ~/.ssh/id_ed25519.pub
  echo -e "$HR"
  echo -e "  ${D}test with:  ssh -T git@github.com${N}"
  echo -e "$HR"
}

# ── Expo ───────────────────────────────────────────────────────────────────────
cmd_expo() {
  local PROJECT_DIR="${ARC_EXPO_DIR:-}"

  echo -e "$HR"
  echo -e "  ${C}${B}arc expo${N}  —  expo dev server"
  echo -e "$HR\n"

  if [[ -z "$PROJECT_DIR" ]]; then
    echo -e "  ${R}ARC_EXPO_DIR is not set${N}"
    echo -e "  ${D}add to ~/.zshrc or ~/.bashrc:${N}"
    echo -e "  ${D}export ARC_EXPO_DIR=\"/path/to/your/expo/project\"${N}"
    echo -e "$HR"
    return 1
  fi

  # Kill stale Metro on 8081
  local stale
  stale=$(lsof -ti :8081 2>/dev/null || true)
  if [[ -n "$stale" ]]; then
    echo -e "${Y}clearing stale Metro on 8081...${N}"
    echo "$stale" | xargs kill -9 2>/dev/null || true
    sleep 1
  fi

  echo -e "${C}starting Expo...${N}"
  echo -e "$HR\n"

  cd "$PROJECT_DIR" && EXPO_DEBUG=1 pnpm expo start --tunnel --clear
}

# ── Ref ────────────────────────────────────────────────────────────────────────
cmd_ref() {
  local ARCHIVE="${ARC_REF_DIR:-$HOME/archive}"
  local query="${1:-}"

  echo -e "$HR"
  echo -e "  ${C}${B}arc ref${N}  —  archived references"
  echo -e "$HR"

  if [[ ! -d "$ARCHIVE" ]]; then
    echo -e "  ${R}no archive found${N}"
    echo -e ""
    echo -e "  create a folder and drop files into it:"
    echo -e "  ${D}mkdir ~/archive${N}"
    echo -e ""
    echo -e "  or point arc at an existing folder:"
    echo -e "  ${D}export ARC_REF_DIR=\"\$HOME/your-folder\"  # add to ~/.zshrc or ~/.bashrc${N}"
    echo -e "$HR"
    return 1
  fi

  if [[ -z "$query" ]]; then
    echo ""
    find "$ARCHIVE" -type f | sort | while IFS= read -r f; do
      local size rel
      size=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
      rel="${f#$ARCHIVE/}"
      printf "  ${D}·${N}  %-48s  ${D}%s b${N}\n" "$rel" "$size"
    done
    echo ""
    echo -e "  ${D}arc ref <name>     — view a file by name${N}"
    echo -e "  ${D}arc ref <keyword>  — search across all files${N}"
  else
    # Exact or partial filename match first
    local match
    match=$(find "$ARCHIVE" -type f -path "*${query}*" 2>/dev/null | head -1)
    if [[ -n "$match" ]]; then
      local rel="${match#$ARCHIVE/}"
      echo -e "\n  ${G}${rel}${N}\n"
      echo -e "$HR"
      case "$match" in
        *.docx|*.doc) echo -e "  ${D}binary — open manually:${N}\n  ${match}" ;;
        *)            cat "$match" ;;
      esac
    else
      # Search file contents
      echo -e "\n  ${C}searching: ${query}${N}\n"
      local hit=0
      while IFS= read -r f; do
        hit=1
        local rel="${f#$ARCHIVE/}"
        echo -e "  ${D}·${N}  ${W}${rel}${N}"
        grep -n "$query" "$f" 2>/dev/null | head -3 | while IFS= read -r line; do
          echo -e "       ${D}${line}${N}"
        done
      done < <(grep -rl "$query" "$ARCHIVE" 2>/dev/null)
      (( hit == 0 )) && echo -e "  ${D}nothing found for: ${query}${N}"
    fi
  fi
  echo -e "$HR"
}

# ── Help ───────────────────────────────────────────────────────────────────────
cmd_help() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc${N}  —  your system architect"
  echo -e "$HR"
  echo -e "  ${W}arc${N}              status: disk usage + repo overview"
  echo -e "  ${W}arc update${N}       apt update + upgrade + clean"
  echo -e "  ${W}arc clean${N}        deep clean: user cache, tmp, apt"
  echo -e "  ${W}arc audit${N}        full git audit: fetch, status, ahead/behind"
  echo -e "  ${W}arc setup${N}        first-time git identity + ssh key"
  echo -e "  ${W}arc expo${N}         expo dev server — set ARC_EXPO_DIR in your shell config"
  echo -e "  ${W}arc ref${N}          list archived references"
  echo -e "  ${W}arc ref <name>${N}   view archived file by name or keyword"
  echo -e "  ${W}arc help${N}         this screen"
  echo -e "$HR"
}

# ── Router ─────────────────────────────────────────────────────────────────────
case "${1:-}" in
  update)         cmd_update ;;
  clean)          cmd_clean ;;
  audit)          cmd_audit ;;
  setup)          cmd_setup ;;
  expo)           cmd_expo ;;
  ref)            cmd_ref "${2:-}" ;;
  help|-h|--help) cmd_help ;;
  '')             cmd_status ;;
  *)              echo -e "${R}unknown:${N} $1  —  try ${C}arc help${N}"; exit 1 ;;
esac
