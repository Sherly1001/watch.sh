#!/usr/bin/bash
# vi: ts=2 sw=2

color_print() {
  echo -e "\033[$1m$2\033[0m"
}

red() {
  color_print "1;31" "$1"
}

green() {
  color_print "1;32" "$1"
}

yellow() {
  color_print "1;33" "$1"
}

cfg_err=
if [[ -f watch.cfg.sh ]]; then
  source watch.cfg.sh
  if [[ "$?" -ne "0" ]]; then
    red "Error when loading config."
    cfg_err=1
  else
    check_cmd() {
      if ! command -v "$1" &>/dev/null; then
        red "\`$1\` was not configured."
        cfg_err=1
      fi
    }

    check_cmd build_cmd
    check_cmd run_cmd
    check_cmd watch_cmd
  fi
else
  red "\`watch.cfg.sh\` file was not found."
  cfg_err=1
fi

if [[ -n "$cfg_err" ]]; then
  exit 1
fi

watch_pid=`mktemp -t watch_pid.XXX`
run_pid=`mktemp -t run_pid.XXX`

build() {
  green "Building..."
  build_cmd
  ret=$?
  green "Build completed."
  return $ret
}

run() {
  kill_pid $run_pid
  yellow "Running program..."
  (run_cmd; yellow "Program exited with code $?.") &
  echo $! > $run_pid
}

build_and_run() {
  build && run
}

kill_pid() {
  pid=`cat $1 2>/dev/null`

  if [[ -z "$pid" ]]; then
    return 0
  fi

  for child in `pgrep -P $pid`; do
    kill $child &>/dev/null
  done

  kill $pid &>/dev/null
}

kill_watch() {
  kill_pid $watch_pid
  kill_pid $run_pid
  rm -f $watch_pid
  rm -f $run_pid
  exit 0
}

watch() {
  yellow "Watching file change..."
  while watch_cmd; do
    build_and_run
  done
}

handle_input() {
  read line
  if [[ "$line" = "rs" ]]; then
    run
  elif [[ "$line" = "bs" ]]; then
    build_and_run
  elif [[ "$line" = "exit" ]]; then
    kill_watch
  fi
}

trap kill_watch SIGINT SIGTERM

watch & echo $! > $watch_pid
build_and_run
while true; do
  handle_input
done
