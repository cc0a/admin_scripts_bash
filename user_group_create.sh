#!/bin/bash

#!/bin/bash

# Must be run as root
if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root."
  exit 1
fi

echo "=== User Creation Script ==="

# ---------------------------
# Username input
# ---------------------------
read -rp "Enter username: " USERNAME

if id "$USERNAME" &>/dev/null; then
  echo "❌ User '$USERNAME' already exists."
  exit 1
fi

# ---------------------------
# Password input (hidden)
# ---------------------------
read -rsp "Enter password: " PASSWORD
echo
read -rsp "Confirm password: " CONFIRM_PASSWORD
echo

if [[ "$PASSWORD" != "$CONFIRM_PASSWORD" ]]; then
  echo "❌ Passwords do not match."
  exit 1
fi

# ---------------------------
# Group selection
# ---------------------------
echo
echo "Available groups:"
mapfile -t GROUPS < <(getent group | cut -d: -f1)

declare -A GROUP_MAP
i=1
for group in "${GROUPS[@]}"; do
  echo "[$i] $group"
  GROUP_MAP[$i]=$group
  ((i++))
done

echo
read -rp "Select group numbers (space-separated): " GROUP_SELECTION

SELECTED_GROUPS=()
for num in $GROUP_SELECTION; do
  if [[ -n "${GROUP_MAP[$num]}" ]]; then
    SELECTED_GROUPS+=("${GROUP_MAP[$num]}")
  else
    echo "❌ Invalid group selection: $num"
    exit 1
  fi
done

GROUP_STRING=$(IFS=,; echo "${SELECTED_GROUPS[*]}")

# ---------------------------
# Home permission selection
# ---------------------------
echo
echo "Home directory permission options:"
echo "[1] 700  (user only)"
echo "[2] 750  (user + group)"
echo "[3] 755  (user + group + others)"
echo "[4] 770  (user + group full access)"

read -rp "Select permission option: " PERM_OPTION

case $PERM_OPTION in
  1) HOME_PERMS=700 ;;
  2) HOME_PERMS=750 ;;
  3) HOME_PERMS=755 ;;
  4) HOME_PERMS=770 ;;
  *)
    echo "❌ Invalid permission selection."
    exit 1
    ;;
esac

# ---------------------------
# Create user
# ---------------------------
useradd -m -s /bin/bash -G "$GROUP_STRING" "$USERNAME"

echo "$USERNAME:$PASSWORD" | chpasswd

chmod "$HOME_PERMS" "/home/$USERNAME"
chown "$USERNAME:$USERNAME" "/home/$USERNAME"

# ---------------------------
# Summary
# ---------------------------
echo
echo "✅ User '$USERNAME' created successfully!"
echo "Groups: ${SELECTED_GROUPS[*]}"
echo "Home directory: /home/$USERNAME"
echo "Permissions: $HOME_PERMS"
