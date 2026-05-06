;; NVIDIA PRIME offload module for GNU Guix.
;; Configures the proprietary NVIDIA driver in PRIME offload mode alongside
;; the integrated AMD GPU, mirroring the NixOS nvidia.nix module.

(define-module (modules nvidia)
  #:use-module (gnu)
  #:export (nvidia-prime-operating-system
            %nvidia-offload-script))

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

(define (require-nonguix-binding module-name binding-name)
  (or (module-ref* (resolve-interface* module-name) binding-name)
      (error "Nonguix NVIDIA support is unavailable; update channels with `guix pull -C channels.scm`"
             module-name binding-name)))

;;; ---------------------------------------------------------------------------
;;; nvidia-offload helper script
;;;
;;; Equivalent to the NixOS `nvidia-offload` shell script created inside the
;;; nvidia.nix module.  Drop it into the system profile so the user can run:
;;;   nvidia-offload <command>
;;; ---------------------------------------------------------------------------
(define-public %nvidia-offload-script
  (program-file
   "nvidia-offload"
   #~(begin
       ;; Set the environment variables expected by the NVIDIA PRIME runtime.
       (setenv "__NV_PRIME_RENDER_OFFLOAD"          "1")
       (setenv "__NV_PRIME_RENDER_OFFLOAD_PROVIDER" "NVIDIA-G0")
       (setenv "__GLX_VENDOR_LIBRARY_NAME"          "nvidia")
       (setenv "__VK_LAYER_NV_optimus"              "NVIDIA_only")
       ;; Exec the user-supplied command.
       (let ((args (cdr (command-line))))
         (when (null? args)
           (error "Usage: nvidia-offload <command> [args...]"))
         (apply execlp (car args) args)))))

;;; ---------------------------------------------------------------------------
;;; nvidia-prime-operating-system
;;;
;;; Applies Nonguix's current NVIDIA transformation to the final operating
;;; system, replacing the older direct `nvidia-service-type` wiring.
;;; ---------------------------------------------------------------------------
(define-public (nvidia-prime-operating-system os)
  (let ((nonguix-transformation-nvidia
         (require-nonguix-binding '(nonguix transformations)
                                  'nonguix-transformation-nvidia))
        (nvda
         (require-nonguix-binding '(nongnu packages nvidia) 'nvda)))
    ((nonguix-transformation-nvidia
      #:driver nvda
      #:configure-xorg? #f)
     os)))
