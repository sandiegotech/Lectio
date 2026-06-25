#!/bin/bash
# Wall-clock stop for the overnight loop — a stand-in for the 5-hour usage limit,
# since the meter can't be read programmatically.
#
#   guard.sh set 4.5     # arm a deadline 4.5h from now (≈90% of a 5h window)
#   guard.sh             # check: exits 0 (go) with minutes left, or 1 (stop) if past
#
# State lives in $OVERNIGHT_SCRATCH/deadline.txt ($OVERNIGHT_SCRATCH default /tmp/overnight).
SCRATCH="${OVERNIGHT_SCRATCH:-/tmp/overnight}"
mkdir -p "$SCRATCH"
DF="$SCRATCH/deadline.txt"

if [ "$1" = "set" ]; then
  hours="${2:-4.5}"
  now=$(date +%s)
  deadline=$(python3 -c "import sys;print(int(${now}+float('${hours}')*3600))")
  echo "$deadline" > "$DF"
  echo "Deadline set: $(date -r "$deadline" '+%-I:%M %p') (${hours}h from now)"
  exit 0
fi

d=$(cat "$DF" 2>/dev/null || echo 0)
now=$(date +%s)
if [ "$now" -ge "$d" ]; then
  echo "DEADLINE_REACHED ($(date -r "$d" '+%-I:%M %p'))"; exit 1
fi
echo "OK $(( (d - now) / 60 )) min left until stop"; exit 0
