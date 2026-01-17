# Lto

Lightweight terminal output (LTO) - rendering and PTY playback helper for Lisp.

Prerequisiti
- SBCL
- Quicklisp

Installazione
1. Installare SBCL (es. apt install sbcl)
2. Installare Quicklisp: curl -O https://beta.quicklisp.org/quicklisp.lisp && sbcl --load quicklisp.lisp --eval "(quicklisp-quickstart:install)" --quit

Esecuzione
- Per caricare il progetto: sbcl --non-interactive --eval "(ql:quickload :lto-phase1)" --quit
- Per eseguire lo script principale (se presente): sbcl --script main.lisp

Test
- Questo repository usa FiveAM per i test (installare via Quicklisp: (ql:quickload :fiveam)).

Contribuire
- Aprire issue/PR per bugfix o feature. Seguire lo stile di commit e aggiungere test quando possibile.
