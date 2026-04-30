;; LibreWolf package with local browser policies.

(define-module (modules librewolf)
  #:use-module (srfi srfi-13)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
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
    (arguments
     (substitute-keyword-arguments (package-arguments librewolf)
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'install 'install-librewolf-policies
              (lambda _
                (let ((policies.json
                       (string-append #$output
                                      "/lib/librewolf/distribution/policies.json")))
                  (mkdir-p (dirname policies.json))
                  (copy-file #$%librewolf-policies policies.json))))))))))
