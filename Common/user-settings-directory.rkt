;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; File: user-settings-directory.rkt
;; Author: Yong Cho
;; Email: Yong_Cho@student.uml.edu
;; File Description:
;; The set of procedures defined in this file defines the location of the user-
;; specific application settings directory for the Racket-QA application and 
;; provides procedures to obtain the path strings to the directory and the files 
;; in the directory to be used by other components of Racket-QA.
;;
;; The procedures defined in this module use following directories as the
;; user-specific application settings directory.
;;
;; %APPDATA%/Racket QA      (Windows)
;; $HOME/.Racket_QA         (Linux)
;; $HOME/Library/Racket QA  (Mac)
;;
;; Users of this API need not concern about the specific runtime platform.
;; Procedures in this API set will automatically find out the OS type at
;; runtime and use the correct path.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#lang racket

(require racket/file
         racket/system)

(provide (except-out (all-defined-out)
                     SETTINGS-DIRECTORY-NAME-WINDOWS
                     SETTINGS-DIRECTORY-NAME-UNIX
                     SETTINGS-DIRECTORY-NAME-MACOSX))


(define SETTINGS-DIRECTORY-NAME-WINDOWS "Racket QA")
(define SETTINGS-DIRECTORY-NAME-MACOSX "Racket QA")
(define SETTINGS-DIRECTORY-NAME-UNIX ".Racket_QA")



