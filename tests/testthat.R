library(testthat)
library(renv)

Sys.unsetenv("RENV_TESTS_INITIALIZED")
Sys.unsetenv("RENV_TESTS_INITIALIZED_TESTTHAT")

renv:::renv_tests_init()

Sys.setenv("RENV_TESTS_INITIALIZED_TESTTHAT" = "1")

test_check("renv")
