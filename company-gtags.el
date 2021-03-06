;;; company-gtags.el --- company-mode completion back-end for GNU Global

;; Copyright (C) 2009-2011, 2014  Free Software Foundation, Inc.

;; Author: Nikolaj Schumacher

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;

;;; Code:

(require 'company)
(require 'cl-lib)

(defgroup company-gtags nil
  "Completion back-end for GNU Global."
  :group 'company)

(defcustom company-gtags-executable
  (executable-find "global")
  "Location of GNU global executable."
  :type 'string)

(define-obsolete-variable-alias
  'company-gtags-gnu-global-program-name
  'company-gtags-executable "earlier")

(defvar company-gtags--tags-available-p 'unknown)
(make-variable-buffer-local 'company-gtags--tags-available-p)

(defvar company-gtags-modes '(c-mode c++-mode jde-mode java-mode php-mode))

(defun company-gtags--tags-available-p ()
  (if (eq company-gtags--tags-available-p 'unknown)
      (setq company-gtags--tags-available-p
            (locate-dominating-file buffer-file-name "GTAGS"))
    company-gtags--tags-available-p))

(defun company-gtags-fetch-tags (prefix)
  (with-temp-buffer
    (let (tags)
      (when (= 0 (call-process company-gtags-executable nil
                               (list (current-buffer) nil) nil "-xGq" (concat "^" prefix)))
        (goto-char (point-min))
        (cl-loop while
                 (re-search-forward (concat
                                     "^"
                                     "\\([^ ]*\\)" ;; completion
                                     "[ \t]+\\([[:digit:]]+\\)" ;; linum
                                     "[ \t]+\\([^ \t]+\\)" ;; file
                                     "[ \t]+\\(.*\\)" ;; definition 
                                     "$"
                                     ) nil t)
                 collect
                 (propertize (match-string 1)
                             'meta (match-string 4)
                             'location (cons (expand-file-name (match-string 3))
                                             (string-to-number (match-string 2)))
                             ))))))

;;;###autoload
(defun company-gtags (command &optional arg &rest ignored)
  "`company-mode' completion back-end for GNU Global."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-gtags))
    (prefix (and company-gtags-executable
                 (memq major-mode company-gtags-modes)
                 (not (company-in-string-or-comment))
                 (company-gtags--tags-available-p)
                 (or (company-grab-symbol) 'stop)))
    (candidates (company-gtags-fetch-tags arg))
    (sorted t)
    (duplicates t)
    (annotation (let ((meta (get-text-property 0 'meta arg)))
                  (when (string-match (concat arg "\\((.*)\\).*") meta)
                    (match-string 1 meta))))
    (meta (get-text-property 0 'meta arg))
    (location (get-text-property 0 'location arg))))

(provide 'company-gtags)
;;; company-gtags.el ends here
