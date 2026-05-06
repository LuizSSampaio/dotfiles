(define-module (homes)
  #:use-module (gnu home)
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
    (packages %conf-home-packages)))
