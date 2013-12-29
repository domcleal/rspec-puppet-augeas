# Changelog

## 0.3.0
* add `augeas_lensdir` setting to add lenses to the Augeas load path (Jan
  Vansteenkiste)
* redefine idempotency to not also imply changes were made, fixes #7
* remove redundant 'should' from matcher descriptions (Aaron Hicks)
* add Travis CI instructions (Aaron Hicks)
* use --notypecheck to speed up augparse
* pin rspec-puppet to < 1.0.0 temporarily

## 0.2.3
* ignore metaparameters, fixes #1

## 0.2.2
* capture debug logs from resource catalog run
* fixed actual cause in failure messages

## 0.2.1
* detect lens/target options from resource lens/incl
* improve docs and examples in spec/ files
* add puppetlabs_spec_helper gem dependency
* devel: add code coverage report

## 0.2.0
* fix ruby 1.8 compatibility
* test utils: add augparse and augparse_filter test utils
* devel: include all test dependencies in Gemfile

## 0.1.0
* initial release, can run resources
* test utils: open files with Augeas
