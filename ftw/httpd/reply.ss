;;; -*- Gerbil -*-
(export #t)
(import :ftw/http-status-code
        :std/generic
        :std/net/httpd
        :std/text/json
        :drewc/ftw/httpd/cookies
        :drewc/ftw/httpd/handler
        :clan/base)

;;; Base reply struct, which defaults to a plain text reply
(defstruct reply
  (content-type
   status-code
   cookie-jar
   header-list)
  transparent: #t
  constructor: :init!)


;;; Overriding constructor for base reply struct
(defmethod {:init! reply}
  (lambda (self
           (status-code +http-ok+)
           (content-type "text/plain")
           (cookie-jar [])
           (header-list []))
    (struct-instance-init! self
                          content-type
                          status-code
                          cookie-jar
                          header-list)))


;;; Build header list from reply
(defmethod {reply->headers reply}
  (lambda (self)

    ;; make cookie header from cookie object
    (def (cookie->header c)
         (cons "Set-Cookie" (cookie->string c)))

    ;; make content-type header
    (def (content-type->header type)
         (cons "Content-Type" type))

    (let* ((type (reply-content-type self))
           (headers (reply-header-list self)) ;; header-list is an alist
           ;; add our Content-Type only if it is not already included in
           ;; the header list
           (headers (if (assoc "Content-Type" headers)
                        headers
                        (cons (content-type->header type)
                              headers)))
           (cookies (map (lambda (c)   ;; convert our cookies to an alist
                           (cookie->header c))
                         (reply-cookie-jar self))))
      ;; combine "normal" and cookie headers
      (append headers cookies))))


;; html reply, which defaults to an HTML5 content type
(defstruct (reply-html reply)
  ()
  transparent: #t
  constructor: :init!)


;;; Overriding constructor for html reply struct
(defmethod {:init! reply-html}
  (lambda (self
           (status-code +http-ok+)
           (content-type "text/html")
           (cookie-jar [])
           (header-list []))
    (struct-instance-init! self
                          content-type
                          status-code
                          cookie-jar
                          header-list)))


;; json reply, which defaults to an json content type
(defstruct (reply-json reply)
  ()
  transparent: #t
  constructor: :init!)


;;; Overriding constructor for json reply struct
(defmethod {:init! reply-json}
  (lambda (self
           (status-code +http-ok+)
           (content-type "application/json")
           (cookie-jar [])
           (header-list []))
    (struct-instance-init! self
                          content-type
                          status-code
                          cookie-jar
                          header-list)))


;;; helper method to perform an http-response-write from the given
;;; self object and an optional body.
;;; body is a string or u8vector and defaults to #f
;;; res is the response object.  If #f the response is taken from the
;;;   current-http-response parameter.
(defmethod {reply->http-response-write reply}
  (lambda (self (body #f) (res #f))
    (apply http-response-write (list (or res (current-http-response))
                                     (reply-status-code self)
                                     {reply->headers self}
                                     body))))


;;; helper method to perform an http-response-file from the given
;;; self object and a file path.
;;; file is a path string to the file to use as the return body
;;; res is the response object.  If #f the response is taken from the
;;;   current-http-response parameter.
(defmethod {reply->http-response-file reply}
  (lambda (self file (res #f))
    (apply http-response-file (list (or res (current-http-response))
                                    (reply-status-code self)
                                    {reply->headers self}
                                    file))))


;;; helper method to perform an http-response-begin from the given
;;; self object and an optional body.
;;; res is the response object.  If #f the response is taken from the
;;;   current-http-response parameter.
;;;
;;; The body must be sent in chunks using the http-response-chunk
;;; procedure and closed with the http-response-end procedure.
(defmethod {reply->http-response-begin reply}
  (lambda (self (res #f))
    (apply http-response-begin (list (or res (current-http-response))
                                     (reply-status-code self)
                                     {reply->headers self}))))


;;; helper method to perform an http-response-write from the given
;;; self object and an json string or data to convert to json.
;;; data is a json string or scheme data to convert to json.
;;; res is the response object.  If #f the response is taken from the
;;;   current-http-response parameter.
(defmethod {reply->http-response-write reply-json}
  (lambda (self (data #f) (res #f))
    (apply http-response-write (list (or res (current-http-response))
                                     (reply-status-code self)
                                     {reply->headers self}
                                     (json-object->string data)))))
