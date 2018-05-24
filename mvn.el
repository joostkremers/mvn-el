;;; mvn.el --- Helper functions for the maven build tool  -*- lexical-binding: t -*-

;; Copyright (C) 2013 Andrew Gwozdziewycz <git@apgwoz.com>
;; Copyright (C) 2018 Joost Kremers <joostkremers@fastmail.fm>
;; All rights reserved.

;; Author: Andrew Gwozdziewycz <git@apgwoz.com>
;; Maintainer: Joost Kremers <joostkremers@fastmail.fm>
;; URL : https://github.com/joostkremers/mvn-el
;; Version: 0.1
;; Keywords: compilation, maven, java

;; This file is NOT part of GNU Emacs

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; A few helper functions for running mvn from within Emacs.

;;; Code:

(defgroup mvn nil "Maven helper functions" :group 'tools :prefix "mvn-")

(defcustom mvn-command "mvn"
  "Name of the mvn executable.
This can contain just the name of the executable or its full path."
  :group 'maven
  :type 'string)

(defcustom mvn-build-file-name nil
  "Name of the maven build file.
If nil, use the default name \"pom.xml\".  Note that this
variable is buffer-local and can be overridden with a file-local
or directory-local variable."
  :group 'maven
  :type '(choice (const :tag "Use 'pom.xml'" nil)
                 (string :tag "Use custom build file")))
(make-variable-buffer-local 'mvn-build-file-name)

(defcustom mvn-project-root-dir nil
  "Directory containing the project's build file.
If nil, use the default root dir (i.e., move up in the directory
  tree searching for `mvn-build-file-name'.  If provided a
  directory, it should end in a slash.  This variable is
  buffer-local and can be overridden with a file-local or
  directory-local variable."
  :group 'maven
  :type '(choice (const :tag "Use standard project root directory" nil)
                 (directory :tag "Use custom project root directory")))
(make-variable-buffer-local 'mvn-project-root-dir)

(defcustom mvn-show-output-buffer-on-error t
  "Show the maven output buffer when a command returns with an error."
  :group 'maven
  :type '(choice (const :tag "Show the output buffer on error" t)
                 (const :tag "Do not show the output buffer on error" nil)))

(defvar-local mvn-last-task "compile" "Last mvn task.")
(defvar mvn-task-history nil "History list of read task(s).")
(defvar mvn-buffer (get-buffer-create " *maven-output*") "Maven output buffer.")
(defvar mvn-dont-search-root nil "If set, `mvn' does not search for a project root.")

(defvar mvn-default-phases '("validate"
                          "initialize"
                          "generate-sources"
                          "process-sources"
                          "generate-resources"
                          "process-resources"
                          "compile"
                          "process-classes"
                          "generate-test-sources"
                          "process-test-sources"
                          "generate-test-resources"
                          "process-test-resources"
                          "test-compile"
                          "process-test-classes"
                          "test"
                          "package"
                          "pre-integration-test"
                          "integration-test"
                          "post-integration-test"
                          "verify"
                          "install"
                          "deploy")
  "Phases for the default lifecycle.")

(defvar mvn-clean-phases '("pre-clean"
                        "clean"
                        "post-clean")
  "Phases for the clean lifecycle.")

(defvar mvn-site-phases '("pre-site"
                       "site"
                       "post-site"
                       "site-deploy")
  "Phases for the site lifecycle.")

(defvar mvn-core-plugins '("clean:clean"
                        "clean:help"
                        "compiler:compile"
                        "compiler:testCompile"
                        "compiler:help"
                        "deploy:deploy"
                        "deploy:deploy-file"
                        "deploy:help"
                        "install:install"
                        "install:install-file"
                        "install:help"
                        "resources:resources"
                        "resources:testResources"
                        "resources:copy-resources"
                        "resources:help"
                        "site:site"
                        "site:deploy"
                        "site:run"
                        "site:stage"
                        "site:stage-deploy"
                        "site:attach-descriptor"
                        "site:jar"
                        "site:help"
                        "surefire:test"
                        "surefire:help"
                        "verifier:verify"
                        "verifier:help")
  "Core plugin targets.")

(defvar mvn-packaging-plugins '("ear:ear"
                             "ear:generate-application-xml"
                             "ear:help"
                             "jar:jar"
                             "jar:test-jar"
                             "jar:sign"
                             "jar:sign-verify"
                             "jar:help"
                             "rar:rar"
                             "rar:help"
                             "war:war"
                             "war:exploded"
                             "war:inplace"
                             "war:manifest"
                             "war:help"
                             "shade:shade"
                             "shade:help")
  "Packaging plugin targets.")

