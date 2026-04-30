;; Noctalia shell module for GNU Guix Home.
;; Provides a reproducible package and Gruvbox-oriented default settings.

(define-module (modules noctalia)
  #:use-module (gnu home services)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages hardware)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages music)
  #:use-module (gnu packages web)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages xdisorg)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (gnu services)
  #:export (%noctalia-home-packages
            %noctalia-shell-package
            noctalia-home-services))

(define %noctalia-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/noctalia-dev/noctalia-shell")
          (commit "9f8dd48c8df5ab1f7f87ddf9842627e1e5682186")))
    (file-name (git-file-name "noctalia-shell" "2026-04-30"))
    (sha256
     (base32 "1br4074j7ygcbzxcf9aqqr0rh7mzkhjaq143ms9jmy2vvhniz9wj"))))

(define-public %noctalia-shell-package
  (package
    (name "noctalia-shell")
    (version "2026-04-30.9f8dd48")
    (source %noctalia-source)
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan
      #~'(("." "share/noctalia-shell"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'install-launcher
            (lambda* (#:key outputs inputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (bin (string-append out "/bin"))
                     (launcher (string-append bin "/noctalia-shell"))
                     (bash (search-input-file inputs "/bin/bash"))
                     (quickshell-bin
                      (search-input-file inputs "/bin/quickshell")))
                (mkdir-p bin)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%" bash)
                    (format port "set -euo pipefail~%")
                    (format port "export QS_CONFIG_PATH=~s~%"
                            (string-append out "/share/noctalia-shell"))
                    (format port "exec ~a \"$@\"~%" quickshell-bin)))
                (chmod launcher #o555)))))))
    (inputs (list bash quickshell))
    (home-page "https://github.com/noctalia-dev/noctalia-shell")
    (synopsis "Wayland desktop shell built on Quickshell")
    (description
     "Noctalia is a Wayland desktop shell built on Quickshell.  This package
ships upstream Noctalia files and a launcher wrapper that sets QS_CONFIG_PATH.")
    (license expat)))

(define %noctalia-settings-file
  (plain-file
   "noctalia-settings.json"
   "{
  \"bar\": {
    \"position\": \"top\",
    \"barType\": \"floating\",
    \"showCapsule\": true,
    \"outerCorners\": false,
    \"widgets\": {
      \"left\": [
        { \"id\": \"Launcher\" },
        { \"id\": \"Clock\", \"formatHorizontal\": \"HH:mm ddd, MMM d\" },
        { \"id\": \"SystemMonitor\" },
        { \"id\": \"MediaMini\" }
      ],
      \"center\": [
        { \"id\": \"Workspace\" }
      ],
      \"right\": [
        { \"id\": \"Tray\" },
        { \"id\": \"NotificationHistory\" },
        { \"id\": \"Brightness\" },
        { \"id\": \"Battery\", \"displayMode\": \"alwaysShow\" },
        { \"id\": \"Volume\", \"displayMode\": \"alwaysShow\" },
        { \"id\": \"Bluetooth\", \"displayMode\": \"alwaysShow\" },
        { \"id\": \"ControlCenter\", \"useDistroLogo\": true }
      ]
    }
  },
  \"general\": {
    \"animationSpeed\": 1,
    \"enableShadows\": true,
    \"lockOnSuspend\": true,
    \"telemetryEnabled\": false
  },
  \"location\": {
    \"monthBeforeDay\": false,
    \"weatherEnabled\": false
  },
  \"dock\": {
    \"enabled\": false
  },
  \"colorSchemes\": {
    \"darkMode\": true,
    \"useWallpaperColors\": false,
    \"predefinedScheme\": \"GruvboxAlt\",
    \"syncGsettings\": true
  }
}
"))

(define %noctalia-colors-file
  (plain-file
   "noctalia-colors.json"
   "{
  \"mPrimary\": \"#ebdbb2\",
  \"mOnPrimary\": \"#282828\",
  \"mSecondary\": \"#8ec07c\",
  \"mOnSecondary\": \"#282828\",
  \"mTertiary\": \"#83a598\",
  \"mOnTertiary\": \"#282828\",
  \"mError\": \"#fb4934\",
  \"mOnError\": \"#282828\",
  \"mSurface\": \"#282828\",
  \"mOnSurface\": \"#fbf1c7\",
  \"mSurfaceVariant\": \"#3c3836\",
  \"mOnSurfaceVariant\": \"#ebdbb2\",
  \"mOutline\": \"#57514e\",
  \"mShadow\": \"#282828\",
  \"mHover\": \"#83a598\",
  \"mOnHover\": \"#282828\",
  \"terminal\": {
    \"foreground\": \"#ebdbb2\",
    \"background\": \"#282828\",
    \"selectionFg\": \"#ebdbb2\",
    \"selectionBg\": \"#665c54\",
    \"cursorText\": \"#282828\",
    \"cursor\": \"#ebdbb2\",
    \"normal\": {
      \"black\": \"#282828\",
      \"red\": \"#cc241d\",
      \"green\": \"#98971a\",
      \"yellow\": \"#d79921\",
      \"blue\": \"#458588\",
      \"magenta\": \"#b16286\",
      \"cyan\": \"#689d6a\",
      \"white\": \"#a89984\"
    },
    \"bright\": {
      \"black\": \"#928374\",
      \"red\": \"#fb4934\",
      \"green\": \"#b8bb26\",
      \"yellow\": \"#fabd2f\",
      \"blue\": \"#83a598\",
      \"magenta\": \"#d3869b\",
      \"cyan\": \"#8ec07c\",
      \"white\": \"#ebdbb2\"
    }
  }
}
"))

(define-public %noctalia-home-packages
  (list
   %noctalia-shell-package
   brightnessctl
   cliphist
   ddcutil
   imagemagick
   jq
   playerctl
   wget
   wl-clipboard
   wlr-randr
   wlsunset))

(define-public (noctalia-home-services)
  (list
   (simple-service
    'noctalia-config-files
    home-files-service-type
    (list
     `(".config/noctalia/settings.json" ,%noctalia-settings-file)
     `(".config/noctalia/colors.json" ,%noctalia-colors-file)))))
