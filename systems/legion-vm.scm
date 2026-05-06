(define-module (systems legion-vm)
  #:use-module (gnu)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages nushell)
  #:use-module (gnu packages version-control)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services dbus)
  #:use-module (gnu services desktop)
  #:use-module (gnu services networking)
  #:use-module (gnu system)
  #:use-module (gnu system file-systems)
  #:use-module (gnu system image)
  #:use-module (gnu system keyboard)
  #:use-module (gnu system locale)
  #:use-module (gnu system privilege)
  #:use-module (gnu system shadow)
  #:export (%legion-vm-operating-system))

(define %vm-timezone "America/Sao_Paulo")
(define %vm-locale "en_US.UTF-8")

(define %vm-keyboard-layout
  (keyboard-layout "us" "intl"))

(define %vm-initrd-modules
  %base-initrd-modules)

(define %vm-users
  (cons*
   (user-account
    (name "luiz")
    (group "users")
    (supplementary-groups '("wheel" "netdev" "audio" "video" "input" "i2c"))
    (shell (file-append nushell "/bin/nu")))
   %base-user-accounts))

(define %vm-groups
  (cons* (user-group (name "i2c") (system? #t))
         %base-groups))

(define %vm-system-packages
  (cons*
   git
   nushell
   opendoas
   %base-packages))

(define %vm-doas-conf
  (plain-file
   "doas.conf"
   "permit persist keepenv :wheel
"))

(define %vm-privileged-programs
  (cons*
   (privileged-program
    (program (file-append opendoas "/bin/doas"))
    (setuid? #t))
   (privileged-program
    (program (file-append inetutils "/bin/ping"))
    (capabilities "cap_net_raw=ep"))
   (privileged-program
    (program (file-append inetutils "/bin/ping6"))
    (capabilities "cap_net_raw=ep"))
   (map file-like->setuid-program
        (list (file-append shadow "/bin/passwd")
              (file-append shadow "/bin/chfn")
              (file-append shadow "/bin/sg")
              (file-append shadow "/bin/su")
              (file-append shadow "/bin/newgrp")
              (file-append shadow "/bin/newuidmap")
              (file-append shadow "/bin/newgidmap")
              (file-append fuse-2 "/bin/fusermount")
              (file-append fuse "/bin/fusermount3")
              (file-append util-linux "/bin/mount")
              (file-append util-linux "/bin/umount")))))

(define %vm-system-services
  (cons*
   (service network-manager-service-type)
   (service wpa-supplicant-service-type)
   (service dbus-root-service-type)
   (service seatd-service-type)
   (service polkit-service-type)
   (service udisks-service-type)
   (service upower-service-type)
   (simple-service 'doas-config
                   etc-service-type
                   `(("doas.conf" ,%vm-doas-conf)))
   %base-services))

;; VM image variant for QEMU.  Keep this separate from the physical Legion host:
;; the host config uses real disks, LUKS mappings, Nonguix firmware, NVIDIA, and
;; machine services that do not belong in a generic qcow2 VM.
(define-public %legion-vm-operating-system
  (operating-system
    (host-name "legion-vm")
    (locale %vm-locale)
    (timezone %vm-timezone)

    (locale-definitions
     (list
      (locale-definition (name "en_US.UTF-8") (source "en_US"))
      (locale-definition (name "pt_BR.UTF-8") (source "pt_BR"))))

    (keyboard-layout %vm-keyboard-layout)
    (kernel linux-libre)
    (initrd-modules %vm-initrd-modules)

    (bootloader
     (bootloader-configuration
      (bootloader grub-bootloader)
      (targets '("/dev/vda"))
      (keyboard-layout %vm-keyboard-layout)
      (terminal-outputs '(console))
      (timeout 3)))

    (mapped-devices '())
    (swap-devices '())
    (users %vm-users)
    (groups %vm-groups)
    (privileged-programs %vm-privileged-programs)
    (packages %vm-system-packages)
    (services %vm-system-services)
    (file-systems
     (cons (file-system
             (mount-point "/")
             (device (file-system-label root-label))
             (type "ext4"))
           %base-file-systems))
    (sudoers-file #f)))

%legion-vm-operating-system
