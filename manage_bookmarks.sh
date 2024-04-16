#!/usr/bin/bash

function retrieve_backup() {
  local passphrase="$1"
  local output_file_path="$2"
  local file_path="$3"

  gpg --yes --batch --pinentry-mode=loopback --passphrase="${passphrase}" --output "${output_file_path}" -d "${file_path}"
}

function encrypt_backup() {
  local passphrase="$1"
  local output_file_path="$2"
  local file_path="$3"

  gpg --yes --batch --pinentry-mode=loopback --passphrase="${passphrase}" --output "${output_file_path}" --armor -c --s2k-cipher-algo AES256 "${file_path}"
}

function save_changes() {
  local message="$1"
  local remote="$2"
  local branch="$3"

  git add .
  git status
  git commit -m "${message}"
  git push "${remote}" "${branch}"

  echo "${message} completed"
}

function backup_bookmarks() {
  local backup_file="$1"
  local passphrase="$2"
  local bookmarks="$3"
  local commit_message="$4"
  local git_remote="$5"
  local git_branch="$6"

  local backup_location="$(dirname '${backup_file}')"

  #printf "backup_location = %s\n backup_file = %s\n passphrase = %s\n bookmarks = %s\n ommit_message = %s\n git_remote = %s\n git_branch = %s\n" "${backup_location}" "${backup_file}" "${passphrase}" "${bookmarks}" "${commit_message}" "${git_remote}" "${git_branch}"
  #exit 0

  # tmp variables
  tmp="$(mktemp -d)"
  last_backup="${tmp}/places.sqlite"

  # make sure backup_location exists
  mkdir -p "${backup_location}"

  if [[ -f "${backup_file}" ]]; then
    retrieve_backup "${passphrase}" "${last_backup}" "${backup_file}"
    sqlite_diff="$(diff '${last_backup}' '${bookmarks}')"
    git_status="$(git status --porcelain)"

    if [[ -n "${sqlite_diff}" ]] || [[ -n "${git_status}" ]]; then
      encrypt_backup "${passphrase}" "${backup_file}" "${bookmarks}"
      save_changes "${commit_message}" "${git_remote}" "${git_branch}"
      else
        echo "Nothing to backup"
    fi
  else
    encrypt_backup "${passphrase}" "${backup_file}" "${bookmarks}"
    save_changes "${commit_message}" "${git_remote}" "${git_branch}"
  fi

  # cleanup tmp
  rm -rf "${tmp}"
}


function restore_bookmarks() {
  local backup_file="$1"
  local passphrase="$2"
  local bookmarks="$3"

  # tmp variables
  tmp="$(mktemp -d)"
  last_backup="${tmp}/places.sqlite"

  retrieve_backup "${passphrase}" "${last_backup}" "${backup_file}"
  cp "${last_backup}" "${bookmarks}"

  # cleanup tmp
  rm -rf "${tmp}"

}

# command
command="$1"

# root_dir
root_dir="$2"

# passphrase
passphrase="$3"

# bookmarks
bookmarks="${root_dir}/places.sqlite"


# data variables
backup_location="data"
backup_file="${backup_location}/places.asc"

# git variables
git_remote="origin"
git_branch="main"

# commit message
# put current date as yyyy-mm-dd HH:MM:SS in $date
printf -v current_date '%(%Y-%m-%d %H:%M:%S)T' -1
commit_message="backup of ${current_date}"


case "${command}" in
  backup)
    backup_bookmarks "${backup_file}" "${passphrase}" "${bookmarks}" "${commit_message}" "${git_remote}" "${git_branch}"
    ;;

  restore)
    restore_bookmarks "${backup_file}" "${passphrase}" "${bookmarks}"
    ;;

  *)
    error "Unknowm command '${command}'"
    ;;

esac
