#!/bin/sh

# Configure wayland environment if needed
if [[ $XDG_SESSION_TYPE == wayland ]]; then
    export MOZ_ENABLE_WAYLAND=1
    export MOZ_DBUS_REMOTE=1
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
    export SDL_VIDEODRIVER=wayland
    export CLUTTER_BACKEND=wayland
    export ECORE_EVAS_ENGINE=wayland_egl
    export _JAVA_AWT_WM_NONREPARENTING=1
done;