(defvar mvn-reporting-plugins '("changelog:changelog"
                             "changelog:dev-activity"
                             "changelog:file-activity"
                             "changelog:help"
                             "changes:announcement-mail"
                             "changes:announcement-generate"
                             "changes:changes-report"
                             "changes:jira-report"
                             "changes:changes-validate"
                             "changes:help"
                             "checkstyle:checkstyle"
                             "checkstyle:check"
                             "checkstyle:help"
                             "doap:generate"
                             "doap:help"
                             "docck:check"
                             "docck:help"
                             "javadoc:javadoc"
                             "javadoc:test-javadoc"
                             "javadoc:aggregate"
                             "javadoc:test-aggregate"
                             "javadoc:jar"
                             "javadoc:test-jar"
                             "javadoc:help"
                             "jxr:jxr"
                             "jxr:test-jxr"
                             "jxr:help"
                             "pmd:pmd"
                             "pmd:cpd"
                             "pmd:check"
                             "pmd:cpd-check"
                             "pmd:help"
                             "project-info-reports:cim"
                             "project-info-reports:dependencies"
                             "project-info-reports:dependency-convergence"
                             "project-info-reports:dependency-management"
                             "project-info-reports:index"
                             "project-info-reports:issue-tracking"
                             "project-info-reports:license"
                             "project-info-reports:mailing-list"
                             "project-info-reports:plugin-management"
                             "project-info-reports:project-team"
                             "project-info-reports:scm"
                             "project-info-reports:summary"
                             "project-info-reports:help"
                             "surefire-report:report"
                             "surefire-report:report-only"
                             "surefire-report:help")
  "Reporting plugin targets.")

(defvar mvn-tools-plugins '("ant:ant"
                         "ant:clean"
                         "ant:help"
                         "antrun:run"
                         "antrun:help"
                         "archetype:create"
                         "archetype:generate"
                         "archetype:create-from-project"
                         "archetype:crawl"
                         "archetype:help"
                         "assembly:assembly"
                         "assembly:directory"
                         "assembly:directory-single"
                         "assembly:single"
                         "assembly:help"
                         "dependency:copy"
                         "dependency:copy-dependencies"
                         "dependency:unpack"
                         "dependency:unpack-dependencies"
                         "dependency:resolve"
                         "dependency:list"
                         "dependency:sources"
                         "dependency:resolve-plugins"
                         "dependency:go-offline"
                         "dependency:purge-local-repository"
                         "dependency:build-classpath"
                         "dependency:analyze"
                         "dependency:analyze-dep-mgt"
                         "dependency:tree"
                         "dependency:help"
                         "enforcer:enforce"
                         "enforcer:display-info"
                         "enforcer:help"
                         "gpg:sign"
                         "gpg:sign-and-deploy-file"
                         "gpg:help"
                         "help:active-profiles"
                         "help:all-profiles"
                         "help:describe"
                         "help:effective-pom"
                         "help:effective-settings"
                         "help:evaluate"
                         "help:expressions"
                         "help:system"
                         "invoker:install"
                         "invoker:run"
                         "invoker:help"
                         "one:convert"
                         "one:deploy-maven-one-repository"
                         "one:install-maven-one-repository"
                         "one:maven-one-plugin"
                         "one:help"
                         "patch:apply"
                         "patch:help"
                         "pdf:pdf"
                         "pdf:help"
                         "plugin:descriptor"
                         "plugin:report"
                         "plugin:updateRegistry"
                         "plugin:xdoc"
                         "plugin:addPluginArtifactMetadata"
                         "plugin:helpmojo"
                         "plugin:help"
                         "release:clean"
                         "release:prepare"
                         "release:rollback"
                         "release:perform"
                         "release:stage"
                         "release:branch"
                         "release:help"
                         "reactor:resume"
                         "reactor:make"
                         "reactor:make-dependents"
                         "reactor:make-scm-changes"
                         "reactor:help"
                         "remote-resources:bundle"
                         "remote-resources:process"
                         "remote-resources:help"
                         "repository:bundle-create"
                         "repository:bundle-pack"
                         "repository:help"
                         "scm:branch"
                         "scm:validate"
                         "scm:add"
                         "scm:unedit"
                         "scm:export"
                         "scm:bootstrap"
                         "scm:changelog"
                         "scm:list"
                         "scm:checkin"
                         "scm:checkout"
                         "scm:status"
                         "scm:update"
                         "scm:diff"
                         "scm:update-subprojects"
                         "scm:edit"
                         "scm:tag"
                         "scm:help"
                         "source:aggregate"
                         "source:jar"
                         "source:test-jar"
                         "source:jar-no-fork"
                         "source:test-jar-no-fork"
                         "source:help"
                         "stage:copy"
                         "stage:help")
  "Tools plugin targets.")

