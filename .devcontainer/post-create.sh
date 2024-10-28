#!/usr/bin/env bash

mkdir -p /workspaces/jukebox/.vscode
cp /workspaces/jukebox/.devcontainer/artifacts/vscode/* /workspaces/jukebox/.vscode

sudo cp -r /workspaces/jukebox/runners/base/deps/gstreamer/subprojects/packages/* /usr
