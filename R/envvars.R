
renv_envvars <- function() {
  c(
    "R_PROFILE", "R_PROFILE_USER",
    "R_ENVIRON", "R_ENVIRON_USER",
    "R_LIBS_USER", "R_LIBS_SITE", "R_LIBS"
  )
}

renv_envvars_save <- function() {

  # save the common set of environment variables
  sources <- renv_envvars()
  env <- Sys.getenv(sources, unset = "<NA>")
  names(env) <- paste("RENV_DEFAULT", names(env), sep = "_")
  do.call(Sys.setenv, as.list(env))

  # also persist library paths as environment variable
  libpaths <- paste(renv_libpaths_all(), collapse = .Platform$path.sep)
  Sys.setenv(RENV_DEFAULT_LIBPATHS = libpaths)

}

renv_envvars_restore <- function() {

  Sys.unsetenv("RENV_PROJECT")

  # restore old environment variables
  sources <- paste("RENV_DEFAULT", renv_envvars(), sep = "_")
  env <- Sys.getenv(sources, unset = "<NA>")
  names(env) <- sub("^RENV_DEFAULT_", "", names(env))
  missing <- env == "<NA>"
  Sys.unsetenv(names(env[missing]))

  existing <- as.list(env[!missing])
  if (length(existing))
    do.call(Sys.setenv, existing)

  # restore old library paths
  libpaths <- Sys.getenv("RENV_DEFAULT_LIBPATHS", unset = NA)
  if (!is.na(libpaths)) {
    libpaths <- strsplit(libpaths, .Platform$path.sep, fixed = TRUE)[[1]]
    renv_libpaths_set(libpaths)
  }

}
