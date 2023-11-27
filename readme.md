# Watch.sh

A simple script to watch for file changes in the project, enabling automatic recompilation and execution.

Just do: `watch.sh`

- type `bs` to rebuild the project.
- type `rs` to rerun the built program.
- type `exit` or `Ctrl-C` to stop watching.

# Install

```sh
sudo curl -sL https://raw.githubusercontent.com/Sherly1001/watch.sh/main/watch.sh -o /usr/local/bin/watch.sh
sudo chmod +x /usr/local/bin/watch.sh
```

# Example

Create a file named `watch.cfg.sh` inside the root directory of your project and define three commands: `build_cmd`, `run_cmd`, and `watch_cmd`.

```sh
# watch.cfg.sh

build_cmd() {
    meson compile -C build
}

run_cmd() {
    ./build/main
}

watch_cmd() {
    inotifywait -e modify -r src include meson.build
}
```
