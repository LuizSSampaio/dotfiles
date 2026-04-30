(define-module (homes)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (gnu home services shells)
  #:use-module (gnu home services xdg)
  #:export (%conf-home-packages
            %conf-initial-home))

;; Packages installed in every user's home profile.
;; Per-user files should append their own packages on top of this list.
(define-public %conf-home-packages
  '())

;; Skeleton home-environment used as a base for all user configurations.
;; Per-user files should inherit from this value and override individual
;; fields, mirroring the pattern used by %conf-initial-os in systems.scm.
(define-public %conf-initial-home
  (home-environment
    (packages %conf-home-packages)
    (services
     (list
      ;; Activate XDG base-directory support so that tools respect
      ;; $XDG_CONFIG_HOME, $XDG_DATA_HOME, etc.
      (service home-xdg-base-directories-service-type)))))
