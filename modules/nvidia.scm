;; NVIDIA PRIME offload module for GNU Guix.
;; Configures the proprietary NVIDIA driver in PRIME offload mode alongside
;; the integrated AMD GPU, mirroring the NixOS nvidia.nix module.

(define-module (modules nvidia)
  #:use-module (gnu)
  #:use-module (gnu services)
  #:use-module (nongnu services nvidia)
  #:export (nvidia-prime-services
            %nvidia-offload-script))

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
;;; nvidia-prime-services
;;;
;;; Returns a list of services to splice into the operating-system services
;;; list.  Call (append (nvidia-prime-services) %desktop-services) or similar.
;;; ---------------------------------------------------------------------------
(define-public (nvidia-prime-services)
  (list
   ;; Load the proprietary NVIDIA kernel module and user-space components.
   ;; nonguix provides nvidia-service-type which handles module loading,
   ;; /dev node creation, and the OpenGL/Vulkan ICD configuration.
   (service nvidia-service-type)))
