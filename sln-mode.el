;;; sln-mode.el --- a major-mode for msvc's *.sln files
;;
;; Copyright 2013 Florian Kaufmann <sensorflo@gmail.com>
;;
;; Author: Florian Kaufmann <sensorflo@gmail.com>
;; Created: 2013
;; Keywords: languages
;; 
;; This file is not part of GNU Emacs.
;; 
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;; 
;; 
;;; Commentary:
;; 
;; A major-mode for msvc's *.sln files. Is currently only about syntax
;; highlightening.


;;; Variables:
(defvar sln-mode-hook nil
  "Normal hook run when entering sln mode.")

(defconst sln-re-uuid-raw
  (let ((hd "[a-fA-F0-9]"));hexdigit
    (concat hd"\\{8\\}-"hd"\\{4\\}-"hd"\\{4\\}-"hd"\\{4\\}-"hd"\\{12\\}"))
  "Regexp matching an uuid exclusive braces.")

(defconst sln-re-uuid
  (concat "{" sln-re-uuid-raw "}")
  "Regexp matching an uuid inclusive braces.")

(defconst sln-re-project-def
  (concat
   "^\\(?:Project(\"" sln-re-uuid "\")\\s-*=\\s-*" ; type
   "\\(\"\\([^\"\n]*?\\)\"\\)\\s-*,\\s-*"          ; name
   "\"[^\"\n]*?\"\\s-*,\\s-*"                      ; path
   "\\(\"{\\(" sln-re-uuid-raw "\\)}\"\\)\\)")     ; uuid
  "Regexp matching a project definition header line.
Subgroups:
1 project name inclusive quotes
2 project name only
3 project uuid inclusive quotes and braces
4 project uuid only")

(defvar sln-uuid-projectname-alist nil
  "alist: key=uuid, value=projectname.")
(make-variable-buffer-local 'sln-uuid-projectname-alist)

(defconst sln-font-lock-keywords
  (list
   (cons sln-re-uuid 'font-lock-constant-face)
   (list sln-re-project-def
         (list 1 'font-lock-function-name-face t)
         (list 3 'font-lock-function-name-face t))
   (list 'sln-keyword-function-put-overlay)))


;;; Code:
(defun sln-keyword-function-put-overlay(end)
  (when (re-search-forward
         (concat "^\\s-*{\\(" sln-re-uuid-raw "\\)}\\s-*=\\s-*{\\1}")
         end t)
    (let ((o (make-overlay (match-end 0) (match-end 0)))
          (projectname-raw
           (cdr (assoc (match-string-no-properties 1) sln-uuid-projectname-alist))))
      (overlay-put o 'after-string
                   (concat " (=" (or projectname-raw "unknown") ")"))
      t)))

(defun sln-parse()
  "Parses current buffer to generate `sln-uuid-projectname-alist'"
  (interactive)
  (save-excursion
    (save-restriction
      (setq sln-uuid-projectname-alist nil)
      (goto-char (point-min))
      (while (re-search-forward sln-re-project-def nil t)
        (setq sln-uuid-projectname-alist
              (cons (cons (match-string-no-properties 4)
                          (match-string-no-properties 2))
                    sln-uuid-projectname-alist))))))

(defun sln-unfontify-region-function (beg end)
  "sln-mode's function for `font-lock-unfontify-region-function'."
  (font-lock-default-unfontify-region beg end)
  
  ;; todo: this is an extremely brute force solution and interacts very badly
  ;; with many (minor) modes using overlays such as flyspell or ediff
  (remove-overlays beg end))

;;;###autoload
(define-derived-mode sln-mode text-mode "sln"
  "Major mode for editing msvc's *.sln files.
Turning on sln mode runs the normal hook `sln-mode-hook'."
  
  ;; syntax table
  (modify-syntax-entry ?$ ".")
  (modify-syntax-entry ?% ".")
  (modify-syntax-entry ?& ".")
  (modify-syntax-entry ?' ".")
  (modify-syntax-entry ?` ".")
  (modify-syntax-entry ?* ".")
  (modify-syntax-entry ?+ ".")
  (modify-syntax-entry ?. ".")
  (modify-syntax-entry ?/ ".")
  (modify-syntax-entry ?< ".")
  (modify-syntax-entry ?= ".")
  (modify-syntax-entry ?> ".")
  (modify-syntax-entry ?\\ ".")
  (modify-syntax-entry ?| ".")
  (modify-syntax-entry ?_ ".")
  (modify-syntax-entry ?\; ".")
  (modify-syntax-entry ?\" "\"")
  (modify-syntax-entry ?\# "<")
  (modify-syntax-entry ?\n ">")
  (modify-syntax-entry ?\r ">")

  ;; comments
  (set (make-local-variable 'comment-column) 0)
  (set (make-local-variable 'comment-start) "#")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'comment-start-skip) "\\(#[ \t]*\\)")
  (set (make-local-variable 'comment-end-skip) "[ \t]*\\(?:\n\\|\\'\\)")
  
  ;; font lock
  (set (make-local-variable 'font-lock-defaults)
       '(sln-font-lock-keywords))
  (set (make-local-variable 'font-lock-unfontify-region-function)
       'sln-unfontify-region-function)
  
  ;; auto runned stuff
  (sln-parse)
  (run-hooks 'sln-mode-hook))


(provide 'sln-mode)

;;; sln-mode.el ends here
