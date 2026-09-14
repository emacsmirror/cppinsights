;;; cppinsights-test.el --- Command configuration tests -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)
(require 'cppinsights)

(defmacro cppinsights-test--with-project (&rest body)
  "Run BODY in a temporary project with a source file path."
  (declare (indent 0))
  `(let* ((root (make-temp-file "cppinsights-test-" t))
          (source (expand-file-name "src/main file.cpp" root))
          (cppinsights-program "insights")
          (cppinsights-clang-opts '("-O0" "-std=c++20"))
          (cppinsights-extra-clang-opts nil)
          (cppinsights-compilation-database-directory nil))
     (unwind-protect
         (progn
           (make-directory (file-name-directory source) t)
           (cl-letf (((symbol-function 'cppinsights--project-root)
                      (lambda (_) root)))
             ,@body))
       (delete-directory root t))))

(defun cppinsights-test--database (directory)
  "Create an empty compilation database in DIRECTORY."
  (make-directory directory t)
  (with-temp-file (expand-file-name "compile_commands.json" directory)
    (insert "[]")))

(ert-deftest cppinsights-test-fallback ()
  (cppinsights-test--with-project
    (setq cppinsights-extra-clang-opts '("-isysroot" "/SDK path"))
    (should (equal (cppinsights--build-command source)
                   (list "insights" source "--" "-O0" "-std=c++20"
                         "-isysroot" "/SDK path")))
    (setq cppinsights-clang-opts nil cppinsights-extra-clang-opts nil)
    (should (equal (cppinsights--build-command source)
                   (list "insights" source "--")))))

(ert-deftest cppinsights-test-database-keeps-project-flags ()
  (cppinsights-test--with-project
    (cppinsights-test--database root)
    (setq cppinsights-extra-clang-opts '("-isysroot" "/SDK path" "-DVALUE=1"))
    (should (equal (cppinsights--build-command source)
                   (list "insights" source "-p" (file-name-as-directory root)
                         "--extra-arg=-isysroot" "--extra-arg=/SDK path"
                         "--extra-arg=-DVALUE=1")))))

(ert-deftest cppinsights-test-nearest-database ()
  (cppinsights-test--with-project
    (cppinsights-test--database root)
    (cppinsights-test--database (file-name-directory source))
    (should (equal (cppinsights--database-directory source)
                   (file-name-directory source)))))

(ert-deftest cppinsights-test-explicit-database ()
  (cppinsights-test--with-project
    (cppinsights-test--database (file-name-directory source))
    (let ((build (expand-file-name "build dir" root)))
      (cppinsights-test--database build)
      (dolist (setting (list "build dir" build))
        (setq cppinsights-compilation-database-directory setting)
        (should (equal (cppinsights--build-command source)
                       (list "insights" source "-p"
                             (file-name-as-directory build))))))))

(ert-deftest cppinsights-test-database-path-is-expanded ()
  (cppinsights-test--with-project
    (cl-letf (((symbol-function 'locate-dominating-file)
               (lambda (_filename _name) "~/sandbox/cpp/example/"))
              ((symbol-function 'file-regular-p) (lambda (_) t))
              ((symbol-function 'file-readable-p) (lambda (_) t)))
      (should (equal (cppinsights--database-directory source)
                     (expand-file-name "~/sandbox/cpp/example/"))))))

(ert-deftest cppinsights-test-invalid-explicit-database ()
  (cppinsights-test--with-project
    (cppinsights-test--database root)
    (setq cppinsights-compilation-database-directory "missing")
    (should-error (cppinsights--build-command source) :type 'user-error)
    (make-directory (expand-file-name "missing/compile_commands.json" root) t)
    (should-error (cppinsights--build-command source) :type 'user-error)))

(ert-deftest cppinsights-test-legacy-options ()
  (cppinsights-test--with-project
    ;; Use symbols to exercise old user settings without obsolete-use warnings.
    (set 'cppinsights-extra-args '("-std=c++17"))
    (set 'cppinsights-binary "/custom/insights")
    (should (equal (cppinsights--build-command source)
                   (list "/custom/insights" source "--" "-std=c++17")))))

;;; cppinsights-test.el ends here
