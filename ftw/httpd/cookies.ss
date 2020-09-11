;; -*- Gerbil -*-
(export #t)
(import :drewc/ftw/httpd/handler
        :std/srfi/13
        :std/format
        :ftw/timestamp
        :clan/base)

;;;; Handling of cookie headers

;;; Request cookies

(def (http-request-cookies req)
  (let* ((hs (http-request-headers*))
         (cj (assget "Cookie" hs))
         (cookies
          (and cj (map (lambda (c) (match (map string-trim (string-split c #\=))
                                ([a b] [a . b])))
                       (string-split cj #\;)))))

    (or cookies [])))

(def (http-request-cookies* (req #f))
  (http-request-cookies (or req (current-http-request))))


;;; Response cookies
;;; Response Cookie class object
(defstruct cookie
  (name value
   expires max-age domain path
   secure http-only samesite)
  transparent: #t
  constructor: :init!)


;;; Override constructor for cookie to allow setting values and
;;; defaults
(defmethod {:init! cookie}
  (lambda (self
           name
           value
           expires: (expires #f)
           max-age: (max-age #f)
           domain: (domain #f)
           path: (path #f)
           secure: (secure #f)
           http-only: (http-only #f)
           samesite: (samesite #f))
    (struct-instance-init! self
                           name
                           value
                           expires
                           max-age
                           domain
                           path
                           secure
                           http-only
                           samesite)))


;;; Valid values for SameSite cookie flag
(def +samesite-valid-values+
     ["None" "Strict" "Lax"])


;;; Format cookie expires date as a rfc-1123 timestamp, or #f
(def (cookie-expires-date cookie)
     (let (date (cookie-expires cookie))
       (if date
           (rfc-1123-date<-date date)
           #f)))

;;; Validate the SameSite value
(def (cookie-samesite-valid cookie)
     (let* ((ss (cookie-samesite cookie))
            (val (member ss +samesite-valid-values+))
            (val (and val
                      (list? val)
                      (car val))))
       val))



;;; Convert response cookie object to a string suitable for use as a
;;; 'Set-Cookie:' header.
(def (cookie->string cookie)

     (def (format-if-needed reader cookie format-string (true-value #f))
          (let* ((raw-value (reader cookie))
                 (value (or (and raw-value
                                 true-value)
                            raw-value)))
            (if value
                (if format-string
                    (format format-string value)
                    value)
                "")))

     (string-append
      (cookie-name cookie) "=" (cookie-value cookie)
      (format-if-needed cookie-expires-date cookie "; Expires=~A")
      (format-if-needed cookie-max-age cookie "; Max-Age=~A")
      (format-if-needed cookie-domain cookie "; Domain=~A")
      (format-if-needed cookie-path cookie "; Path=~A")
      (format-if-needed cookie-secure cookie #f "; Secure")
      (format-if-needed cookie-http-only cookie #f "; HttpOnly")
      (format-if-needed cookie-samesite-valid cookie "; Same-Site=~A")))
