(defpackage #:lto-tests
  (:use #:cl #:fiveam #:lto-phase1)
  (:shadowing-import-from #:lto-phase1 #:kill #:posix-close #:posix-read #:posix-write #:sigkill #:forkpty #:execvp #:setenv)
  (:export #:run-tests))
