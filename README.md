# mvn-el: [Emacs][0] things for [mvn][1] #

By [Andrew Gwozdziewycz](https://github.com/apg/mvn-el), licensed under the [GNU GPLv3][2]

Changes / updates by Joost Kremers.

This package provides a few helper functions for using maven from within Emacs.


## Installation ##

Put mvn.el in your `load-path` and add `(require 'mvn)` to your init file (`~/emacs.d/init.el`).

Alternatively, use `use-package`:

```
(use-package mvn
  :load-path "~/<path>/<to>/mvn-el/"
  :hook (java-mode . mvn-mode)
  :bind (:map mvn-mode-map
              ("s-m" . mvn-hydra/body))
  :config
  (defhydra mvn-hydra (:hint nil :exit t)
    "
  ^ ^                    ^ ^                       ╭───────┐
  ^ ^ Project            ^ ^ File                  │ Maven │
╭─^─^────────────────────^─^───────────────────────┴───────╯
  _N_ New project        _n_ New class
  _P_ Package project    _p_ Package file
  _R_ Run project        _r_ Run file

  _q_ Quit"
    ("N" mvn-create-project)
    ("P" mvn-package-project)
    ("R" mvn-run-project)
    ("n" mvn-new-class)
    ("p" mvn-package)
    ("r" mvn-run)
    ("q" nil)))
```


## Usage ##

The basic operation is to invoke `M-x mvn`, which will ask you for a goal.

`M-x mvn-last` will re-issue the last command

`M-x mvn-compile` will run the standard `mvn compile`

`M-x mvn-clean` will run the standard `mvn clean`

`M-x mvn-test` will run the standard `mvn test`

`M-x mvn-create-project` will create an mvn project in the current directory.

`M-x mvn-package-and-execute` will execute `mvn package` followed by `mvn exec:java`.

`mvn` can be called non-interactively too, in which case it's called as such: `(mvn "sometask")`. This means that you can can define your own functions like `mvn-compile` for your projects:

    (defun mvn-compile-full ()
        (interactive)
        (mvn "dependency:sources"))
        
By default, `(mvn <task>)` searches for the root directory of the current buffer's project before calling `mvn`. If you don't want this (and thus execute the `mvn` command in the current buffer's `default-directory`), bind `mvn-dont-search-root` to `t` before calling `(mvn <task>)`.


## Minor mode and keymap ##

`mvn.el' provides a minor mode `mvn-mode' and a keymap `mvn-mode-map'. Both are effectively empty, but the minor mode can be used to load `mvn.el' (if you use something like `use-package` to delay loading) and the keymap can be used to bind keys to the various `mvn-` commands. `mvn` doesn't bind any keys by default, because most people's keymaps are already cluttered as it is.


## Customizations ##

- `mvn-command`: The location of the maven executable. Default is `"mvn"`.
- `mvn-build-file-name`: Use an alternative build file name. Default is to use `"pom.xml"`.
- `mvn-project-root-dir`: Use an alternative project root. Default is to move up the directory tree searching for `mvn-build-file-name`.
- `mvn-show-output-buffer-on-error`: Show the output buffer if `mvn` returns with an error code. 


## Tips ##

When the compilation buffer looks garbled, it usually from the wrong terminal escape sequences.  You may insert following code into your init script so that compilation buffer can correctly shows colored messages [ansi-color][4]:

    (ignore-errors
      (require 'ansi-color)
      (defun colorize-compilation-buffer ()
        (when (eq major-mode 'compilation-mode)
          (let ((inhibit-read-only t))
            (if (boundp 'compilation-filter-start)
                (ansi-color-apply-on-region compilation-filter-start (point))))))
      (add-hook 'compilation-filter-hook 'colorize-compilation-buffer))

[0]: http://gnu.org/software/emacs
[1]: http://maven.apache.org
[2]: http://www.gnu.org/licenses/gpl.html
[3]: https://github.com/espenhw/malabar-mode
[4]: http://stackoverflow.com/questions/13397737/ansi-coloring-in-compilation-mode
