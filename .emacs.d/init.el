;; -*- lexical-binding: t; -*-
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
	  (lambda ()
	    (setq gc-cons-threshold (* 16 1024 1024)
		  gc-cons-percentage 0.1)))

;;; enhance
(setq-default indent-tabs-mode nil)
(recentf-mode 1)
(save-place-mode 1)
(global-auto-revert-mode 1)
(global-so-long-mode 1)
(delete-selection-mode 1)
(electric-pair-mode 1)
(tool-bar-mode -1)
(winner-mode 1)
(fido-mode 1)
(prefer-coding-system 'utf-8)
(setq uniquify-buffer-name-style 'reverse
      visible-bell t
      inhibit-startup-screen t
      enable-recursive-minibuffers t
      redisplay-skip-fontification-on-input t
      jit-lock-defer-time 0.05
      save-interprogram-paste-before-kill t
      kill-do-not-save-duplicates t
      frame-inhibit-implied-resize t
      package-quickstart t
      dired-recursive-copies 'top
      dired-recursive-deletes 'top

      backup-directory-alist
      `(("." . ,(expand-file-name "~/.local/state/emacs/backup/")))
      )

(require 'misc)
(setq duplicate-line-final-position 1)
(global-set-key (kbd "C-c d") #'duplicate-dwim)

;;; ispell/flyspell
(with-eval-after-load 'ispell
  (setq ispell-program-name (or (executable-find "aspell") (executable-find "hunspell")
                                ispell-program-name)
        ispell-dictionary "en_US"))
(global-set-key (kbd "C-c s t") #'flyspell-mode)
(global-set-key (kbd "C-c s p") #'flyspell-prog-mode)

(with-eval-after-load 'dired (require 'dired-x))
(set-face-attribute 'default nil
                    :background (if (display-graphic-p) "grey15" nil)
                    :foreground (if (display-graphic-p) "wheat" nil)
                    :family "juliamono")

;;; text mode :font include juliamono unifont fairfaxhd jigmo
(add-hook 'text-mode-hook
          (lambda ()
            (face-remap-add-relative 'default :family "unifont" :height 140)))
;; org
(add-hook 'org-mode-hook
          (lambda ()
            (face-remap-add-relative 'org-block :family "juliamono")
            (face-remap-add-relative 'org-code :family "juliamono")
            (face-remap-add-relative 'org-block-begin-line :family "juliamono")
            (face-remap-add-relative 'org-block-end-line :family "juliamono")))
;; markdown
(add-hook 'markdown-mode-hook
          (lambda ()
            (face-remap-add-relative 'markdown-code-face :family "juliaMono")
            (face-remap-add-relative 'markdown-inline-code-face :family "juliamono")))

(add-to-list 'load-path (expand-file-name "site-lisp" user-emacs-directory))

;;; package
(require 'package)
(add-to-list 'package-archives
             ;'("org" . "https://orgmode.org/elpa/")
             ;'("nongnu" . "https://elpa.nongnu.org/packages/")
             '("melpa" . "https://melpa.org/packages/"))
;(package-initialize)
(setq package-archive-priorities '(("gnu"    . 40) ("nongnu" . 30)
                                   ("org"    . 20) ("melpa"  . 10)))

(defun ensure-installed (&rest packages)
  (let (refreshed)
    (dolist (p packages)
      (unless (package-installed-p p)
        (condition-case err
            (progn (unless refreshed (setq refreshed t) (package-refresh-contents))
                   (package-install p))
          (error (message "ensure-installed: %s: %s" p (error-message-string err))))))))

(ensure-installed 'magit 'paredit 'envrc
                  'sly                          ;; Common Lisp
                  'racket-mode 'geiser-chez     ;; Scheme
                  'haskell-mode                 ;; Haskell
                  'rustic ;'rust-mode           ;; Rust
                  'j-mode 'bqn-mode             ;; J, BQN
                  )

;;; envrc
(add-hook 'after-init-hook #'envrc-global-mode)

;;; magit
(autoload 'magit-status "magit" "Magit status." t)
(with-eval-after-load 'magit
  (setq magit-process-connection-type 'always))

;;; paredit
(dolist (hook '(lisp-mode-hook
                lisp-interaction-mode-hook
                emacs-lisp-mode-hook
                ielm-mode-hook
                scheme-mode-hook racket-mode-hook
                eval-expression-minibuffer-setup-hook))
  (add-hook hook #'enable-paredit-mode))

;;; scheme
(autoload 'geiser-mode "geiser-mode" "Geiser mode." t)
(autoload 'racket-mode "racket-mode" "Racket mode." t)

(add-hook 'scheme-mode-hook 'geiser-mode)

(with-eval-after-load 'geiser-mode
  (setq geiser-active-implementations '(chez guile)
        geiser-default-implementation 'chez
        geiser-chez-binary "scheme"))

;;; common lisp
(autoload 'sly "sly" "Start SLY" t)
(autoload 'sly-mode "sly" "SLY mode" t)

(setq sly-auto-select-connection 'always
      ;sly-kill-without-query-p t
      sly-description-autofocus t
      sly-inhibit-pipelining nil
      sly-load-failed-fasl 'always)
(with-eval-after-load 'sly
  (setq sly-lisp-implementations
        (let (impls)
          (dolist (spec '((sbcl "sbcl" "--dynamic-space-size" "2048")
                          (ccl "ccl")
                          (acl "acl")
                          (clisp "clisp")))
            (let ((path (executable-find (cadr spec))))
              (when path
                (push `(,(car spec) (,path ,@(cddr spec))) impls))))
          (nreverse impls))))
