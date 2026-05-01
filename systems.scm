(define-module (systems)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (gnu system keyboard)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu system file-systems)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:export (%conf-timezone
            %conf-locale
            %conf-keyboard-layout
            %conf-initrd-modules
            %conf-initial-os))

(define-public %conf-timezone "America/Sao_Paulo")
(define-public %conf-locale "en_US.UTF-8")

(define-public %conf-keyboard-layout
  (keyboard-layout "us" "intl"))

;; initrd kernel modules common to all hosts.
;; Mirrors boot.initrd.availableKernelModules in the NixOS configs.
(define-public %conf-initrd-modules
  (append
   '("nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" "rtsx_pci_sdmmc"
     "dm_mod" "dm_crypt" "aes_x86_64" "sha256_generic")
   %base-initrd-modules))

;; Skeleton operating-system used as a base for all host configurations.
;; Per-host files should override individual fields via inheritance or
;; by composing on top of this value.
(define-public %conf-initial-os
  (operating-system
    (host-name "unknown")
    (locale %conf-locale)
    (timezone %conf-timezone)

    (locale-definitions
     (list
      (locale-definition (name "en_US.UTF-8") (source "en_US"))
      (locale-definition (name "pt_BR.UTF-8") (source "pt_BR"))))

    (keyboard-layout %conf-keyboard-layout)

    ;; Non-free Linux kernel + microcode initrd (from nonguix).
    (kernel linux)
    (firmware (list linux-firmware))
    (initrd microcode-initrd)
    (initrd-modules %conf-initrd-modules)

    (bootloader
     (bootloader-configuration
      (bootloader grub-efi-bootloader)
      (targets '("/boot/efi"))
      (keyboard-layout %conf-keyboard-layout)
      (timeout 3)))

    (services '())
    (file-systems %base-file-systems)
    (sudoers-file #f)))
