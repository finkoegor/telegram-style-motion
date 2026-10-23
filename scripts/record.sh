#!/bin/zsh
# Records one scripted run of an app on the iOS Simulator.
#
# Usage: record.sh <out-dir> <simulator-udid> <bundle-id> [launch arguments...]
#
# Leaves rec.mp4 and taps.json in <out-dir>. The app must already be installed on the
# simulator. Recording stops when the app writes tmp/demo-taps.json into its container
# (the autopilot's timeline) or after $MAX_SECONDS (default 60).
#
# Environment:
#   APPEARANCE=light  light or dark appearance
#   TIME=9:41         status bar time; the bar is set to full signal and battery
#   CLIPBOARD=text    put text on the simulator's clipboard before launch
#   STATE_DIR=path    replace the app's Application Support folder with this one, for a
#                     known starting state
#   MAX_SECONDS=60    how long to wait for the timeline
set -e
OUT=${1:?out dir}
SIM=${2:?simulator udid}
APP=${3:?bundle id}
shift 3
mkdir -p $OUT

xcrun simctl boot $SIM 2>/dev/null || true
xcrun simctl bootstatus $SIM -b >/dev/null
xcrun simctl terminate $SIM $APP 2>/dev/null || true
DATA=$(xcrun simctl get_app_container $SIM $APP data)
rm -f "$DATA/tmp/demo-taps.json"
if [[ -n "$STATE_DIR" ]]; then
  rm -rf "$DATA/Library/Application Support"
  mkdir -p "$DATA/Library/Application Support"
  cp -R "$STATE_DIR" "$DATA/Library/Application Support/$(basename "$STATE_DIR")"
fi

[[ -n "$APPEARANCE" ]] && xcrun simctl ui $SIM appearance $APPEARANCE
if [[ -n "$TIME" ]]; then
  xcrun simctl status_bar $SIM override --time $TIME --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiMode active --wifiBars 3 --dataNetwork wifi
fi
[[ -n "$CLIPBOARD" ]] && printf "%s" "$CLIPBOARD" | xcrun simctl pbcopy $SIM

rm -f $OUT/rec.mp4 $OUT/taps.json
xcrun simctl io $SIM recordVideo --codec h264 --force $OUT/rec.mp4 >/dev/null 2>&1 &
REC=$!
sleep 1.5
xcrun simctl launch $SIM $APP "$@" >/dev/null
for i in $(seq 1 $(( ${MAX_SECONDS:-60} * 10 ))); do
  [[ -f "$DATA/tmp/demo-taps.json" ]] && break
  sleep 0.1
done
sleep 0.5
kill -INT $REC
wait $REC 2>/dev/null || true
if [[ -f "$DATA/tmp/demo-taps.json" ]]; then
  cp "$DATA/tmp/demo-taps.json" $OUT/taps.json
else
  echo "No timeline from the app; write $OUT/taps.json by hand" >&2
fi
[[ -n "$TIME" ]] && xcrun simctl status_bar $SIM clear
echo "$OUT/rec.mp4"
