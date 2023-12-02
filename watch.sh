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

check_cmd() {
  command -v "$1" &>/dev/null
}

required_cmd() {
  if ! check_cmd "$1"; then
    red "\`$1\` was not configured."
    cfg_err=1
  fi
}

watch_cmd() {
  inotifywait -e modify,move_self -r . 2>/dev/null
}

usage() {
  cat <<END
Usage: $0 [options]

Options:
  -h                  : Show this help message
  -b build_script     : Script to run when \`watch_script\` detects new changes
  -r run_script       : Script to run when the build is completed
  -w watch_script     : Script to detect file changes

END

  exit "$1"
}

if [[ -f watch.cfg.sh ]]; then
  source watch.cfg.sh
  if [[ "$?" -ne "0" ]]; then
    red "Error when loading config."
    exit 1
  fi
fi

while getopts 'b:r:w:h' opt; do
  case "${opt}" in
    b)
      build_cmd_="$OPTARG"
      build_cmd() {
        bash -c "$build_cmd_"
      }
      ;;
    r)
      run_cmd_="$OPTARG"
      run_cmd() {
        bash -c "$run_cmd_"
      }
      ;;
    w)
      watch_cmd_="$OPTARG"
      watch_cmd() {
        bash -c "$watch_cmd_"
      }
      ;;
    h) usage 0;;
    *) usage 1;;
  esac
done

required_cmd run_cmd
required_cmd watch_cmd

if [[ -n "$cfg_err" ]]; then
  exit 1
fi

watch_pid=`mktemp -t watch_pid.XXX`
run_pid=`mktemp -t run_pid.XXX`

build() {
  if ! check_cmd "build_cmd"; then
    return 0
  fi

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
