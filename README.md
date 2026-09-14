# cppinsights.el

[![EMACS](https://img.shields.io/badge/Emacs-28.1-922793?logo=gnu-emacs&logoColor=b39ddb&.svg)](https://www.gnu.org/savannah-checkouts/gnu/emacs/emacs.html)
![GitHub License](https://img.shields.io/github/license/ignity21/cppinsights.el)
[![MELPA](https://melpa.org/packages/cppinsights-badge.svg)](https://melpa.org/#/cppinsights)


An Emacs package that integrates with [C++ Insights](https://cppinsights.io/), a tool that transforms C++ source code into its expanded form, revealing the details the compiler sees after applying language features like templates, operator overloading, and lambda functions.

## Description

This package allows you to run C++ Insights directly from within Emacs, displaying the transformed code in a separate buffer. It helps C++ developers understand how the compiler interprets their code, making it easier to debug complex C++ features and learn about the language's inner workings.

## Installation

### Prerequisites

Before using this package, you need to install the C++ Insights command-line tool:

#### Windows
1. Install [WSL](https://docs.microsoft.com/en-us/windows/wsl/install) (Windows Subsystem for Linux)
2. Follow the Ubuntu instructions below within WSL

#### macOS
Using Homebrew:
```bash
brew install cmake llvm
git clone https://github.com/andreasfertig/cppinsights.git
cd cppinsights
mkdir build && cd build
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_CXX_COMPILER=clang++ ..
make
sudo make install
```

#### Ubuntu/Debian
```bash
sudo apt-get install cmake clang libclang-dev llvm
git clone https://github.com/andreasfertig/cppinsights.git
cd cppinsights
mkdir build && cd build
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
make
sudo make install
```

#### Arch Linux
Using AUR:
```bash
pamac install cppinsights
```

### Package Installation

#### With Straight
``` elisp
(use-package cppinsights
  :straight (:host github :repo "ignity21/cppinsights.el")
  :commands cppinsights-run
  :custom
  ;; Customize variables as needed
  (cppinsights-program "insights")  ;; Path to the insights binary
  (cppinsights-clang-opts '("-std=c++17"))  ;; Fallback flags without a compilation database
  :bind
  ;; Add keybinding for cppinsights-run
  (:map c++-mode-map
        ("C-c c i" . cppinsights-run)))

```

#### With Doom Emacs
In `packages.el`:
``` elisp
(package! cppinsights
  :recipe (:host github :repo "ignity21/cppinsights.el"))
```

In `config.el`:
``` elisp
(use-package! cppinsights
  :commands cppinsights-run
  :custom
  (cppinsights-program "insights")  ;; Path to the insights binary
  (cppinsights-clang-opts '("-O0" "-std=c++17"))  ;; Fallback flags without a compilation database
  :init
  ;; Add keybinding for cppinsights-run
  (map! :map c++-mode-map
        :desc "Run C++ Insights" "C-c i" #'cppinsights-run))
```

#### With `package-vc-install` (Emacs 30+ built-in)
``` elisp
(package-vc-install '(cppinsights :url "https://github.com/ignity21/cppinsights.el"))
```

## Usage

1. Open a C++ file in Emacs
2. Run `M-x cppinsights-run` to process the current file
3. A new buffer will open showing the transformed code

You can customize the package by:
- `M-x customize-group RET cppinsights RET`

## Compiler configuration

C++ Insights reads `compile_commands.json` through Clang Tooling. By default,
the package searches from the source file's directory upward and passes the
nearest database directory using `-p`. For a database in a build directory,
configure its location explicitly (relative to the project root, or the source
directory outside a project):

```elisp
(setq cppinsights-compilation-database-directory "build/")
```

An explicitly configured directory must contain a readable `compile_commands.json`.
Database parsing is delegated to C++ Insights. Clang Tooling may report a
database-loading error and continue without database flags; the package does
not retry with `cppinsights-clang-opts`. A nonzero exit displays the error buffer.

- `cppinsights-clang-opts` supplies fallback flags only when no database is found.
  Its default is `("-O0" "-std=c++20")`; it does not override project flags.
- `cppinsights-extra-clang-opts` defaults to `nil` and appends compiler arguments
  in both modes. In database mode, each argument is passed as `--extra-arg=...`,
  preserving the database's flags. In fallback mode, arguments follow the fallback
  flags after `--`.

Each list item is one argument; do not add shell quoting around paths with spaces.
Relative compiler paths use the database entry's working directory in database
mode, and the project root (or source directory) in fallback mode. Prefer absolute
paths for additional SDK and include directories.

Older configurations using `cppinsights-extra-args` and `cppinsights-binary`
remain supported as obsolete aliases for `cppinsights-clang-opts` and
`cppinsights-program`, respectively. The old arguments alias is fallback-only;
move flags needed with a database to `cppinsights-extra-clang-opts`.

### macOS SDK headers

If C++ Insights cannot find system headers such as `wchar.h`, check the selected
SDK and the flags in your compilation database. Run `xcrun --show-sdk-path` in
a terminal to obtain the SDK path, then use that actual path, for example:

```elisp
(setq cppinsights-extra-clang-opts
      '("-isysroot" "/absolute/path/to/MacOSX.sdk"))
```

This allows SDK flags to reach Clang even when a compilation database is used.
It does not repair an incompatible LLVM/libc++ installation; if errors persist,
check the same source and flags directly with `insights` outside Emacs.

## Key Bindings

You can add a key binding to your Emacs configuration:

```elisp
(keymap-set c++-mode-map "C-c c i" #'cppinsights-run)
```
