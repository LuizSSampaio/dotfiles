(define-module (systems legion)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (gnu system file-systems)
  #:use-module (gnu system mapped-devices)
  #:use-module (gnu system shadow)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services dbus)
  #:use-module (gnu services desktop)
  #:use-module (gnu services networking)
  #:use-module (gnu system privilege)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages firmware)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nushell)
  #:use-module (gnu packages version-control)
  #:use-module (btv tailscale)
  #:use-module (systems)
  #:use-module (modules nvidia)
  #:use-module (modules steam)
  #:export (%legion-operating-system))

;; ---------------------------------------------------------------------------
;; LUKS mapped devices
;; ---------------------------------------------------------------------------
(define %mapped-devices
  (list
   (mapped-device
    (source (uuid "82c28330-9254-4b1c-908a-4ddf127a53d0"))
    (target "cryptroot")
    (type luks-device-mapping))

   (mapped-device
    (source (uuid "b6abffa9-06b2-47e4-8a01-2b73dca6da81"))
    (target "cryptstorage")
    (type luks-device-mapping))))

;; ---------------------------------------------------------------------------
;; File systems
;; ---------------------------------------------------------------------------
(define %file-systems
  (cons*
   (file-system
    (mount-point "/boot/efi")
    (device (uuid "8515-3EC5" 'fat32))
    (type "vfat")
    (flags '(no-atime)))

   (file-system
    (mount-point "/")
    (device "/dev/mapper/cryptroot")
    (type "ext4")
    (dependencies %mapped-devices))

   (file-system
    (mount-point "/mnt/storage")
    (device "/dev/mapper/vg--storage-storage")
    (type "ext4")
    (needed-for-boot? #f)
    (options "nofail")
    (dependencies %mapped-devices))

   %base-file-systems))

;; ---------------------------------------------------------------------------
;; Swap
;; ---------------------------------------------------------------------------
(define %swap-devices
  (list (swap-space (target "/swapfile"))))

;; ---------------------------------------------------------------------------
;; Users
;; ---------------------------------------------------------------------------
(define %users
  (cons*
   (user-account
    (name "luiz")
    (group "users")
    (supplementary-groups '("wheel" "netdev" "audio" "video" "input" "i2c"))
    (shell (file-append nushell "/bin/nu")))
   %base-user-accounts))

(define %groups
  (cons* (user-group (name "i2c") (system? #t))
         %base-groups))

;; ---------------------------------------------------------------------------
;; System packages
;; ---------------------------------------------------------------------------
(define %system-packages
  (cons*
   git
   nushell
   opendoas
   %nvidia-offload-script
   %base-packages))

;; ---------------------------------------------------------------------------
;; doas
;; ---------------------------------------------------------------------------
(define %doas-conf
  (plain-file
   "doas.conf"
   "permit persist keepenv :wheel
"))

(define %privileged-programs
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

;; ---------------------------------------------------------------------------
;; nftables firewall rules
;; ---------------------------------------------------------------------------
(define %nftables-ruleset
  "#!/usr/sbin/nft -f

# Flush all existing rules
flush ruleset

table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;

    # Allow established and related connections
    ct state { established, related } accept

    # Allow loopback
    iif lo accept

    # Allow ICMP / ICMPv6
    ip  protocol icmp   accept
    ip6 nexthdr  icmpv6 accept

    # Trust Tailscale interface fully
    iifname \"tailscale0\" accept

    # LocalSend (TCP + UDP 53317)
    tcp dport 53317 accept
    udp dport 53317 accept

    # Tailscale WireGuard port (default 41641; overridden at runtime)
    udp dport 41641 accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
  }

  chain output {
    type filter hook output priority 0; policy accept;
  }
}
")

;; ---------------------------------------------------------------------------
;; Services
;; ---------------------------------------------------------------------------
(define %system-services
  (append
   (list
    (service network-manager-service-type)
    (service wpa-supplicant-service-type)
    (service dbus-root-service-type)
    (service seatd-service-type)
    (service polkit-service-type)
    (service udisks-service-type)
    (service upower-service-type)

    (simple-service 'doas-config
                    etc-service-type
                    `(("doas.conf" ,%doas-conf)))

    (service nftables-service-type
             (nftables-configuration
              (ruleset (plain-file "nftables.conf" %nftables-ruleset))))

    (service bluetooth-service-type
             (bluetooth-configuration (auto-enable? #f)))

    (service tailscale-service-type))

   (list
    (udev-rules-service 'qmk qmk-udev-rules))

   (steam-system-services)

   (modify-nonguix-substitutes %base-services)))

;; ---------------------------------------------------------------------------
;; Operating system declaration
;; ---------------------------------------------------------------------------
(define-public %legion-operating-system
  (nvidia-prime-operating-system
   (operating-system
     (inherit %conf-initial-os)
     (host-name "legion")

     (mapped-devices  %mapped-devices)
     (file-systems    %file-systems)
     (swap-devices    %swap-devices)
     (users           %users)
     (groups          %groups)
     (privileged-programs %privileged-programs)
     (packages        %system-packages)
     (services        %system-services))))

;; Allow this file to be passed directly to `guix system reconfigure`.
%legion-operating-system
