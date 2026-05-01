(define-module (homes luiz)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services sound)
  #:use-module (gnu packages nushell)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages file)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages terminals)
  #:use-module (guix gexp)
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
(define %home-packages
  (append
   (list
    ;; Shell
    nushell
    direnv

    ;; CLI utilities
    curl
    wget
    file
    unzip
    zip

    ;; Gaming
    %steam-package

    ;; Browser
    %librewolf-package)
   %niri-home-packages
   %noctalia-home-packages
   %doom-home-packages
   %conf-home-packages))

;; ---------------------------------------------------------------------------
;; Home services
;; ---------------------------------------------------------------------------
(define %nushell-config-file
  (plain-file
   "config.nu"
   "$env.config = ($env.config? | default {})
$env.config = ($env.config | upsert hooks.env_change.PWD [
  {|before, after|
    direnv export json | from json | default {} | load-env
  }
])
"))

(define %home-services
  (append
   (list
    (simple-service
     'nushell-config-files
     home-files-service-type
     (list
      `(".config/nushell/config.nu" ,%nushell-config-file)))

    ;; Persist common environment variables across all sessions.
    (service home-environment-variables-service-type
             '(;; Default editor for command-line tools.
               ("EDITOR"  . "emacs")
               ("VISUAL"  . "emacs")
               ;; Colored output for common tools.
               ("CLICOLOR" . "1")))

    (service home-dbus-service-type)
    (service home-pipewire-service-type))
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
