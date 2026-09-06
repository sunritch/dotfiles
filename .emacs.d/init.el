;; -*-lexical-binding: t; -*-
(defvar file-name-handler-alist--orig file-name-handler-alist)
(setq gc-cons-threshold most-positive-fixnum
      file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
	  (lambda ()
	    (setq gc-cons-threshold (* 16 1024 1024)
		  gc-cons-percentage 0.1
                  file-name-handler-alist file-name-handler-alist--orig)))

(add-to-list 'load-path (expand-file-name "site-lisp" user-emacs-directory))
;; Recursively add subdirectories in `site-lisp` to `load-path`.
;; Avoid placing large files like EAF in `site-lisp` to prevent slow startup.
(let ((default-directory
       (expand-file-name "site-lisp" user-emacs-directory)))
  (normal-top-level-add-subdirs-to-load-path))

;; package
(require 'cl-lib)
(require 'package)
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/packages/")
        ("gnu" . "https://elpa.gnu.org/packages/")))

(defvar package-contents-refreshed nil)
(defun package-ensure-refreshed ()
  (unless package-contents-refreshed
    (package-refresh-contents)
    (setq package-contents-refreshed t)))
(defun package-locally-installed-p (package)
  (or (assq package package-alist)
      (package-built-in-p package)))
(defun ensure-installed (&rest packages)
  (when-let ((missing (cl-remove-if
                       #'package-locally-installed-p packages)))
    (package-ensure-refreshed)
    (mapc #'package-install missing)))

(ensure-installed 'magit 'paredit 'yasnippet 'sly 'tuareg 'merlin 'haskell-mode
                  'racket-mode 'geiser 'geiser-chez)

;; enhance
(setq-default indent-tabs-mode nil)
(recentf-mode 1)
(save-place-mode 1)
(electric-pair-mode 1)
(tool-bar-mode -1)
(ido-mode 1)
(auto-image-file-mode 1)
(prefer-coding-system 'utf-8)
(setq uniquify-buffer-name-style 'reverse
      visible-bell 1
      inhibit-startup-screen 1
      enable-recursive-minibuffers 1
      redisplay-skip-fontification-on-input 1
      jit-lock-defer-time 0.05
      save-interprogram-paste-before-kill 1
      kill-do-not-save-duplicates 1
      frame-inhibit-implied-resize 1
      dired-recursive-copies 'top
      dired-recursive-deletes 'top
      buffer-face-mode-face '(:family "Unifont" :height 120))
(with-eval-after-load 'dired (require 'dired-x))
(unless (display-graphic-p) (xterm-mouse-mode 1))
(set-face-attribute 'default nil
                    :background (if (display-graphic-p)
                                    "#022" nil)
                    :foreground (if (display-graphic-p)
                                    "wheat" nil)
                    :family "juliamono")

(dolist (pair '(("\\.cl\\'" . lisp-mode)
                ("\\.mll\\'" . tuareg-mode)
                ("\\.mly\\'" . tuareg-mode)
                ("\\.lhs\\'" . haskell-mode)
                ("\\.cabal\\'" . haskell-mode)
                ("\\.agda\\'" . agda2-mode)
                ("\\.lagda\\'" . agda2-mode)))
  (add-to-list 'auto-mode-alist pair))

;; magit
(autoload 'magit-status "magit" "Magit status." t)
(autoload 'magit-blame "magit" "Blame current file." t)
(autoload 'magit-log-buffer-file "magit" "Log current file." t)
(autoload 'magit-dispatch "magit" "Magit dispatch." t)
(autoload 'magit-file-dispatch "magit" "Magit file dispatch." t)
(global-set-key (kbd "C-x g") 'magit-status)
(with-eval-after-load 'magit
  (setq magit-auto-select-connection 'always)
  ;; other configs
)

;; yasnippet
(autoload 'yas-minor-mode "yasnippet" "YASnippet minor mode." t)
(autoload 'yas-reload-all "yasnippet" nil t)
(add-hook 'c++-mode-hook 'yas-minor-mode)

;; paredit
(autoload 'enable-paredit-mode "paredit" "Paredit of Lisp code." t)
(add-hook 'lisp-mode-hook 'enable-paredit-mode)
(add-hook 'lisp-interaction-mode-hook 'enable-paredit-mode)
(add-hook 'eval-expression-minibuffer-setup-hook 'enable-paredit-mode)
(add-hook 'emacs-lisp-mode-hook 'enable-paredit-mode)
(add-hook 'ielm-mode-hook 'enable-paredit-mode)
(add-hook 'scheme-mode-hook 'enable-paredit-mode)
(add-hook 'racket-mode-hook 'enable-paredit-mode)
(put 'paredit-forward-delete 'delete-selection 'supersede)
(put 'paredit-backward-delete 'delete-selection 'supersede)
(put 'paredit-newline 'delete-selection t)

;; Scheme
(autoload 'geiser-mode "geiser-mode" "Geiser mode." t)
(autoload 'racket-mode "racket-mode" "Racket mode." t)

(add-hook 'scheme-mode-hook 'geiser-mode)

(with-eval-after-load 'geiser-mode
  (setq geiser-active-implementations '(chez guile)
        geiser-default-implementation 'chez))

(with-eval-after-load 'geiser-chez
  (setq geiser-chez-binary "scheme"))

(with-eval-after-load 'geiser-guile
  (setq geiser-chez-binary "guile"))

;; common lisp
(remove-hook 'lisp-mode-hook 'cl-lisp-mode-hook)
(autoload 'sly "sly" "Start SLY" t)
(autoload 'sly-mode "sly" "SLY mode" t)

(setq sly-auto-select-connection 'always
      ;sly-kill-without-query-p t
      sly-description-autofocus t 
      sly-inhibit-pipelining nil
      sly-load-failed-fasl 'always
      ;; Make sure SLY knows about our SBCL
      sly-lisp-implementations
      `((sbcl (,(executable-find "sbcl") "--dynamic-space-size" "256"))))
;; Don't turn on paredit in REPL, but at least use electric-pair-mode
(add-hook 'sly-mrepl-mode-hook 'electric-pair-local-mode)
;; Make sure we don't clash with SLIME when starting
(add-hook 'lisp-mode-hook 'sly-mode)

;; OCaml (tuareg + merlin + utop)
;; at any time via `M-x opam-switch-to` (not just at startup).
(defvar opam-env-synced nil
  "Non-nil once the default opam switch's env has been applied at least once.")
(defvar opam-current-switch nil
  "Name of the opam switch currently synced into this Emacs session.")

(defun opam-shell-command-to-string (command)
  "Like `shell-command-to-string', but return nil unless COMMAND exits 0."
  (let* ((return-value 0)
         (return-string
          (with-output-to-string
            (setq return-value
                  (with-current-buffer standard-output
                    (process-file shell-file-name nil '(t nil) nil
                                  shell-command-switch command))))))
    (if (= return-value 0) return-string nil)))

(defun opam-apply-env (switch-arg)
  "Apply `opam env' output for SWITCH-ARG (e.g. \"--switch foo\" or \"\")
to the current Emacs process: PATH, exec-path, and other env vars."
  (let* ((command (concat "opam env --safe --sexp " switch-arg))
         (env (opam-shell-command-to-string command)))
    (when (and env (not (string= env "")))
      (dolist (var (car (read-from-string env)))
        (setenv (car var) (cadr var))
        (when (string= (car var) "PATH")
          (setq exec-path (split-string (cadr var) path-separator)))))))

(defun opam-sync-share-path ()
  "Add the current switch's emacs/site-lisp dir to `load-path'."
  (let ((share (opam-shell-command-to-string "opam var share --safe")))
    (when share
      (setq share (string-trim share))
      (when (file-directory-p share)
        (add-to-list 'load-path (expand-file-name "emacs/site-lisp" share))))))

(defun opam-restart-merlin-buffers ()
  "Restart merlin's process in every buffer with merlin-mode enabled.
Needed after switching opam switch, since merlin caches per-switch state."
  (when (and (featurep 'merlin) (fboundp 'merlin-command-restart))
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (when (bound-and-true-p merlin-mode)
          (ignore-errors (merlin-command-restart)))))))

(defun opam-switch-to (switch)
  "Interactively switch the active opam switch and resync PATH/exec-path/
load-path accordingly. Can be called at any time, not just at startup."
  (interactive
   (list (let ((default (car (split-string
                              (or (opam-shell-command-to-string
                                   "opam switch show --safe")
                                  "")))))
           (completing-read
            (format "opam switch (%s): " (or default "none"))
            (split-string
             (or (opam-shell-command-to-string "opam switch list -s --safe") "")
             "\n" t)
            nil t nil nil default))))
  (opam-apply-env (if (string= switch "") "" (concat "--switch " switch)))
  (opam-sync-share-path)
  (setq opam-current-switch switch
        opam-env-synced t)
  (opam-restart-merlin-buffers)
  (message "opam switch: %s" (if (string= switch "") "default" switch)))

(defun opam-ensure-env ()
  "Sync the default switch's env once, the first time a tuareg buffer opens.
Only runs once per session; use `opam-switch-to' for later switch changes."
  (unless opam-env-synced
    (opam-apply-env "")
    (opam-sync-share-path)
    (setq opam-env-synced t)))

;; --- autoloads: nothing here loads until an .ml/.mli file is opened ---
(autoload 'tuareg-mode     "tuareg" "OCaml mode."         t)
(autoload 'merlin-mode     "merlin" "Merlin mode."         t)
(autoload 'utop-minor-mode "utop"   "Minor mode for utop." t)

;; --- hooks: run in strict order so opam env is synced before anything
;; that depends on load-path/exec-path (merlin, utop) tries to load ---
(defun tuareg-setup ()
  "Enable OCaml tooling for the current buffer, in dependency order."
  (opam-ensure-env)     ; must run first — populates load-path/exec-path
  (merlin-mode 1)
  (utop-minor-mode 1))

(add-hook 'tuareg-mode-hook #'tuareg-setup)

(with-eval-after-load 'merlin
  (setq merlin-error-after-save nil)  ; check on demand, not on every save
  (set-face-background 'merlin-type-face "skyblue")
  (define-key merlin-mode-map (kbd "C-c <up>")   #'merlin-type-enclosing-go-up)
  (define-key merlin-mode-map (kbd "C-c <down>") #'merlin-type-enclosing-go-down))

(with-eval-after-load 'tuareg   
  (when (executable-find "ocamlformat")
    (autoload 'ocamlformat "ocamlformat" nil t)
    (define-key tuareg-mode-map (kbd "C-c C-f") #'ocamlformat)))

(global-set-key (kbd "C-c o s") #'opam-switch-to)

;; haskell
(autoload 'haskell-mode "haskell-mode" "Haskell mode.")
(autoload 'haskell-cabal-mode "haskell-cabal" "Cabal mode.")
(autoload 'interactive-haskell-mode "haskell" "Interactive Haskell minor mode." t)
(add-hook 'haskell-mode-hook 'interactive-haskell-mode)
(with-eval-after-load 'haskell-mode
  (setq haskell-process-suggest-remove-import-lines t
        haskell-process-auto-import-loaded-modules t))
;; agda
(autoload 'agda2-mode "agda2" "Agda mode." t)
(with-eval-after-load 'agda2-mode
  (load-file (let ((coding-system-for-read 'utf-8))
               (shell-command-to-string "agda --emacs-mode locate")))
  (require 'agda-input)
  (setq agda2-program-name "agda"
        agda2-highlight-level 'interactive))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
