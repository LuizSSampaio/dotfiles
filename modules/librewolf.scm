;; LibreWolf package with local browser policies.

(define-module (modules librewolf)
  #:use-module (srfi srfi-13)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages librewolf)
  #:export (%librewolf-package))

(define %librewolf-extension-urls
  '("https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/popupoff/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/youtube-recommended-videos/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/youtube-anti-translate/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/istilldontcareaboutcookies/latest.xpi"
    "https://addons.mozilla.org/firefox/downloads/latest/languagetool/latest.xpi"))

(define %librewolf-policies
  (plain-file
   "policies.json"
   (format #f "\
{
  \"policies\": {
    \"Extensions\": {
      \"Install\": [
        \"~a\"
      ]
    },
    \"SearchEngines\": {
      \"Add\": [
        {
          \"Name\": \"LSAMP SearXNG\",
          \"URLTemplate\": \"https://search.lsamp.dev/search?q={searchTerms}\",
          \"Method\": \"GET\",
          \"IconURL\": \"https://search.lsamp.dev/favicon.ico\",
          \"Alias\": \"sx\",
          \"Description\": \"Self-hosted SearXNG\"
        }
      ],
      \"Default\": \"LSAMP SearXNG\"
    }
  }
}~%"
           (string-join %librewolf-extension-urls
                        "\",\n        \""))))

(define-public %librewolf-package
  (package
    (inherit librewolf)
    (name "librewolf-configured")
    (source #f)
    (build-system trivial-build-system)
    (native-inputs '())
    (inputs (list librewolf))
    (propagated-inputs '())
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils)
                       (ice-9 ftw)
                       (ice-9 regex)
                       (srfi srfi-13))

          (let* ((out #$output)
                 (upstream #$librewolf)
                 (distribution
                  (string-append out "/lib/librewolf/distribution"))
                 (policies.json
                  (string-append distribution "/policies.json")))
            (define (metadata-file? file)
              (or (string-prefix? (string-append out "/bin/") file)
                  (string-prefix? (string-append out "/share/applications/") file)
                  (string-prefix? (string-append out "/share/metainfo/") file)
                  (string-suffix? ".desktop" file)
                  (string-suffix? ".service" file)))

            (define (rewrite-output-references directory)
              (define (rewrite-symlink file)
                (let ((target (readlink file)))
                  (when (string-prefix? upstream target)
                    (delete-file file)
                    (symlink
                     (string-append out
                                    (substring target (string-length upstream)))
                     file))))

              (define (walk directory)
                (make-file-writable directory)
                (for-each
                 (lambda (entry)
                   (let* ((file (string-append directory "/" entry))
                          (stat (lstat file))
                          (type (stat:type stat)))
                     (cond
                      ((eq? type 'directory)
                       (walk file))
                      ((eq? type 'symlink)
                       (rewrite-symlink file))
                      ((and (eq? type 'regular) (metadata-file? file))
                       (make-file-writable file)
                       (substitute* file
                         (((regexp-quote upstream)) out)))))))
                 (scandir directory
                          (lambda (entry)
                            (not (member entry '("." "..")))))))

              (walk directory))

            ;; Avoid rebuilding LibreWolf from source just to add policies.
            (copy-recursively #$librewolf out)
            (rewrite-output-references out)
            (mkdir-p distribution)
            (chmod distribution #o755)
            (when (file-exists? policies.json)
              (delete-file policies.json))
            (copy-file #$%librewolf-policies policies.json))))))
