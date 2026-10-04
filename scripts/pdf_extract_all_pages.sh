#!/bin/zsh
set -u

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

notify() {
  [[ "${PDF_IMAGE_ACTION_QUIET:-0}" == "1" ]] && return 0
  /usr/bin/osascript -e "display notification \"$1\" with title \"Extract PDF as Images\"" >/dev/null 2>&1 || true
}

alert() {
  if [[ "${PDF_IMAGE_ACTION_QUIET:-0}" == "1" ]]; then print -r -- "$1" >&2; return 0; fi
  /usr/bin/osascript -e "display alert \"Extract PDF as Images\" message \"$1\" as warning" >/dev/null 2>&1 || true
}

escape_applescript() {
  /usr/bin/sed 's/\\/\\\\/g; s/"/\\"/g'
}

unique_dir() {
  local base_dir="$1"
  local candidate="$base_dir"
  local index=2

  while [[ -e "$candidate" ]]; do
    candidate="${base_dir}_${index}"
    index=$((index + 1))
  done

  print -r -- "$candidate"
}

if ! command -v pdftoppm >/dev/null 2>&1; then
  alert "pdftoppm was not found. Install Poppler first: brew install poppler"
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  alert "Select one or more PDF files in Finder first."
  exit 1
fi

log_file="$(/usr/bin/mktemp -t pdf-extract-all)" || exit 1
trap '/bin/rm -f "$log_file"' EXIT

converted=0
errors=()
last_output=""

for pdf in "$@"; do
  if [[ ! -f "$pdf" || "${pdf:e:l}" != "pdf" ]]; then
    errors+=("Skipped non-PDF file: $(basename "$pdf")")
    continue
  fi

  parent_dir="$(dirname "$pdf")"
  stem="${${pdf:t}%.*}"
  output_dir="$(unique_dir "$parent_dir/${stem}_images")"

  if ! /bin/mkdir -p "$output_dir"; then
    errors+=("Could not create output folder: $output_dir")
    continue
  fi

  if pdftoppm -png -r 200 "$pdf" "$output_dir/$stem" >"$log_file" 2>&1; then
    converted=$((converted + 1))
    last_output="$output_dir"
  else
    message="$(/bin/cat "$log_file" 2>/dev/null | /usr/bin/tail -n 3 | escape_applescript)"
    errors+=("Conversion failed: $(basename "$pdf") ${message}")
    /bin/rm -rf "$output_dir"
  fi
done

if [[ "$converted" -gt 0 ]]; then
  notify "Converted ${converted} PDF file(s)."
  if [[ -n "$last_output" && "${PDF_IMAGE_ACTION_SKIP_REVEAL:-0}" != "1" ]]; then
    /usr/bin/open -R "$last_output" >/dev/null 2>&1 || true
  fi
fi

if [[ "${#errors[@]}" -gt 0 ]]; then
  alert "$(printf '%s\n' "${errors[@]}" | escape_applescript)"
fi

exit $(( ${#errors[@]} > 0 ))
