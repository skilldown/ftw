#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/build-script)

(defbuild-script
  '("ftw/httpd/handler"
    "ftw/httpd/parameters"
    "ftw/httpd/endpoint/struct"
    "ftw/httpd/endpoint/queue"
    "ftw/httpd/endpoint/mux"
    "ftw/httpd/endpoint-test"
    "ftw/httpd/endpoint"
    "ftw/httpd/cookies"
    "ftw/httpd"
    "ftw/timestamp"
    "ftw/file"
    "ftw/shtml5"
    "ftw"
    "ftw/test/all-tests"))
