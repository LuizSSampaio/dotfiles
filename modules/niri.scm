;; Niri window manager module for GNU Guix Home.
;; Installs a full Niri + Noctalia desktop stack with Gruvbox-oriented defaults.

(define-module (modules niri)
  #:use-module (gnu home services)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnome-xyz)
  #:use-module (gnu packages polkit)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu services)
  #:export (%niri-home-packages
            niri-home-services))

(define %gruvbox-wallpaper
  (origin
    (method url-fetch)
    (uri "https://gruvbox-wallpapers.pages.dev/wallpapers/pixelart/dock.png")
    (sha256
     (base32 "1zy60s7icrdvvdbmr4445g8mz6iqyxv1knxgy854r9dffh45xsdp"))))

(define %niri-config-file
  (mixed-text-file
   "niri-config.kdl"
   "input {
    keyboard {
        xkb {
            layout \"us\"
            variant \"intl\"
            options \"compose:caps\"
        }
        repeat-rate 40
        repeat-delay 600
    }

    touchpad {
        tap
        dwt
        natural-scroll
        scroll-factor 0.4
        accel-speed 0.2
    }

    mouse {
        accel-speed 0.0
    }

    focus-follows-mouse {
        on
        max-scroll-amount \"0%\"
    }
}

gestures {
    hot-corners {
        off
    }
}

layout {
    gaps 4

    preset-column-widths {
        proportion 0.33333333
        proportion 0.5
        proportion 0.66666667
    }

    default-column-width {
        proportion 0.5
    }

    border {
        on
        width 2
        active-color \"#d79921\"
        inactive-color \"#504945\"
    }

    focus-ring {
        off
    }

    center-focused-column \"never\"
}

environment {
    DISPLAY \":0\"
    XDG_CURRENT_DESKTOP \"niri\"
    XDG_SESSION_TYPE \"wayland\"
    XDG_SESSION_DESKTOP \"niri\"
}

spawn-at-startup \"xwayland-satellite\"
spawn-at-startup \"swaybg\" \"-i\" \""
   %gruvbox-wallpaper
   "\" \"-m\" \"fill\"
spawn-at-startup \"noctalia-shell\"
spawn-at-startup \""
   (file-append mako "/bin/mako")
   "\"
spawn-at-startup \""
   (file-append hyprpolkitagent "/bin/hyprpolkitagent")
   "\"

prefer-no-csd
screenshot-path \"~/Pictures/Screenshots/%Y-%m-%d %H-%M-%S.png\"

hotkey-overlay {
    skip-at-startup true
}

binds {
    Mod+Return { spawn \"ghostty\"; }
    Mod+Space { spawn \"sh\" \"-c\" \"noctalia-shell ipc call launcher toggle\"; }
    Mod+Escape { spawn \"sh\" \"-c\" \"noctalia-shell ipc call sessionMenu toggle\"; }

    Mod+Shift+B { spawn \"librewolf\"; }
    Mod+Shift+F { spawn \"nautilus\" \"--new-window\"; }
    Mod+Shift+E { spawn \"sh\" \"-c\" \"emacs\"; }
    Mod+Shift+Slash { spawn \"bitwarden\"; }

    Mod+W { close-window; }
    Mod+Ctrl+Alt+Shift+E { quit; }
    Mod+Slash { show-hotkey-overlay; }
    Mod+O { toggle-overview; }

    Mod+H { focus-column-left; }
    Mod+L { focus-column-right; }
    Mod+J { focus-window-down; }
    Mod+K { focus-window-up; }

    Mod+Shift+H { move-column-left; }
    Mod+Shift+L { move-column-right; }
    Mod+Shift+J { move-window-down; }
    Mod+Shift+K { move-window-up; }

    Mod+Alt+H { focus-column-first; }
    Mod+Alt+L { focus-column-last; }
    Mod+Alt+Shift+H { move-column-to-first; }
    Mod+Alt+Shift+L { move-column-to-last; }

    Mod+Ctrl+H { focus-monitor-left; }
    Mod+Ctrl+L { focus-monitor-right; }

    Mod+Ctrl+Shift+H { move-column-to-monitor-left; }
    Mod+Ctrl+Shift+L { move-column-to-monitor-right; }

    Mod+Alt+J { focus-workspace-down; }
    Mod+Alt+K { focus-workspace-up; }

    Mod+Alt+Shift+J { move-column-to-workspace-down; }
    Mod+Alt+Shift+K { move-column-to-workspace-up; }

    Mod+Alt+Ctrl+J { move-workspace-down; }
    Mod+Alt+Ctrl+K { move-workspace-up; }

    Mod+1 { focus-workspace 1; }
    Mod+2 { focus-workspace 2; }
    Mod+3 { focus-workspace 3; }
    Mod+4 { focus-workspace 4; }
    Mod+5 { focus-workspace 5; }
    Mod+6 { focus-workspace 6; }
    Mod+7 { focus-workspace 7; }
    Mod+8 { focus-workspace 8; }
    Mod+9 { focus-workspace 9; }

    Mod+Shift+1 { move-column-to-workspace 1; }
    Mod+Shift+2 { move-column-to-workspace 2; }
    Mod+Shift+3 { move-column-to-workspace 3; }
    Mod+Shift+4 { move-column-to-workspace 4; }
    Mod+Shift+5 { move-column-to-workspace 5; }
    Mod+Shift+6 { move-column-to-workspace 6; }
    Mod+Shift+7 { move-column-to-workspace 7; }
    Mod+Shift+8 { move-column-to-workspace 8; }
    Mod+Shift+9 { move-column-to-workspace 9; }

    Mod+R { switch-preset-column-width; }
    Mod+Alt+R { switch-preset-window-height; }
    Mod+F { maximize-column; }
    Mod+Alt+F { fullscreen-window; }

    Mod+Minus { set-column-width \"-10%\"; }
    Mod+Equal { set-column-width \"+10%\"; }
    Mod+Shift+Minus { set-window-height \"-10%\"; }
    Mod+Shift+Equal { set-window-height \"+10%\"; }

    Mod+Comma { consume-window-into-column; }
    Mod+Period { expel-window-from-column; }

    Mod+V { toggle-window-floating; }
    Mod+Shift+V { switch-focus-between-floating-and-tiling; }

    Print { screenshot; }
    Ctrl+Print { screenshot-screen; }
    Alt+Print { screenshot-window; }

    XF86AudioRaiseVolume allow-when-locked=true { spawn \"noctalia-shell\" \"ipc\" \"call\" \"volume\" \"increase\"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn \"noctalia-shell\" \"ipc\" \"call\" \"volume\" \"decrease\"; }
    XF86AudioMute allow-when-locked=true { spawn \"noctalia-shell\" \"ipc\" \"call\" \"volume\" \"muteOutput\"; }
    XF86MonBrightnessUp allow-when-locked=true { spawn \"noctalia-shell\" \"ipc\" \"call\" \"brightness\" \"increase\"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn \"noctalia-shell\" \"ipc\" \"call\" \"brightness\" \"decrease\"; }
}

window-rule {
    geometry-corner-radius 4
    clip-to-geometry true
}

window-rule {
    match app-id=\"^1[Pp]assword$\"
    block-out-from \"screencast\"
}

window-rule {
    match is-window-cast-target=true
    focus-ring {
        on
        active-color \"#fb4934\"
        inactive-color \"#fb493480\"
    }
    border {
        active-color \"#fb4934\"
        inactive-color \"#fb493480\"
    }
}

window-rule {
    match app-id=\"^steam$\" title=\"^notificationtoasts_[0-9]+_desktop$\"
    default-floating-position x=10 y=10 relative-to=\"bottom-right\"
    open-focused false
}

window-rule {
    match app-id=\"^1[Pp]assword$\"
    match app-id=\"^org\\.gnome\\.Calculator$\"
    match app-id=\"^org\\.gnome\\.Nautilus$\" title=\"^Properties$\"
    match app-id=\"^file-roller$\"
    match app-id=\"^org\\.gnome\\.FileRoller$\"
    match app-id=\"^pavucontrol$\"
    match app-id=\"^nm-connection-editor$\"
    match app-id=\"^blueman-manager$\"
    open-floating true
}

window-rule {
    match app-id=\"^steam$\"
    match app-id=\"^Steam$\"
    exclude title=\"^Steam$\"
    open-floating true
}

window-rule {
    match title=\"^Open File$\"
    match title=\"^Save As$\"
    match title=\"^Save File$\"
    match title=\"^Open Folder$\"
    match title=\"^Select Folder$\"
    match title=\"^Choose Files$\"
    match title=\"^File Upload$\"
    open-floating true
}

window-rule {
    match title=\"^Picture-in-Picture$\"
    match title=\"Picture in picture\"
    open-floating true
    open-focused false
}

window-rule {
    match app-id=\"^ghostty$\"
    match app-id=\"^Alacritty$\"
    match app-id=\"^kitty$\"
    match app-id=\"^foot$\"
    default-column-width { proportion 0.5; }
}

window-rule {
    match app-id=\"^zen.*$\"
    open-maximized true
    open-on-output \"eDP-2\"
    opacity 0.99
}

layer-rule {
    match namespace=\"^notifications$\"
    block-out-from \"screencast\"
}
"))

(define %mako-config-file
  (plain-file
   "mako-config"
   "font=JetBrains Mono 10
background-color=#282828ee
text-color=#ebdbb2ff
border-color=#d79921ff
border-size=2
border-radius=6
default-timeout=5000
padding=8
margin=10
anchor=top-right
max-visible=6
icons=1
"))

(define %gtk-settings-file
  (plain-file
   "gtk-settings.ini"
   "[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Yaru-prussiangreen
gtk-font-name=Roboto 10
gtk-cursor-theme-name=Bibata-Modern-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
"))

(define %gtk-css-file
  (plain-file
   "gtk-gruvbox.css"
   "@define-color gruv-bg #282828;
@define-color gruv-bg-soft #3c3836;
@define-color gruv-fg #ebdbb2;
@define-color gruv-fg-soft #d5c4a1;
@define-color gruv-accent #d79921;
@define-color gruv-accent-soft #fabd2f;

* {
  color: @gruv-fg;
}

window, dialog, popover, headerbar, stack, viewport, scrolledwindow {
  background-color: @gruv-bg;
  color: @gruv-fg;
}

entry, textview, spinbutton, combobox, button, modelbutton {
  background-color: @gruv-bg-soft;
  color: @gruv-fg;
  border-color: @gruv-accent;
}

selection {
  background-color: @gruv-accent;
  color: @gruv-bg;
}

button:hover, modelbutton:hover {
  background-color: @gruv-accent-soft;
  color: @gruv-bg;
}

treeview, list, row {
  background-color: @gruv-bg;
  color: @gruv-fg-soft;
}
"))

(define %xresources-file
  (plain-file
   "Xresources"
   "Xcursor.theme: Bibata-Modern-Classic
Xcursor.size: 24
"))

(define-public %niri-home-packages
  (list
   bibata-cursor-theme
   gnome-keyring
   hyprpolkitagent
   mako
   nautilus
   niri
   swaybg
   xdg-desktop-portal
   xdg-desktop-portal-gnome
   xdg-desktop-portal-gtk
   xwayland-satellite
   wl-clipboard
   yaru-theme))

(define-public (niri-home-services)
  (list
   (simple-service
    'niri-config-files
    home-files-service-type
    (list
     `(".config/niri/config.kdl" ,%niri-config-file)
     `(".config/mako/config" ,%mako-config-file)
     `(".config/gtk-3.0/settings.ini" ,%gtk-settings-file)
     `(".config/gtk-3.0/gtk.css" ,%gtk-css-file)
     `(".config/gtk-4.0/settings.ini" ,%gtk-settings-file)
     `(".config/gtk-4.0/gtk.css" ,%gtk-css-file)
     `(".Xresources" ,%xresources-file)))
   (simple-service
    'gruvbox-desktop-env-vars
    home-environment-variables-service-type
    '(("XDG_CURRENT_DESKTOP" . "niri")
      ("XDG_SESSION_DESKTOP" . "niri")
      ("XDG_SESSION_TYPE" . "wayland")
      ("XCURSOR_THEME" . "Bibata-Modern-Classic")
      ("XCURSOR_SIZE" . "24")
      ("GTK_THEME" . "Adwaita:dark")
      ("QT_QPA_PLATFORM" . "wayland")))))
