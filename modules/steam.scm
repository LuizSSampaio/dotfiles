;; Steam support for GNU Guix.
;; Provides the NVIDIA Steam package and the system services needed for
;; controller udev rules and Nonguix substitutes.

(define-module (modules steam)
  #:use-module (gnu)
  #:use-module (gnu packages games)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:export (%steam-package
            %steam-home-packages
            %steam-flatpak-applications
            modify-nonguix-substitutes
            steam-system-services))

(define %nonguix-substitute-url
  "https://substitutes.nonguix.org")

(define %steam-flatpak-application
  "com.valvesoftware.Steam")

(define (resolve-interface* name)
  (catch #t
    (lambda ()
      (resolve-interface name))
    (lambda _
      #f)))

(define (module-ref* module name)
  (and module
       (module-variable module name)
       (module-ref module name)))

(define %game-client-module
  (resolve-interface* '(nongnu packages game-client)))

(define %steam-client-module
  (resolve-interface* '(nongnu packages steam-client)))

(define %nvidia-module
  (resolve-interface* '(nongnu packages nvidia)))

(define (nonguix-steam-package)
  (or
   (let ((steam-for (or (module-ref* %game-client-module 'steam-for)
                        (module-ref* %steam-client-module 'steam-for)))
         (nvda (module-ref* %nvidia-module 'nvda)))
     (and steam-for nvda (steam-for nvda)))
   (module-ref* %game-client-module 'steam-nvidia)
   (module-ref* %steam-client-module 'steam-nvidia)))

;; Steam with NVIDIA userspace libraries for the proprietary driver.
(define-public %steam-package
  (nonguix-steam-package))

(define-public %steam-home-packages
  (if %steam-package
      (list %steam-package)
      '()))

(define-public %steam-flatpak-applications
  (if %steam-package
      '()
      (list %steam-flatpak-application)))

(define (nonguix-guix-configuration config)
  (guix-configuration
   (inherit config)
   (substitute-urls
    (append (list %nonguix-substitute-url)
            %default-substitute-urls))
   (authorized-keys
    (append
     (list (local-file
            (canonicalize-path
             (search-path %load-path "modules/nonguix-signing-key.pub"))))
     %default-authorized-guix-keys))))

(define-public (steam-system-services)
  (list
   (udev-rules-service 'steam-devices steam-devices-udev-rules)))

(define-syntax-rule (modify-nonguix-substitutes config)
  (modify-services config
    (guix-service-type guix-config =>
                       (nonguix-guix-configuration guix-config))))
