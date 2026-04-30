(define-module (systems legion-vm)
  #:use-module (gnu)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu system)
  #:use-module (gnu system file-systems)
  #:use-module (gnu system image)
  #:use-module (systems legion)
  #:export (%legion-vm-operating-system))

;; VM image variant for QEMU.  The physical Legion host uses LUKS, swap, and
;; EFI mount points that do not exist inside a generated qcow2 image.
(define-public %legion-vm-operating-system
  (operating-system
    (inherit %legion-operating-system)
    (host-name "legion-vm")

    (bootloader
     (bootloader-configuration
      (bootloader grub-bootloader)
      (targets '("/dev/vda"))
      (terminal-outputs '(console))))

    (mapped-devices '())
    (swap-devices '())
    (file-systems
     (cons (file-system
             (mount-point "/")
             (device (file-system-label root-label))
             (type "ext4"))
           %base-file-systems))))

%legion-vm-operating-system