;; Returns the name of the user-specific application settings directory.
;; > (settings-directory-name)
;; "Racket QA"                    ;(Windows)
;; > (settings-directory-name)
;; ".Racket_QA"                   ;(Linux)
(define (settings-directory-name)
  (cond ((eq? (system-type) 'windows) SETTINGS-DIRECTORY-NAME-WINDOWS)
        ((eq? (system-type) 'unix) SETTINGS-DIRECTORY-NAME-UNIX)
        ((eq? (system-type) 'macosx) SETTINGS-DIRECTORY-NAME-MACOSX)
        (else #f)))



;; Returns the full path of the user-specific application settings directory.
;; > (settings-directory-path)
;; "C:\\Users\\yongjec\\AppData\\Roaming\\Racket QA"  ;(Windows)
;; "/home/yongjec/.Racket_QA"                         ;(Liunx)
(define (settings-directory-path)
  (cond ((eq? (system-type) 'windows)
         (string-append (getenv "APPDATA") "\\" SETTINGS-DIRECTORY-NAME-WINDOWS))
        ((eq? (system-type) 'unix)
         (string-append (getenv "HOME") "/" SETTINGS-DIRECTORY-NAME-UNIX))
        ((eq? (system-type) 'macosx) 
         (string-append (getenv "HOME") "/Library/" SETTINGS-DIRECTORY-NAME-MACOSX))
        (else #f)))



;; Returns the absolute path of a file or directory as it is located in the
;; user-specific application settings directory. This path string can be 
;; used with Racket file I/O procedures to create or access the file or 
;; directory.
;;
;; > (full-path-in-settings-directory "a file you want the full path string.txt")
;; "C:\\Users\\yongjec\\AppData\\Roaming\\Racket QA\\a file you want the full path string.txt"  ;(Windows)
;; "/home/yongjec/.Racket_QA/a file you want the full path.txt"                                 ;(Linux)
;;
;; > (full-path-in-settings-directory "smtp-info.conf")
;; "C:\\Users\\yongjec\\AppData\\Roaming\\Racket QA\\smtp-info.conf"                            ;(Windows)
;; "/home/yongjec/.Racket_QA/smtp-info.conf"                                                    ;(Linux)
;;
;; > (full-path-in-settings-directory "dir/filename.txt")                ;(Windows/Linux)
;; > (full-path-in-settings-directory "dir\\filename.txt")               ;(Windows/Linux)
;; "C:\\Users\\yongjec\\AppData\\Roaming\\Racket QA\\dir\\filename.txt"  ;(Windows)
;; "/home/yongjec/.Racket_QA/dir/filename.txt"                           ;(Linux)
;;
;; (define smtp-settings-file (full-path-in-settings-directory "smtp-settings.conf"))
;; (define out (open-output-file full-path-in-settings-directory 
;;                               #:mode 'binary #:exists 'truncate/replace))
;; (fprintf out "~a\t~a\t~a~n" server username password)
(define (full-path-in-settings-directory file-or-directory-name)
  (define cleansed-name (cleanse-path-string file-or-directory-name))
  (cond ((eq? (system-type) 'windows)
         (string-append (settings-directory-path) "\\" cleansed-name))
        ((or (eq? (system-type) 'unix)
             (eq? (system-type) 'macosx))
         (string-append (settings-directory-path) "/" cleansed-name))
        (else #f)))



;; Checks if the user-specific application settings directory exists for the current user.
;; This will usually return #f when the Racket-QA application is run for the first
;; time for the machine/user.
(define (settings-directory-exists?)
  (directory-exists? (settings-directory-path)))



;; Creates the user-specific application settings directory whose path is
;; the return value of (settings-directory-path).
;; This shouldn't need to be called more than once per machine/user,
;; but it is safe to call it multiple times. It will only create the
;; directory when it is not already present.
;;
;; > (settings-directory-exists?)
;; #f
;; > (create-settings-directory)
;; > (settings-directory-exists?)
;; #t
;; > (settings-directory-path)
;; "C:\\Users\\yongjec\\AppData\\Roaming\\Racket QA"  ;(Windows)
;; "/home/yongjec/.Racket_QA"                         ;(Linux)
(define (create-settings-directory)
  (when (not (directory-exists? (settings-directory-path)))
    (make-directory* (settings-directory-path))))



;; Checks if a file exists in the user-specific settings directory.
;;
;; > (file-exists-in-settings-directory? "some_file_that_is_not_there.txt")
;; #f
;; > (file-exists-in-settings-directory? "smtp-login-info.conf")
;; #t
;; > (file-exists-in-settings-directory? "Addresses/master-address.dat")   ;(Windows/Linux)
;; #t
;; > (file-exists-in-settings-directory? "Addresses\\master-address.dat")  ;(Windows/Linux)
;; #t
(define (file-exists-in-settings-directory? filename)
  (define cleansed-filename (cleanse-path-string filename))
  (file-exists? (full-path-in-settings-directory cleansed-filename)))



;; Checks if the specified sub-directory exists in the settings directory.
;; 
;; > (directory-exists-in-settings-directory? "Addresses")
;; #t
;; > (directory-exists-in-settings-directory? "Some Non-Existing Folder")
;; #f
;; > (directory-exists-in-settings-directory? "Addresses/Boston Office")   ;(Windows/Linux)
;; #t
;; > (directory-exists-in-settings-directory? "Addresses\\Boston Office")  ;(Windows/Linux)
;; #t
(define (directory-exists-in-settings-directory? dirname)
  (define cleansed-dirname (cleanse-path-string dirname))
  (cond ((eq? (system-type) 'windows)
         (directory-exists? (string-append (settings-directory-path) "\\" cleansed-dirname)))
        ((or (eq? (system-type) 'unix)
             (eq? (system-type) 'macosx))
         (directory-exists? (string-append (settings-directory-path) "/" cleansed-dirname)))
        (else #f)))



;; Creates a sub-directory in the user-specific application settings directory.
;; Has no effect if the specified directory already exists.
;; 
;; > (directory-exists-in-settings-directory? "Addresses")
;; #f
;; > (make-directory-in-settings-directory "Addresses")
;; > (directory-exists-in-settings-directory? "Addresses")
;; #t
;; 
;; > (make-directory-in-settings-directory "Addresses/Lowell Office")   ;(Windows/Linux)
;; > (make-directory-in-settings-directory "Addresses\\Lowell Office")  ;(Windows/Linux)
(define (make-directory-in-settings-directory dirname)
  (define cleansed-dirname (cleanse-path-string dirname))
  (if (not (directory-exists-in-settings-directory? cleansed-dirname))
      (cond ((eq? (system-type) 'windows)
             (make-directory* (string-append (settings-directory-path) "\\" cleansed-dirname)))
            ((or (eq? (system-type) 'unix)
                 (eq? (system-type) 'macosx))
             (make-directory* (string-append (settings-directory-path) "/" cleansed-dirname)))
            (else #f))
      #f))



;; Deletes a file from the user-specific application settings directory.
;; Has no effect if the file does not exist already.
;; 
;; > (file-exists-in-settings-directory? "unneeded_file.dat")
;; #t
;; > (delete-file-from-settings-directory "unneeded_file.dat")
;; > (file-exists-in-settings-directory? "unneeded_file.dat")
;; #f
;; 
;; > (delete-file-from-settings-directory "Addresses/unneeded-addresses.dat")   ;(Windows/Linux)
;; > (delete-file-from-settings-directory "Addresses\\unneeded-addresses.dat")  ;(Windows/Linux)
(define (delete-file-from-settings-directory filename)
  (define cleansed-filename (cleanse-path-string filename))
  (if (file-exists? (full-path-in-settings-directory cleansed-filename))
      (delete-file (full-path-in-settings-directory cleansed-filename))
      #f))



;; Renames a file or a sub-directory in the user-specific application settings directory.
;; If 'old' is a file and 'new' already exists, it will be overwritten.
;; If 'old' is a directory and 'new' already exists, an exception will be thrown.
;; 
;; > (rename-in-settings-directory "old-config.conf" "new-conf.conf")
;; > (rename-in-settings-directory "Old DB" "New DB")
;; > (rename-in-settings-directory "New DB\\old-db-name.dat" "New DB\\new-db-name.dat")  ;(Windows/Linux)
;; > (rename-in-settings-directory "New DB/old-db-name.dat" "New DB/new-db-name.dat")    ;(Windows/Linux)
(define (rename-something-in-settings-directory old new)
  (define cleansed-old (cleanse-path-string old))
  (define cleansed-new (cleanse-path-string new))
  (cond ((or (file-exists-in-settings-directory? cleansed-old)
             (directory-exists-in-settings-directory? cleansed-old))
         (rename-file-or-directory
          (full-path-in-settings-directory cleansed-old)
          (full-path-in-settings-directory cleansed-new)
          #t))
        (else #f)))



;; For Windows, applies a 'hidden' attribute to a file or directory.
;; For Linux or Mac, attaches a dot before the name of the file or directory.
;; This can be used with both absolute and relative path.
;; 
;; > (hide-file-or-directory "D:\\Data\\AVs")
;; > (hide-file-or-directory (full-path-in-settings-directory "smtp-credentials.dat"))
;; > (hide-file-or-directory "a-file-in-current-folder.txt")
(define (hide-file-or-directory filepath)
  (define dirpath (get-dirpath-from-filepath filepath))
  (define filename (get-filename-from-filepath filepath))
  (cond ((eq? (system-type) 'windows)
         (process (string-append "attrib +h \"" filepath "\"")))
        ((and (or (eq? (system-type) 'unix)
                  (eq? (system-type) 'macosx))
              (not (first-char-is-dot? filename)))
         (define new-filepath
           (string-append dirpath "/." filename))
         (process (string-append "mv " filepath " " new-filepath)))
        (else #f)))



;; Reverses hide-file-or-directory.
(define (unhide-file filepath)
  (cond ((eq? (system-type) 'windows)
         (process (string-append "attrib -h \"" filepath "\"")))
        ((member (system-type) '(unix macosx))
         (let ((dirpath (get-dirpath-from-filepath filepath))
               (filename (get-filename-from-filepath filepath)))
           (process (string-append
                     "mv " 
                     (whitespace-fix filepath)
                     " " 
                     (whitespace-fix 
                      (string-append
                       dirpath
                       "/"
                       (string-trim filename "." #:left? #t #:right? #f #:repeat? #t)))))))
        (else (void))))




;; Extracts the directory portion from a file path.
;; 
;; > (get-dirpath-from-filepath "/home/yongjec/.Racket_QA/smtp-credentials.conf")
;; "/home/yongjec/.Racket_QA"
;; 
;; > (get-dirpath-from-filepath "only_file_name.txt")
;; ""
(define (get-dirpath-from-filepath filepath)
  (cond ((eq? (system-type) 'windows)
         (if (pair? (regexp-match #rx"(.*)\\\\[^\\]*$" filepath))
             (cadr (regexp-match #rx"(.*)\\\\[^\\]*$" filepath))
             ""))
        ((or (eq? (system-type) 'unix)
             (eq? (system-type) 'macosx))
         (if (pair? (regexp-match #rx"(.*)/[^/]*$" filepath))
             (cadr (regexp-match #rx"(.*)/[^/]*$" filepath))
             ""))
        (else #f)))



;; Extracts the file name portion from a file path.
;; 
;; > (get-filename-from-filepath "/home/yongjec/.Racket_QA/smtp-credentials.conf")
;; "smtp-credentials.conf"
(define (get-filename-from-filepath filepath)
  (cond ((eq? (system-type) 'windows)
         (if (pair? (regexp-match #rx"\\\\([^\\]*)$" filepath))
             (cadr (regexp-match #rx"\\\\([^\\]*)$" filepath))
             filepath))
        ((or (eq? (system-type) 'unix)
             (eq? (system-type) 'macosx))
         (if (pair? (regexp-match #rx"/([^/]*)$" filepath))
             (cadr (regexp-match #rx"/([^/]*)$" filepath))
             filepath))
        (else #f)))



;; Checks if a string starts with a dot character.
;; 
;; > (first-char-is-dot? "smtp-credentials.conf")
;; #f
;; > (first-char-is-dot? ".smtp-credentials.conf")
;; #t
(define (first-char-is-dot? a-string)
  (pair? (regexp-match #rx"^\\." a-string)))



;; For Windows, replaces all / to \\.
;; For Linux and Mac, does the opposite.
;; 
;; > (cleanse-path-string "Addresses/master.db")    ;(Windows/Linux)
;; > (cleanse-path-string "Addresses\\master.db")   ;(Windows/Linux)
;; "Addresses\\master.db"                           ;(Windows)
;; "Addresses/master.db"                            ;(Linux)
;; 
;; > (cleanse-path-string "smtp-config.conf")
;; "smtp-config.conf"
(define (cleanse-path-string str)
  (cond ((eq? (system-type) 'windows)
         (string-replace str "/" "\\"))
        ((or (eq? (system-type) 'unix)
             (eq? (system-type) 'macosx))
         (string-replace str "\\" "/"))
        (else str)))


;; Miscellaneous utilities
(define (double-backslash windows-str)
  (when (eq? (system-type) 'windows)
    (string-replace windows-str "\\" "\\\\")))

(define (whitespace-fix a-string)
  (cond ((eq? (system-type) 'windows)
         (valid-path-windows a-string))
        ((member (system-type) '(unix macosx))
         (valid-path-linux a-string))
        (else "whitespace-fix: platform not supported")))

(define (valid-path-windows windows-str)
  (when (eq? (system-type) 'windows)
    (string-append "\"" windows-str "\"")))

(define (valid-path-linux linux-str)
  (when (member (system-type) '(unix macosx))
    (string-replace linux-str " " "\\ ")))
