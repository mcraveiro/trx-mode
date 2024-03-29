;;; trx-mode.el --- A mode for processing Visual Studio Test Results files  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Marco Craveiro

;; Author: Marco Craveiro <marco.craveiro@gmail.com>
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Viewer for Visual Studio Test Result Files (TRX)

;;; Code:
(require 'tree-widget)



(defun trx-read-test-results-file (path)
  "Read a TRX file given by PATH."
  (xml-parse-file path))

(defun trx-create-tree-widget ()
  "Create a tree widget."
  (interactive)
  (with-current-buffer
    (get-buffer-create "*Visual Studio Test Results*")
    (setq-local trx-tree-widget
        (widget-create
         'tree-widget
         :open t
         :tag "one"
         :args
         (list (widget-convert
            'tree-widget
            :tag "two"
            :args (mapcar
                    (apply-partially #'widget-convert 'item)
                    '("three" "four"))))))
    (switch-to-buffer (current-buffer))))

(provide '.#trx-mode)
;;; trx-mode.el ends here