;; Don't turn on paredit in REPL
(add-hook 'sly-mrepl-mode-hook 'electric-pair-local-mode)
(add-hook 'lisp-mode-hook 'sly-mode)
(add-to-list 'auto-mode-alist '("\\.cl\\'" . lisp-mode))

;;; ocaml (opam install utop merlin tuareg)
;; switch projects outside emacs using direnv, then restart emacs
(let* ((prefix (getenv "OPAM_SWITCH_PREFIX"))
       (share (if prefix
                  (expand-file-name "share" prefix)
                (ignore-errors (car (process-lines "opam" "var" "share")))))
       (site-lisp (and share (expand-file-name "emacs/site-lisp" share))))
  (when (and site-lisp (file-directory-p site-lisp))
    (add-to-list 'load-path site-lisp)))

(autoload 'tuareg-mode "tuareg" nil t)
(add-to-list 'auto-mode-alist '("\\.ml[ily]?\\'" . tuareg-mode))

;; optional tools from opam
(dolist (spec '(("merlin" . merlin-mode)
                ("utop" . utop-minor-mode)))
  (when (locate-library (car spec))
    (autoload (cdr spec) (car spec) nil t)
    (add-hook 'tuareg-mode-hook (cdr spec) t)))

(when (locate-library "ocamlformat")
  (autoload 'ocamlformat "ocamlformat" nil t)
  (autoload 'ocamlformat-before-save "ocamlformat" nil t)
  (add-hook 'tuareg-mode-hook
            (lambda () (when (string-match-p "\\.mli?\\'" (or buffer-file-name ""))
                         (add-hook 'before-save-hook #'ocamlformat-before-save nil t)))))


;;; haskell
(autoload 'haskell-mode "haskell-mode" "Haskell mode." t)
(autoload 'haskell-cabal-mode "haskell-cabal" "Cabal mode." t)
(autoload 'interactive-haskell-mode "haskell" "Interactive Haskell minor mode." t)
(add-hook 'haskell-mode-hook 'interactive-haskell-mode)
(with-eval-after-load 'haskell-mode
  (setq haskell-process-suggest-remove-import-lines t
        haskell-process-auto-import-loaded-modules t))

;;; rust
;; rustic would otherwise start lsp-mode on every .rs buffer (rustic-lsp-setup-p)
;(autoload 'rust-mode "rust-mode" "Rust mode." t)
(setq rustic-lsp-client 'eglot rustic-lsp-setup-p nil)
(autoload 'rustic-mode "rustic" "Rustic mode." t)
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rustic-mode))
(with-eval-after-load 'eglot (setq eglot-autoshutdown t))

;;; j
(with-eval-after-load 'j-console
  (unless j-console-cmd
    (catch 'found
      (dolist (g '("~/j9*/jconsole.sh" "~/j9*/bin/jconsole" "/Applications/j9*/bin/jconsole"))
        (dolist (f (reverse (file-expand-wildcards g t)))
          (when (file-executable-p f) (throw 'found (setq j-console-cmd f))))))))

;;; BQN (REPL: C-c C-z; glyphs: `\' prefix, `\\' = literal \)
(with-eval-after-load 'bqn-mode
  (keymap-set bqn-mode-map "C-c C-d" #'bqn-comint-send-dwim)
  (keymap-set bqn-mode-map "C-c C-b" #'bqn-comint-send-buffer)
  (keymap-set bqn-mode-map "C-c C-k" #'bqn-keymap-mode)
  (keymap-set bqn-mode-map "C-c C-g" #'bqn-glyph-mode))

;;; agda
(defun load-agda2-mode ()
  (interactive)
  (unless (fboundp 'agda2-mode)
    (let ((exe (executable-find "agda-mode")))
      (unless exe (user-error "agda-mode not in PATH"))
      (load-file (let ((coding-system-for-read 'utf-8))
                   (car (process-lines exe "locate"))))
      (setq agda2-highlight-level 'interactive)))
  (agda2-mode))

(add-to-list 'auto-mode-alist '("\\.l?agda\\'" . load-agda2-mode))

;;; ------------- third-party -------------- ;;;
;; cweb https://github.com/ascherer/cweb
(autoload 'cweb-mode "cweb" "CWEB mode." t)
(add-to-list 'auto-mode-alist '("\\.w\\'" . cweb-mode))
(add-to-list 'auto-mode-alist '("\\.ch\\'" . cweb-mode))


;;;;;;;;;;;;;;;;;;;;;;;
;;; Don't edit this !!!
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(envrc geiser-chez geiser-guile haskell-mode magit paredit
           racket-mode rustic sly))
 '(tool-bar-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
