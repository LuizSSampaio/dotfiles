;; Doom Emacs bootstrap module for GNU Guix Home.
;; Installs the core editor/tooling packages and keeps Doom synchronized on
;; each home activation.

(define-module (modules emacs)
  #:use-module (gnu home services)
  #:use-module (gnu packages)
  #:use-module (guix gexp)
  #:use-module (guix modules)
  #:export (%doom-home-packages
            doom-home-services))

(define %doom-emacs-repository
  "https://github.com/doomemacs/doomemacs")

(define-public %doom-home-packages
  (map specification->package
       '("emacs" "git" "ripgrep" "fd")))

(define %doom-private-config-files
  (map (lambda (file)
         `(,(string-append ".config/doom/" file)
           ,(local-file
             (canonicalize-path
              (search-path %load-path
                           (string-append "modules/emacs/doom.d/" file))))))
       '("config.el" "init.el" "packages.el")))

(define (doom-activation-gexp)
  (with-imported-modules (source-module-closure '((guix build utils)))
    #~(begin
        (use-modules (guix build utils))

        (define home (getenv "HOME"))
        (define xdg-config-home
          (or (getenv "XDG_CONFIG_HOME")
              (string-append home "/.config")))
        (define doom-dir (string-append xdg-config-home "/emacs"))
        (define doom-bin (string-append doom-dir "/bin/doom"))
        (define doom-private-dir
          (or (getenv "DOOMDIR")
              (string-append xdg-config-home "/doom")))

        ;; Keep activation non-interactive.
        (setenv "YES" "1")
        (setenv "DOOMDIR" doom-private-dir)

        (if (file-exists? doom-bin)
            (begin
              (format #t "Synchronizing Doom Emacs (~a)~%" doom-private-dir)
              (invoke doom-bin "sync"))
            (begin
              (mkdir-p xdg-config-home)
              (when (and (file-exists? doom-dir)
                         (not (file-exists? (string-append doom-dir "/.git"))))
                (error "Doom directory exists but is not a git checkout"
                       doom-dir))
              (unless (file-exists? doom-dir)
                (format #t "Cloning Doom Emacs into ~a~%" doom-dir)
                (invoke "git" "clone" "--depth" "1"
                        #$%doom-emacs-repository doom-dir))
              (format #t "Installing Doom Emacs (~a)~%" doom-private-dir)
              (invoke doom-bin "install"))))))

(define-public (doom-home-services)
  (list
   (simple-service 'doom-emacs-config-files
                   home-files-service-type
                   %doom-private-config-files)
   (simple-service 'doom-emacs-activation
                   home-activation-service-type
                   (doom-activation-gexp))))
