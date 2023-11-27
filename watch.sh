#!/usr/bin/bash

cfg_err=
if [[ -f watch.cfg.sh ]]; then
    source watch.cfg.sh

    check_cmd() {
        if ! command -v "$1" &>/dev/null; then
            echo -e "\033[1;31m\`$1\` was not configured.\033[0m"
            cfg_err=1
        fi
    }

    check_cmd build_cmd
    check_cmd run_cmd
    check_cmd watch_cmd
else
    echo -e "\033[1;31m\`watch.cfg.sh\` file was not found.\033[0m"
    cfg_err=1
fi

if [[ -n "$cfg_err" ]]; then
    exit 1
fi

watch_pid=`mktemp -t watch_pid.XXX`
run_pid=`mktemp -t run_pid.XXX`

build() {
    echo -e "\033[1;32mBuilding...\033[0m"
    build_cmd
    ret=$?
    echo -e "\033[1;32mBuild completed.\033[0m"
    return $ret
}

run() {
    kill_pid $run_pid
    echo -e "\033[1;33mRunning program...\033[0m"
    (run_cmd; echo -e "\033[1;33mProgram exited with code $?.\033[0m") &
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
    echo -e "\033[1;33mWatching file change...\033[0m"
    while watch_cmd 2>/dev/null; do
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
