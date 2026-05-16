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

# Scan home subdirs + USB repos dir for git repos
scan_repos() {
  for d in "$HOME"/*/; do
    [[ -d "$d/.git" ]] && echo "$d"
  done
  local usb_repos="/mnt/storage/dev-lab/repos"
  if [[ -d "$usb_repos" ]]; then
    for d in "$usb_repos"/*/; do
      [[ -d "$d/.git" ]] && echo "$d"
    done
  fi
}

# ── Status ─────────────────────────────────────────────────────────────────────
cmd_status() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc${N}  ${D}·${N}  ${W}$(whoami)@$(hostname)${N}"
  echo -e "$HR"
  echo -e "  ${C}disk${N}    $(disk_used) used  ${D}·${N}  $(disk_free) free  ${D}/  $(disk_total)  ($(disk_pct))${N}"

  if mountpoint -q /mnt/storage 2>/dev/null; then
    local uu uf
    uu=$(df -h /mnt/storage | awk 'NR==2 {print $3}')
    uf=$(df -h /mnt/storage | awk 'NR==2 {print $4}')
    echo -e "  ${C}usb ${N}    ${uu} used  ${D}·${N}  ${uf} free  ${D}/ /mnt/storage${N}"
  fi

  echo -e "$HR"
  echo -e "  ${C}repos${N}"

  local found=0
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
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
  done < <(scan_repos)

  (( found == 0 )) && echo -e "  ${D}no repos found${N}"
  echo -e "$HR"
}

# ── Health ─────────────────────────────────────────────────────────────────────
cmd_health() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc health${N}  —  system health"
  echo -e "$HR\n"

  # Disks
  echo -e "  ${C}disks${N}"
  local iu if_ it ip
  iu=$(df -h / | awk 'NR==2 {print $3}')
  if_=$(df -h / | awk 'NR==2 {print $4}')
  it=$(df -h / | awk 'NR==2 {print $2}')
  ip=$(df / | awk 'NR==2 {print $5}')
  echo -e "  ${D}·${N}  internal    ${iu} used · ${if_} free / ${it}  ${D}(${ip})${N}"

  if mountpoint -q /mnt/storage 2>/dev/null; then
    local uu uf ut up
    uu=$(df -h /mnt/storage | awk 'NR==2 {print $3}')
    uf=$(df -h /mnt/storage | awk 'NR==2 {print $4}')
    ut=$(df -h /mnt/storage | awk 'NR==2 {print $2}')
    up=$(df /mnt/storage | awk 'NR==2 {print $5}')
    echo -e "  ${G}·${N}  usb         ${uu} used · ${uf} free / ${ut}  ${D}(${up})${N}"
  else
    echo -e "  ${R}·${N}  usb         not mounted"
  fi

  # RAM
  echo ""
  echo -e "  ${C}memory${N}"
  local rm_used rm_avail rm_total
  rm_used=$(free -h | awk '/Mem:/ {print $3}')
  rm_avail=$(free -h | awk '/Mem:/ {print $7}')
  rm_total=$(free -h | awk '/Mem:/ {print $2}')
  echo -e "  ${D}·${N}  ram         ${rm_used} used · ${rm_avail} available / ${rm_total}"

  local sw_used sw_total
  sw_used=$(free -h | awk '/Swap:/ {print $3}')
  sw_total=$(free -h | awk '/Swap:/ {print $2}')
  echo -e "  ${D}·${N}  swap        ${sw_used} used / ${sw_total}"

  # Encryption layers
  echo ""
  echo -e "  ${C}encryption${N}"

  # Home (ecryptfs)
  if grep -q ecryptfs /proc/mounts 2>/dev/null; then
    echo -e "  ${G}✓${N}  home        ecryptfs active"
  else
    echo -e "  ${Y}?${N}  home        ecryptfs not detected"
  fi

  # Swap (luks)
  if swapon --show 2>/dev/null | grep -q mapper; then
    echo -e "  ${G}✓${N}  swap        LUKS encrypted"
  else
    echo -e "  ${D}·${N}  swap        ${D}(not luks or not active)${N}"
  fi

  # USB (luks) — check mapper device directly, no sudo needed
  if [[ -b /dev/mapper/storage_crypt ]]; then
    echo -e "  ${G}✓${N}  usb         LUKS open (storage_crypt)"
  else
    echo -e "  ${R}✗${N}  usb         LUKS not open"
  fi

  echo -e "\n$HR"
}

