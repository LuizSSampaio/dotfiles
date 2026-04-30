;; Steam support for GNU Guix.
;; Provides the NVIDIA Steam package and the system services needed for
;; controller udev rules and Nonguix substitutes.

(define-module (modules steam)
  #:use-module (gnu)
  #:use-module (gnu packages games)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (nongnu packages game-client)
  #:use-module (nongnu packages nvidia)
  #:export (%steam-package
            modify-nonguix-substitutes
            steam-system-services))

(define %nonguix-substitute-url
  "https://substitutes.nonguix.org")

;; Steam with NVIDIA userspace libraries for the proprietary driver.
(define-public %steam-package
  (steam-for nvda))

(define (nonguix-guix-configuration config)
  (guix-configuration
   (inherit config)
   (substitute-urls
    (append (list %nonguix-substitute-url)
            %default-substitute-urls))
   (authorized-keys
    (append
     (list (local-file
            (search-path %load-path "modules/nonguix-signing-key.pub")))
     %default-authorized-guix-keys))))

(define-public (steam-system-services)
  (list
   (udev-rules-service 'steam-devices steam-devices-udev-rules)))

(define-syntax-rule (modify-nonguix-substitutes config)
  (guix-service-type config =>
                     (nonguix-guix-configuration config)))