(defvar mvn-ide-plugins '("eclipse:clean"
                       "eclipse:configure-workspace"
                       "eclipse:eclipse"
                       "eclipse:help"
                       "eclipse:install-plugins"
                       "eclipse:m2eclipse"
                       "eclipse:make-artifacts"
                       "eclipse:myeclipse"
                       "eclipse:myeclipse-clean"
                       "eclipse:rad"
                       "eclipse:rad-clean"
                       "eclipse:remove-cache"
                       "eclipse:to-maven"
                       "idea:clean"
                       "idea:help"
                       "idea:idea"
                       "idea:module"
                       "idea:project"
                       "idea:workspace")
  "IDE plugin targets.")

(defvar mvn-other-plugins '("plexus:app"
                         "plexus:bundle-application"
                         "plexus:bundle-runtime"
                         "plexus:descriptor"
                         "plexus:runtime"
                         "plexus:service"
                         "jetty:run-war"
                         "jetty:run"
                         "cargo:start"
                         "cargo:stop"
                         "dbunit:export"
                         "dbunit:operation"
                         "exec:exec"
                         "exec:java"
                         "exec:help"
                         "hibernate3:hbm2cfgxml"
                         "hibernate3:hbm2ddl"
                         "hibernate3:hbm2doc"
                         "hibernate3:hbm2hbmxml"
                         "hibernate3:hbm2java"
                         "hibernate3:schema-export"
                         "hibernate3:schema-update"
                         "groovy:compile"
                         "groovy:console"
                         "groovy:execute"
                         "groovy:generateStubs"
                         "groovy:generateTestStubs"
                         "groovy:help"
                         "groovy:providers"
                         "groovy:shell"
                         "groovy:testCompile"
                         "gwt:compile"
                         "gwt:eclipse"
                         "gwt:eclipseTest"
                         "gwt:generateAsync"
                         "gwt:help"
                         "gwt:i18n"
                         "gwt:test"
                         "javacc:help"
                         "javacc:javacc"
                         "javacc:jjdoc"
                         "javacc:jjtree"
                         "javacc:jjtree-javacc"
                         "javacc:jtb"
                         "javacc:jtb-javacc"
                         "jboss:configure"
                         "jboss:deploy"
                         "jboss:harddeploy"
                         "jboss:start"
                         "jboss:stop"
                         "jboss:undeploy"
                         "jboss-packaging:esb"
                         "jboss-packaging:esb-exploded"
                         "jboss-packaging:har"
                         "jboss-packaging:har-exploded"
                         "jboss-packaging:sar"
                         "jboss-packaging:sar-exploded"
                         "jboss-packaging:sar-inplace"
                         "jboss-packaging:spring"
                         "jpox:enhance"
                         "jpox:schema-create"
                         "jpox:schema-dbinfo"
                         "jpox:schema-delete"
                         "jpox:schema-info"
                         "jpox:schema-validate"
                         "make:autoreconf"
                         "make:chmod"
                         "make:chown"
                         "make:compile"
                         "make:configure"
                         "make:help"
                         "make:make-clean"
                         "make:make-dist"
                         "make:make-install"
                         "make:test"
                         "make:validate-pom"
                         "nbm:autoupdate"
                         "nbm:branding"
                         "nbm:cluster"
                         "nbm:directory"
                         "nbm:jar"
                         "nbm:nbm"
                         "nbm:populate-repository"
                         "nbm:run-ide"
                         "nbm:run-platform"
                         "spring-boot:help"
                         "spring-boot:repackage"
                         "spring-boot:run"
                         "tomcat:deploy"
                         "tomcat:exploded"
                         "tomcat:info"
                         "tomcat:inplace"
                         "tomcat:list"
                         "tomcat:redeploy"
                         "tomcat:resources"
                         "tomcat:roles"
                         "tomcat:run"
                         "tomcat:run-war"
                         "tomcat:sessions"
                         "tomcat:start"
                         "tomcat:stop"
                         "tomcat:undeploy"
                         "wagon:copy"
                         "wagon:download"
                         "wagon:download-single"
                         "wagon:help"
                         "wagon:list"
                         "wagon:merge-maven-repos"
                         "wagon:upload"
                         "wagon:upload-single"
                         "was6:clean"
                         "was6:ejbdeploy"
                         "was6:help"
                         "was6:installApp"
                         "was6:wsAdmin"
                         "was6:wsDefaultBindings"
                         "was6:wsListApps"
                         "was6:wsStartApp"
                         "was6:wsStartServer"
                         "was6:wsStopApp"
                         "was6:wsStopServer"
                         "was6:wsUninstallApp"
                         "weblogic:appc"
                         "weblogic:clientgen"
                         "weblogic:clientgen9"
                         "weblogic:deploy"
                         "weblogic:jwsc"
                         "weblogic:listapps"
                         "weblogic:redeploy"
                         "weblogic:servicegen"
                         "weblogic:start"
                         "weblogic:stop"
                         "weblogic:undeploy"
                         "weblogic:wsdlgen")
  "Other plugins.")