# ── Mount ──────────────────────────────────────────────────────────────────────
cmd_mount() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc mount${N}  —  manual USB remount"
  echo -e "$HR\n"

  if mountpoint -q /mnt/storage 2>/dev/null; then
    local uu uf
    uu=$(df -h /mnt/storage | awk 'NR==2 {print $3}')
    uf=$(df -h /mnt/storage | awk 'NR==2 {print $4}')
    echo -e "  ${G}✓${N}  already mounted  —  ${uu} used · ${uf} free"
    echo -e "$HR"
    return 0
  fi

  local PARTUUID="e60e3d97-03"
  local DEV="/dev/disk/by-partuuid/$PARTUUID"
  local KEY="/etc/luks/storage.key"

  if [[ ! -e "$DEV" ]]; then
    echo -e "  ${R}✗${N}  drive not found — is the USB plugged in?"
    echo -e "  ${D}PARTUUID: ${PARTUUID}${N}"
    echo -e "$HR"
    return 1
  fi

  echo -e "  ${C}opening LUKS container...${N}"
  if sudo cryptsetup open "$DEV" storage_crypt --key-file "$KEY"; then
    echo -e "  ${G}✓${N}  LUKS opened"
  else
    echo -e "  ${R}✗${N}  cryptsetup failed — key file issue?"
    echo -e "  ${D}key: ${KEY}${N}"
    echo -e "$HR"
    return 1
  fi

  echo -e "  ${C}mounting /mnt/storage...${N}"
  if sudo mount /dev/mapper/storage_crypt /mnt/storage; then
    echo -e "  ${G}✓${N}  mounted at /mnt/storage"
  else
    echo -e "  ${Y}!${N}  trying with exec flag..."
    sudo mount /dev/mapper/storage_crypt /mnt/storage -o exec
    echo -e "  ${G}✓${N}  mounted (exec)"
  fi

  echo -e "\n$HR"
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
  while IFS= read -r d; do
    [[ -z "$d" ]] && continue
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
  done < <(scan_repos)

  (( found == 0 )) && echo -e "  ${D}no repos found${N}"
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
  for entry in '.env' '*.env.local' '*.log' 'node_modules/' '.DS_Store' '__pycache__/' '*.pyc' '.expo/'; do
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

# ── Keys ───────────────────────────────────────────────────────────────────────
cmd_keys() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc keys${N}  —  SSH public keys"
  echo -e "$HR\n"

  local keys=(
    "$HOME/.ssh/id_ed25519:kwasikontor45 (primary)"
    "$HOME/.ssh/id_ed25519_k6:k6-bleedin6ed6e-k6 (contingency)"
  )

  for entry in "${keys[@]}"; do
    local path="${entry%%:*}"
    local label="${entry##*:}"
    echo -e "  ${C}${label}${N}"
    if [[ -f "${path}.pub" ]]; then
      echo -e "  ${G}✓${N}  ${path}.pub"
      echo -e "  ${D}$(cat "${path}.pub")${N}"
      echo -e "  ${D}test: ssh -T git@github.com${N}"
    else
      echo -e "  ${R}✗${N}  ${path}.pub not found"
    fi
    echo ""
  done

  echo -e "  ${D}to add a key: github.com › Settings › SSH and GPG keys › New SSH key${N}"
  echo -e "$HR"
}

# ── Auth ───────────────────────────────────────────────────────────────────────
cmd_auth() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc auth${N}  —  Proton Authenticator"
  echo -e "$HR\n"

  local APP="$HOME/ProtonAuthenticator.AppImage"
  if [[ ! -f "$APP" ]]; then
    echo -e "  ${R}✗${N}  ProtonAuthenticator.AppImage not found at ${APP}"
    echo -e "$HR"
    return 1
  fi

  echo -e "  ${C}launching...${N}"
  WEBKIT_DISABLE_DMABUF_RENDERER=1 "$APP" &>/dev/null &
  disown
  echo -e "  ${G}✓${N}  Proton Authenticator launched (background)"
  echo -e "\n  ${D}note: TOTP seed was on lost iPhone. If codes don't appear,${N}"
  echo -e "  ${D}use GitHub support to reset 2FA:${N}"
  echo -e "  ${D}https://support.github.com/contact${N}"
  echo -e "$HR"
}

# ── Expo ───────────────────────────────────────────────────────────────────────
cmd_expo() {
  local mode_arg="${1:-}"
  local PROJECT_DIR="${ARC_EXPO_DIR:-}"

  echo -e "$HR"
  echo -e "  ${C}${B}arc expo${N}  —  expo dev server"
  echo -e "$HR\n"

  if [[ -z "$PROJECT_DIR" ]]; then
    echo -e "  ${R}ARC_EXPO_DIR is not set${N}"
    echo -e "  ${D}add to ~/.bashrc:${N}"
    echo -e "  ${D}export ARC_EXPO_DIR=\"/path/to/expo/project\"${N}"
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

  # Mode: explicit arg > env var > tunnel default
  local MODE
  if [[ "$mode_arg" == "lan" ]]; then
    MODE="lan"
  elif [[ "$mode_arg" == "tunnel" ]]; then
    MODE="tunnel"
  else
    MODE="${ARC_EXPO_MODE:-tunnel}"
  fi

  echo -e "  ${D}mode: --${MODE}${N}"
  echo -e "${C}starting Expo...${N}"
  echo -e "$HR\n"

  cd "$PROJECT_DIR" || return 1

  local PKG
  if [[ -f pnpm-lock.yaml ]]; then
    PKG="pnpm"
  elif [[ -f yarn.lock ]]; then
    PKG="yarn"
  else
    PKG="npx"
  fi

  $PKG expo start --$MODE --clear
}

