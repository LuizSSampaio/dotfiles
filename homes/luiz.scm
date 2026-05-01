(define-module (homes luiz)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services sound)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages bittorrent)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages file)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages firmware)
  #:use-module (gnu packages kde-graphics)
  #:use-module (gnu packages kde-multimedia)
  #:use-module (gnu packages mpi)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages telephony)
  #:use-module (gnu packages video)
  #:use-module (guix gexp)
  #:use-module (guix modules)
  #:use-module (nongnu packages password-utils)
  #:use-module (homes)
  #:use-module (modules emacs)
  #:use-module (modules librewolf)
  #:use-module (modules niri)
  #:use-module (modules noctalia)
  #:use-module (modules steam)
  #:export (%luiz-home-environment))

;; ---------------------------------------------------------------------------
;; Home packages
;; ---------------------------------------------------------------------------
(define %flatpak-applications
  '("org.prismlauncher.PrismLauncher"
    "in.cinny.Cinny"
    "org.localsend.localsend_app"))

(define %home-packages
  (append
   (list
    ;; Shell/project environment for Emacs and Eshell.
    direnv

    ;; CLI utilities
    bat
    curl
    eza
    wget
    file
    fastfetch
    unzip
    zip
    7zip
    bzip2
    unrar-free
    xz
    zstd
    zoxide

    ;; Gaming
    %steam-package
    flatpak

    ;; Chat/voice
    mumble

    ;; Media creation/playback
    kdenlive
    krita
    ffmpeg
    mpv
    obs

    ;; Network/file sharing
    qbittorrent

    ;; Keyboard firmware tooling
    qmk

    ;; MPI runtime/development tools
    openmpi

    ;; Browser
    %librewolf-package

    ;; Password manager
    bitwarden-desktop)
   %niri-home-packages
   %noctalia-home-packages
   %doom-home-packages
   %conf-home-packages))

;; ---------------------------------------------------------------------------
;; Home services
;; ---------------------------------------------------------------------------
(define (flatpak-apps-activation-gexp)
  (with-imported-modules (source-module-closure '((guix build utils)))
    #~(begin
        (use-modules (guix build utils))

        (define flatpak-bin #$(file-append flatpak "/bin/flatpak"))
        (define flathub-url
          "https://dl.flathub.org/repo/flathub.flatpakrepo")

        (define (run/warn . args)
          (unless (zero? (apply system* args))
            (format (current-error-port)
                    "warning: flatpak command failed: ~s~%" args)))

        (run/warn flatpak-bin "remote-add" "--user" "--if-not-exists"
                  "flathub" flathub-url)
        (for-each
         (lambda (app-id)
           (run/warn flatpak-bin "install" "--user" "--noninteractive"
                     "--or-update" "flathub" app-id))
         '#$%flatpak-applications))))

(define %home-services
  (append
   (list
    ;; Persist common environment variables across all sessions.
    (service home-environment-variables-service-type
             '(;; Default editor for command-line tools.
               ("EDITOR"  . "emacs")
               ("VISUAL"  . "emacs")
               ;; Colored output for common tools.
               ("CLICOLOR" . "1")))

    (service home-dbus-service-type)
    (service home-pipewire-service-type)

    (simple-service 'flatpak-apps-activation
                    home-activation-service-type
                    (flatpak-apps-activation-gexp)))
   (niri-home-services)
   (noctalia-home-services)
   (doom-home-services)))

;; ---------------------------------------------------------------------------
;; Home environment declaration
;; ---------------------------------------------------------------------------
(define-public %luiz-home-environment
  (home-environment
   (inherit %conf-initial-home)
   (packages %home-packages)
   (services
    (append
     %home-services
     ;; Keep the XDG base-directory service declared in the base skeleton.
     (home-environment-services %conf-initial-home)))))

;; Allow this file to be passed directly to `guix home reconfigure`.
%luiz-home-environment