(defvar mvn-plugins-and-goals (append
                            mvn-default-phases
                            mvn-clean-phases
                            mvn-site-phases
                            mvn-core-plugins
                            mvn-packaging-plugins
                            mvn-reporting-plugins
                            mvn-tools-plugins
                            mvn-ide-plugins
                            mvn-other-plugins)
  "List of all plugins and goals.")

(defun mvn-get-task ()
  "Ask for a task to be executed.
Additional arguments can also be provided, separated by
`crm-separator'."
  (let ((task (completing-read-multiple (concat "Goal (default): ")
                                        mvn-plugins-and-goals nil
                                        nil nil 'mvn-task-history)))
    (if (> (length task) 0)
        (mapconcat 'identity task " ")
      "")))

(defun mvn-find-root (dir)
  "Find the root directory of the project to which DIR belongs."
  (if mvn-dont-search-root
      default-directory
    (or mvn-project-root-dir
        (locate-dominating-file dir (or mvn-build-file-name "pom.xml")))))

(defun mvn-build-file-arg ()
  "Return a build file argument for the current project.
This is either nil if the default build file name \"pom.xml\" is
used, or a list of the form `(\"-f\" \"<build-file-name>\")', for
use within the function `mvn'."
  (if mvn-build-file-name
      (list "--file" mvn-build-file-name)))

;;;###autoload
(defun mvn (&optional task &rest args)
  "Run \"mvn TASK\" in the current project's root directory.
ARGS are added to the mvn command call."
  (interactive)
  (let ((default-directory (mvn-find-root default-directory)))
    (if default-directory
        (let ((task (or task (mvn-get-task))))
          (setq mvn-last-task task)
          (unless (listp task)
            (setq task (list task)))
          (let ((res (apply #'call-process mvn-command nil mvn-buffer t (append (mvn-build-file-arg) task args))))
            (if (= res 0)
                (message "[mvn] `%s %s' successful." mvn-command task)
              (when mvn-show-output-buffer-on-error
                (display-buffer mvn-buffer))
              (error "[mvn] `%s %s' exited with non-zero exit status" mvn-command task))))
      (error "[mvn] Could not find a maven project for the current buffer"))))

;;;###autoload
(defun mvn-last ()
  "Rerun the last maven task in the current buffer."
  (interactive)
  (mvn (or mvn-last-task "")))

;;;###autoload
(defun mvn-compile ()
  "Compile the current project."
  (interactive)
  (mvn "compile"))

;;;###autoload
(defun mvn-clean ()
  "Clean the current project."
  (interactive)
  (mvn "clean"))

;;;###autoload
(defun mvn-test (prefix)
  "Run the current project's test suite.
With PREFIX argument non-nil, ask for a test to run."
  (interactive "P")
  (if (not prefix)
      (mvn "test")
    (let ((test (read-string "Test: ")))
      (mvn "test" (concat "-Dtest=" test)))))

;;;###autoload
(defun mvn-create-project (project package)
  "Create a maven project in the current directory.
PROJECT is the `artifactId', PACKAGE the `groupId'."
  (interactive "sProject: \nsPackage: ")
  (let ((mvn-dont-search-root t))
    (mvn "archetype:generate"
         (format "-DgroupId=%s" package)
         (format "-DartifactId=%s" project)
         "-DarchetypeArtifactId=maven-archetype-quickstart"
         "-DinteractiveMode=false")))

;;;###autoload
(defun mvn-package-and-execute ()
  "Package and execute the current project."
  (interactive)
  (mvn "package")
  (mvn "exec:java"))

(provide 'mvn)

;;; mvn.el ends here

;; Local Variables:
;; eval: (nameless-mode 1)
;; End:
