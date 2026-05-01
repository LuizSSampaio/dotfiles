(define-module (homes luiz)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services desktop)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services sound)
  #:use-module (gnu packages nushell)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages shellutils)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages wget)
  #:use-module (gnu packages file)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages terminals)
  #:use-module (nongnu packages password-utils)
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
    bat
    curl
    eza
    wget
    file
    unzip
    zip
    zoxide

    ;; Gaming
    %steam-package

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
(define %nushell-config-file
  (plain-file
   "config.nu"
"$env.config = (
  $env.config?
  | default {}
  | upsert history { default {} }
  | upsert history.max_size 1000
  | upsert completions { default {} }
  | upsert completions.external { default {} }
  | upsert completions.external.enable true
  | upsert highlight_resolved_externals true
  | upsert hooks { default {} }
  | upsert hooks.env_change { default {} }
  | upsert hooks.env_change.PWD { default [] }
)

$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append {
  __direnv_hook: true,
  code: {|before, after|
    let direnv_export = (direnv export json)
    if not ($direnv_export | is-empty) {
      $direnv_export | from json | default {} | load-env
    }
  }
})

source ~/.config/nushell/zoxide.nu

alias c = clear
alias mkdir = ^mkdir -vp
alias rm = ^rm -rifv
alias mv = ^mv -iv
alias cp = ^cp -riv
alias cat = ^bat --paging=never --style=plain
alias cd = z
alias ls = ^eza -lh --group-directories-first --icons=auto
alias lsa = ls -a
alias lt = ^eza --tree --level=2 --long --icons --git
alias lta = lt -a
alias n = ^emacs -nw
"))

(define %zoxide-nushell-file
  (plain-file
   "zoxide.nu"
   "# Code generated from `zoxide init nushell`.

export-env {
  $env.config = (
    $env.config?
    | default {}
    | upsert hooks { default {} }
    | upsert hooks.env_change { default {} }
    | upsert hooks.env_change.PWD { default [] }
  )
  let __zoxide_hooked = (
    $env.config.hooks.env_change.PWD | any { try { get __zoxide_hook } catch { false } }
  )
  if not $__zoxide_hooked {
    $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append {
      __zoxide_hook: true,
      code: {|_, dir| ^zoxide add -- $dir}
    })
  }
}

def --env --wrapped __zoxide_z [...rest: string] {
  let path = match $rest {
    [] => {'~'},
    [ '-' ] => {'-'},
    [ $arg ] if ($arg | path expand | path type) == 'dir' => {$arg}
    _ => {
      ^zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c \"\\n\"
    }
  }
  cd $path
}

def --env --wrapped __zoxide_zi [...rest:string] {
  cd $'(^zoxide query --interactive -- ...$rest | str trim -r -c \"\\n\")'
}

alias z = __zoxide_z
alias zi = __zoxide_zi
"))

(define %home-services
  (append
   (list
    (simple-service
     'nushell-config-files
     home-files-service-type
     (list
      `(".config/nushell/config.nu" ,%nushell-config-file)
      `(".config/nushell/zoxide.nu" ,%zoxide-nushell-file)))

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
