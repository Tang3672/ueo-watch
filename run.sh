cd /home/ijw91021/ueo-watch

# make a backup
cp run.sh run.sh.bak.$(date +%Y%m%d_%H%M%S)

# write the new run.sh
cat > run.sh <<'EOF'
#!/bin/bash
set -x

echo "Running..."
date

# Get into a known directory
root_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$root_dir"

# --- ensure & activate venv; use venv binaries ---
if [ -z "${VIRTUAL_ENV:-}" ]; then
  [ -d ".venv" ] || python3 -m venv .venv
  source .venv/bin/activate
fi
URLWATCH="$VIRTUAL_ENV/bin/urlwatch"
PY="$VIRTUAL_ENV/bin/python"
SENDMAIL="/sbin/sendmail"   # /usr/sbin/sendmail on some distros

# ----- HOUSING -----
[ -f housing/cache.db ] && cp housing/cache.db housing/cache_before_latest_run.db.bak || true
"$URLWATCH" -v --hooks config/hooks.py --urls housing/urls.yaml --config housing/urlwatch.yaml --cache housing/cache.db \
  2> housing/urlwatch_debug.log 1> housing/urlwatch_output.log
if [ $? -gt 0 ]; then
  body="$(tail -n 50 housing/urlwatch_debug.log)"; now="$(date)"
  printf "Subject: urlwatch housing error [%s]\nFrom: Changebot <changebot@theunitedeffort.org>\nTo: trevor@theunitedeffort.org\n\n%s" "$now" "$body" | "$SENDMAIL" -oi -t
fi
if grep -q "ERROR: " housing/urlwatch_debug.log; then
  body="$(grep "ERROR: " housing/urlwatch_debug.log)"; now="$(date)"
  printf "Subject: urlwatch housing error [%s]\nFrom: Changebot <changebot@theunitedeffort.org>\nTo: trevor@theunitedeffort.org\n\n%s" "$now" "$body" | "$SENDMAIL" -oi -t
fi
"$URLWATCH" --urls housing/urls.yaml --config housing/urlwatch.yaml --cache housing/cache.db --gc-cache 5
timestamp=$(date +%Y%m%d_%H%M%S)
[ -f housing/cache.db ] && gsutil cp housing/cache.db "gs://ueo-changes/housing/cache/cache_$timestamp.db" || true

# ----- ELIGIBILITY -----
[ -f eligibility/cache.db ] && cp eligibility/cache.db eligibility/cache_before_latest_run.db.bak || true
"$URLWATCH" -v --hooks config/hooks.py --urls eligibility/urls.yaml --config eligibility/urlwatch.yaml --cache eligibility/cache.db \
  2> eligibility/urlwatch_debug.log 1> eligibility/urlwatch_output.log
if [ $? -gt 0 ]; then
  body="$(tail -n 50 eligibility/urlwatch_debug.log)"; now="$(date)"
  printf "Subject: urlwatch eligibility error [%s]\nFrom: Changebot <changebot@theunitedeffort.org>\nTo: trevor@theunitedeffort.org\n\n%s" "$now" "$body" | "$SENDMAIL" -oi -t
fi
if grep -q "ERROR: " eligibility/urlwatch_debug.log; then
  body="$(grep "ERROR: " eligibility/urlwatch_debug.log)"; now="$(date)"
  printf "Subject: urlwatch eligibility error [%s]\nFrom: Changebot <changebot@theunitedeffort.org>\nTo: trevor@theunitedeffort.org\n\n%s" "$now" "$body" | "$SENDMAIL" -oi -t
fi
"$URLWATCH" --urls eligibility/urls.yaml --config eligibility/urlwatch.yaml --cache eligibility/cache.db --gc-cache 5
timestamp=$(date +%Y%m%d_%H%M%S)
[ -f eligibility/cache.db ] && gsutil cp eligibility/cache.db "gs://ueo-changes/eligibility/cache/cache_$timestamp.db" || true

# ----- AUTOHOUSE -----
# build URL list
"$PY" autohouse/make_urls.py > autohouse/make_urls_debug.log 2>&1
if grep -qi "error: " autohouse/make_urls_debug.log; then
  body="$(grep -i -B 10 "error: " autohouse/make_urls_debug.log)"; now="$(date)"
  printf "Subject: autohouse make_urls error [%s]\nFrom: Changebot <changebot@theunitedeffort.org>\nTo: trevor@theunitedeffort.org\n\n%s" "$now" "$body" | "$SENDMAIL" -oi -t
fi

[ -f autohouse/cache.db ] && cp autohouse/cache.db autohouse/cache_before_latest_run.db.bak || true
"$URLWATCH" -v --hooks config/hooks.py --urls autohouse/urls.yaml --config autohouse/urlwatch.yaml --cache autohouse/cache.db \
  2> autohouse/urlwatch_debug.log 1> autohouse/urlwatch_output.log
if [ $? -gt 0 ]; then
  body="$(tail -n 50 autohouse/urlwatch_debug.log)"; now="$(date)"
  printf "Subject: urlwatch autohouse error [%s]\nFrom: Changebot <changebot@theunitedeffort.org>\nTo: trevor@theunitedeffort.org\n\n%s" "$now" "$body" | "$SENDMAIL" -oi -t
fi
if grep -q "ERROR: " autohouse/urlwatch_debug.log; then
  body="$(grep "ERROR: " autohouse/urlwatch_debug.log)"; now="$(date)"
  printf "Subject: urlwatch autohouse error [%s]\nFrom: Changebot <changebot@theunitedeffort.org>\nTo: trevor@theunitedeffort.org\n\n%s" "$now" "$body" | "$SENDMAIL" -oi -t
fi
"$URLWATCH" --urls autohouse/urls.yaml --config autohouse/urlwatch.yaml --cache autohouse/cache.db --gc-cache 5
timestamp=$(date +%Y%m%d_%H%M%S)
[ -f autohouse/cache.db ] && gsutil cp autohouse/cache.db "gs://ueo-changes/autohouse/cache/cache_$timestamp.db" || true

echo "Done."
EOF

chmod +x run.sh
