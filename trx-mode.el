;;; trx-mode.el --- Visual Studio Test Results viewer  -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024  Marco Craveiro
;;
;; Author: Marco Craveiro <marco.craveiro@gmail.com>
;; Keywords: languages, csharp
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Viewer for Visual Studio Test Result Files (TRX).
;;
;;; Code:
(require 'project)
(require 'tree-widget)

;;------------------Customization options---------------------------------------
(defgroup trx nil
  "Visual Studio Test Results Files viewer."
  :group 'extensions)

;;------------------Functions copied from Sharper mode--------------------------

;;
;; For details on sharper mode see:
;;
;; - https://github.com/sebasmonia/sharper
;;
;; Most of the code was copied as-is, with minor modifications.
(defvar trx--sln-list-template "dotnet sln %t list"
  "Template for \"dotnet sln list\" invocations.")

(defun trx--message (text)
  "Show a TEXT as a message and log it, if `panda-less-messages' log only."
  (message "Sharper: %s" text)
  (trx--log "Package message:\n" text "\n"))

(defun trx--log-command (title command)
  "Log a COMMAND, using TITLE as header, using the predefined format."
  (trx--log
   (concat "[command] " title
           "\n " command
           "\n in directory: " default-directory
           "\n")))

(defun trx--log (&rest to-log)
  "Append TO-LOG to the log buffer.  Intended for internal use only."
  (let ((log-buffer (get-buffer-create "*trx-log*"))
        (text (cl-reduce (lambda (accum elem) (concat accum " " (prin1-to-string elem t))) to-log)))
    (with-current-buffer log-buffer
      (goto-char (point-max))
      (insert text)
      (insert "\n"))))

(defun trx--as-alist (the-list)
  "Convert THE-LIST to an alist by looping over the elements by pairs."
  ;; From this SO answer https://stackoverflow.com/a/19774752/91877
  (cl-loop for (head . tail) on the-list by 'cddr
           collect (cons head (car tail))))

(defun trx--strformat (template-name &rest args)
  "Apply `format-spec' to TEMPLATE-NAME using ARGS as key-value pairs.
Just a facility to make these invocations shorter."
  (format-spec template-name
               (trx--as-alist args)))

(defun trx--format-solution-projects (sln-path)
  "Get and format the projects for the solution at SLN-PATH."
  (cl-labels ((convert-to-entry (project)
                                (list project (vector project))))
    (let ((command (trx--strformat trx--sln-list-template
                                       ?t (shell-quote-argument sln-path))))
      (trx--log-command "List solution projects" command)
      (mapcar #'convert-to-entry
              (nthcdr 2 (split-string (shell-command-to-string command)
                                      "\n" t))))))

(defun trx--filename-sln-p (filename)
  "Return non-nil if FILENAME is a solution."
  (let ((extension (file-name-extension filename)))
    (string= "sln" extension)))

(defun trx--filename-trx-p (filename)
  "Return non-nil if FILENAME is a solution."
  (let ((extension (file-name-extension filename)))
    (string= "trx" extension)))

(defun trx--read-solution ()
  "Offer completion for solution files under the current project's root."
  (let* ((all-files (project-files (project-current t)))
         (sln-file (completing-read "Select project or solution: "
                                    all-files
                                    #'trx--filename-sln-p)))
    (trx--log-command "Using solution: " sln-file)
    sln-file))

;;------------------TRX Specific code---------------------------------------
(defun trx--read-test-results-file (path)
  "Read a TRX file given by PATH."
  (xml-parse-file path))

(defun trx--create-tree-widget (sln-path projects)
  "Create a tree widget for test results.
SLN-PATH is the solution we are processing.
PROJECTS is the list of projects in the solution."
  (let* ((sln-file (file-name-base sln-path))
         (buffer-name (format "*Visual Studio Test Results - %s*" sln-file))
         (buffer (get-buffer-create buffer-name)))
    (with-current-buffer buffer
      (erase-buffer)
      (widget-create
       'tree-widget
       :open t
       :tag sln-file
       :args (mapcar
              (apply-partially #'widget-convert 'item)
              (mapcar 'file-name-base (mapcar 'car projects)))
       (widget-setup)
      (switch-to-buffer (current-buffer))
      ))))

(defun trx-view-results ()
  "Opens the TRX tree buffer."
  (interactive)
  (let*
      ((sln-path (trx--read-solution))
       (projects (trx--format-solution-projects sln-path)))
    (trx--create-tree-widget sln-path projects)))

(provide 'trx-mode)
;;; trx-mode.el ends here