# ── Deploy ─────────────────────────────────────────────────────────────────────
cmd_deploy() {
  local ATHENA_DIR="/mnt/storage/dev-lab/repos/athena"

  echo -e "$HR"
  echo -e "  ${C}${B}arc deploy${N}  —  build + deploy Athena to Cloudflare"
  echo -e "$HR\n"

  if [[ ! -d "$ATHENA_DIR" ]]; then
    echo -e "  ${R}✗${N}  athena repo not found at ${ATHENA_DIR}"
    echo -e "  ${D}is the USB drive mounted? try: arc mount${N}"
    echo -e "$HR"
    return 1
  fi

  cd "$ATHENA_DIR" || return 1

  echo -e "  ${C}building...${N}"
  if node node_modules/vite/bin/vite.js build; then
    echo -e "  ${G}✓${N}  build complete"
  else
    echo -e "  ${R}✗${N}  build failed — check errors above"
    echo -e "$HR"
    return 1
  fi

  echo ""
  echo -e "  ${C}deploying to Cloudflare Pages...${N}"
  if npx wrangler pages deploy dist --project-name athena --branch main --commit-dirty=true; then
    echo -e "\n  ${G}✓${N}  deployed → athena.kontor.studio"
  else
    echo -e "\n  ${R}✗${N}  deploy failed — check wrangler auth"
    echo -e "  ${D}wrangler config: ~/.config/.wrangler/config/default.toml${N}"
  fi

  echo -e "\n$HR"
}

# ── Mirror ─────────────────────────────────────────────────────────────────────
cmd_mirror() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc mirror${N}  —  push repo to k6 contingency"
  echo -e "$HR\n"

  local dir
  dir=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$dir" ]]; then
    echo -e "  ${R}✗${N}  not inside a git repo"
    echo -e "  ${D}cd into a repo first, then run arc mirror${N}"
    echo -e "$HR"
    return 1
  fi

  local name
  name=$(basename "$dir")
  local remote="git@github-k6:k6-bleedin6ed6e-k6/${name}.git"

  echo -e "  ${C}repo:${N}   ${name}"
  echo -e "  ${C}target:${N} ${remote}\n"

  echo -e "  ${C}pushing all branches...${N}"
  git -C "$dir" push "$remote" --all && echo -e "  ${G}✓${N}  branches pushed"

  echo -e "  ${C}pushing tags...${N}"
  git -C "$dir" push "$remote" --tags && echo -e "  ${G}✓${N}  tags pushed"

  echo -e "\n$HR"
}

# ── Day ────────────────────────────────────────────────────────────────────────
cmd_day() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc day${N}  —  morning startup"
  echo -e "$HR\n"

  echo -e "  ${C}storage drive${N}"
  if mountpoint -q /mnt/storage 2>/dev/null; then
    local usb_used usb_free
    usb_used=$(df -h /mnt/storage | awk 'NR==2 {print $3}')
    usb_free=$(df -h /mnt/storage | awk 'NR==2 {print $4}')
    echo -e "  ${G}✓${N}  /mnt/storage mounted  —  ${usb_used} used · ${usb_free} free"
  else
    echo -e "  ${R}✗${N}  USB not mounted — run ${C}arc mount${N} or plug in and wait ~5s"
    echo -e "\n$HR"
    return 1
  fi

  local STAMP="$HOME/.usb-bakup/.last-sync"
  echo ""
  echo -e "  ${C}backup${N}"
  if [[ -f "$STAMP" ]]; then
    echo -e "  ${D}·${N}  last sync: $(cat "$STAMP")"
  else
    echo -e "  ${Y}!${N}  no backup on record — run ${C}arc backup${N} before you start"
  fi

  echo ""
  echo -e "$HR"
  cmd_status
}

# ── Backup ─────────────────────────────────────────────────────────────────────
cmd_backup() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc backup${N}  —  USB → ~/.usb-bakup"
  echo -e "$HR\n"

  local BAKUP_SCRIPT
  BAKUP_SCRIPT=$(command -v bakup-usb 2>/dev/null)
  if [[ -z "$BAKUP_SCRIPT" ]]; then
    for p in "$HOME/local-dev/bakup-usb" "$HOME/.local/bin/bakup-usb"; do
      [[ -x "$p" ]] && BAKUP_SCRIPT="$p" && break
    done
  fi

  if [[ -z "$BAKUP_SCRIPT" ]]; then
    echo -e "  ${R}bakup-usb not found${N}"
    echo -e "  ${D}expected at ~/local-dev/bakup-usb${N}"
    echo -e "$HR"
    return 1
  fi

  bash "$BAKUP_SCRIPT"
  echo -e "$HR"
}

# ── Stop ───────────────────────────────────────────────────────────────────────
cmd_stop() {
  echo -e "$HR"
  echo -e "  ${C}${B}arc stop${N}  —  safe end-of-day shutdown"
  echo -e "$HR\n"

  local killed=0
  for pat in "expo start" "metro" "npx expo" "node_modules/.bin/expo"; do
    if pgrep -f "$pat" &>/dev/null; then
      pkill -f "$pat" 2>/dev/null && echo -e "  ${G}✓${N}  killed: $pat" && killed=1
    fi
  done
  (( killed == 0 )) && echo -e "  ${D}·${N}  no dev servers running"

  echo ""
  echo -e "  ${C}running backup before unmount...${N}"
  cmd_backup

  echo ""
  if mountpoint -q /mnt/storage 2>/dev/null; then
    echo -e "  ${C}unmounting storage drive...${N}"
    if sudo umount /mnt/storage 2>/dev/null; then
      echo -e "  ${G}✓${N}  /mnt/storage unmounted"
      sudo cryptsetup close storage_crypt 2>/dev/null && \
        echo -e "  ${G}✓${N}  LUKS container closed"
      echo -e "\n  ${G}safe to unplug the drive.${N}"
    else
      echo -e "  ${R}✗${N}  unmount failed — check for open files"
      echo -e "     ${D}lsof +D /mnt/storage${N}"
    fi
  else
    echo -e "  ${D}·${N}  drive not mounted — nothing to unmount"
  fi
  echo -e "\n$HR"
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
    echo -e "  ${D}export ARC_REF_DIR=\"\$HOME/your-folder\"  # add to ~/.bashrc${N}"
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
  echo -e "  ${W}arc${N}                  status: disk usage + repo overview"
  echo -e "  ${W}arc day${N}              morning startup: USB check, backup status, repos"
  echo -e "  ${W}arc backup${N}           sync USB → ~/.usb-bakup (additive, nothing deleted)"
  echo -e "  ${W}arc stop${N}             end-of-day: kill servers, backup, unmount USB"
  echo -e "  ${D}──${N}"
  echo -e "  ${W}arc deploy${N}           build + deploy Athena → athena.kontor.studio"
  echo -e "  ${W}arc expo${N}             expo dev server (tunnel default) — set ARC_EXPO_DIR"
  echo -e "  ${W}arc expo lan${N}         expo dev server — LAN mode (same Wi-Fi)"
  echo -e "  ${W}arc mirror${N}           push current repo → k6 contingency account"
  echo -e "  ${D}──${N}"
  echo -e "  ${W}arc health${N}           disks, RAM, all encryption layers"
  echo -e "  ${W}arc mount${N}            manual USB remount (PARTUUID-based, port-agnostic)"
  echo -e "  ${W}arc keys${N}             show SSH public keys for both GitHub accounts"
  echo -e "  ${W}arc auth${N}             launch Proton Authenticator"
  echo -e "  ${D}──${N}"
  echo -e "  ${W}arc update${N}           apt update + upgrade + clean"
  echo -e "  ${W}arc clean${N}            deep clean: user cache, tmp, apt"
  echo -e "  ${W}arc audit${N}            full git audit: fetch, status, ahead/behind"
  echo -e "  ${W}arc setup${N}            first-time git identity + ssh key"
  echo -e "  ${W}arc ref [name]${N}       list or search archived references"
  echo -e "  ${W}arc help${N}             this screen"
  echo -e "$HR"
}

# ── Router ─────────────────────────────────────────────────────────────────────
case "${1:-}" in
  day)            cmd_day ;;
  backup)         cmd_backup ;;
  stop)           cmd_stop ;;
  health)         cmd_health ;;
  mount)          cmd_mount ;;
  deploy)         cmd_deploy ;;
  mirror)         cmd_mirror ;;
  keys)           cmd_keys ;;
  auth)           cmd_auth ;;
  expo)           cmd_expo "${2:-}" ;;
  update)         cmd_update ;;
  clean)          cmd_clean ;;
  audit)          cmd_audit ;;
  setup)          cmd_setup ;;
  ref)            cmd_ref "${2:-}" ;;
  help|-h|--help) cmd_help ;;
  '')             cmd_status ;;
  *)              echo -e "${R}unknown:${N} $1  —  try ${C}arc help${N}"; exit 1 ;;
esac
