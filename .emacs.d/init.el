;; -*- lexical-binding: t; -*-
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
	  (lambda ()
	    (setq gc-cons-threshold (* 16 1024 1024)
		  gc-cons-percentage 0.1)))

;;; enhance
(require 'cl-lib)
(setq-default indent-tabs-mode nil)
(recentf-mode 1)
(save-place-mode 1)
(global-auto-revert-mode 1)
(delete-selection-mode 1)
(electric-pair-mode 1)
(tool-bar-mode -1)
(fido-mode 1)
(auto-image-file-mode 1)
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
      dired-recursive-copies 'top
      dired-recursive-deletes 'top

      backup-directory-alist
      `(("." . ,(expand-file-name "backups/" "~/.cache/emacs/")))
      )      
(with-eval-after-load 'dired (require 'dired-x))
(unless (display-graphic-p) (xterm-mouse-mode t))
(set-face-attribute 'default nil
                    :background (if (display-graphic-p) "grey15" nil)
                    :foreground (if (display-graphic-p) "wheat" nil)
                    :family "juliamono")

(add-to-list 'load-path (expand-file-name "site-lisp" user-emacs-directory))
;; Avoid placing large files in `site-lisp` to prevent slow startup.
(let ((default-directory
       (expand-file-name "site-lisp" user-emacs-directory)))
  (normal-top-level-add-subdirs-to-load-path))

;;; package
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/packages/")
        ("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(defun ensure-installed (&rest packages)
  (let (refreshed)
    (dolist (p packages)
      (unless (package-installed-p p)
        (unless refreshed
          (package-refresh-contents)
          (setq refreshed t))
        (package-install p)))))

(ensure-installed 'magit 'paredit  'envrc
                  'sly                          ;; Common Lisp
                  'haskell-mode                 ;; Haskell
                  'racket-mode 'geiser-chez
                  'geiser-guile                 ;; Scheme
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
        geiser-chez-binary "scheme"
        geiser-guile-binary "guile"))

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
;; Don't turn on paredit in REPL, but at least use electric-pair-mode
(add-hook 'sly-mrepl-mode-hook 'electric-pair-local-mode)
(add-hook 'lisp-mode-hook 'sly-mode)
(add-to-list 'auto-mode-alist '("\\.cl\\'" . lisp-mode))

;;; OCaml (opam install utop merlin tuareg)
;; Switch projects outside Emacs using direnv, then restart Emacs.
(let* ((prefix (getenv "OPAM_SWITCH_PREFIX"))
       (share (if prefix
                  (expand-file-name "share" prefix)
                (ignore-errors (car (process-lines "opam" "var" "share")))))
       (site-lisp (and share (expand-file-name "emacs/site-lisp" share))))
  (when (and site-lisp (file-directory-p site-lisp))
    (add-to-list 'load-path site-lisp)))

(autoload 'tuareg-mode "tuareg" nil t)

;; Optional tools from opam.
(dolist (spec '(("merlin" . merlin-mode)
                ("utop" . utop-minor-mode)))
  (when (locate-library (car spec))
    (autoload (cdr spec) (car spec) nil t)))

(defun ocaml-setup ()
  (when (fboundp 'merlin-mode)
    (merlin-mode 1))
  (when (fboundp 'utop-minor-mode)
    (utop-minor-mode 1)))

(add-hook 'tuareg-mode-hook #'ocaml-setup)
(add-to-list 'auto-mode-alist '("\\.ml[ily]?\\'" . tuareg-mode))

;;; haskell
(autoload 'haskell-mode "haskell-mode" "Haskell mode." t)
(autoload 'haskell-cabal-mode "haskell-cabal" "Cabal mode." t)
(autoload 'interactive-haskell-mode "haskell" "Interactive Haskell minor mode." t)
(add-hook 'haskell-mode-hook 'interactive-haskell-mode)
(with-eval-after-load 'haskell-mode
  (setq haskell-process-suggest-remove-import-lines t
        haskell-process-auto-import-loaded-modules t))

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

;; ------------- third-party -------------- ;;
(autoload 'color-mode "color-mode" "Colorize lines of file" t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes nil)
 '(package-selected-packages
   '(geiser-chez haskell-mode magit paredit racket-mode sly)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
