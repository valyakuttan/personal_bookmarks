#! /usr/bin/bash

ROOTDIR="/var/home/valyakuttan/.var/app/com.github.micahflee.torbrowser-launcher/data/torbrowser/tbb/x86_64/tor-browser/Browser/TorBrowser/Data/Browser/gv743m42.anonymous"
BOOKMARKS=$ROOTDIR"/places.sqlite"

# tmp variables
TMP=$(mktemp -d)
CURRENT="$TMP/current.sqlite"
NEXT="$TMP/next.sqlite"

# data variables
DATA="data"
BACKUP="$DATA/places.asc"

# git variables
REMOTE="origin"
BRANCH="main"

# commit message
# put current date as yyyy-mm-dd HH:MM:SS in $date
printf -v DATE '%(%Y-%m-%d %H:%M:%S)T' -1
MSG="Backup of $DATE"

# check whether new backup is required
echo "Enter the passphrase to decrypt backup: "
read PASSPHRASE
gpg --yes --batch --pinentry-mode=loopback --passphrase="$PASSPHRASE" --output "$CURRENT" -d "$BACKUP"

cp $BOOKMARKS $NEXT

if [ -f "$CURRENT" ] && [ -f "$NEXT" ]; then
  DIFF=$(diff "$CURRENT" "$NEXT")
  GIT_STATUS=$(git status --porcelain)

  if [ "$DIFF" != "" ] || [ "$GIT_STATUS" != "" ]; then
    # create data directory
    mkdir -p $DATA

    # encrypt file
    gpg --yes --batch --pinentry-mode=loopback --passphrase="$PASSPHRASE" --output "$BACKUP" --armor -c --s2k-cipher-algo AES256 "$NEXT"

    # commit changes
    git add .
    git status
    git commit -m "$MSG"
    git push "$REMOTE" "$BRANCH"

    echo "$MSG completed"
  else
    echo "The bookmarks not modified."
  fi
else
  echo "The files $CURRENT, $NEXT not found."
fi

# cleanup the tmp
rm -rf "$TMP"


