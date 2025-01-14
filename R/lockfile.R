
#' Lockfiles
#'
#' A **lockfile** records the state of a project at some point in time. In
#' particular, this implies capturing the \R packages installed (along with
#' their versions) within the project's private library.
#'
#' Projects can be restored from a lockfile using the [restore()] function.
#' This implies re-installing packages into the project's private library,
#' as encoded within the lockfile.
#'
#' While lockfiles are normally generated and used with [snapshot()] /
#' [restore()], they can also hand-edited if so desired. The structure is
#' similar to that of the Windows-style `.ini` file, with some provisioning for
#' nested sections.
#'
#' An example lockfile follows:
#'
#' ```
#' [renv]
#' Version=0.1.0
#'
#'
#' [R]
#' Version=3.5.1
#' Repositories=
#'   CRAN=https://cran.rstudio.com
#'
#'
#' [R/Package/markdown]
#' Package=markdown
#' Version=0.9
#' Source=CRAN
#' Hash=8515151150d7372bc76e0af15ef5dee0
#'
#'
#' [R/Package/mime]
#' Package=mime
#' Version=0.6
#' Source=CRAN
#' Hash=b1e49df8aef896bc8c0b749ef1da5a48
#' ```
#'
#' The sections used within a lockfile are described next.
#'
#' @section \[renv\]:
#'
#' Information about the version of `renv` used to manage this project.
#'
#' \tabular{ll}{
#' \strong{Version}     \tab The version of the `renv` package used with this project. \cr
#' }
#'
#' @section \[R\]:
#'
#' Properties related to the version of \R associated with this project.
#'
#' \tabular{ll}{
#' \strong{Version}      \tab The version of \R used. \cr
#' \strong{Repositories} \tab The \R repositories used in this project. \cr
#' }
#'
#' @section \[R/Package/*\]:
#'
#' Package records, related to the version of an \R package that was installed
#' at the time the lockfile was generated.
#'
#' \tabular{ll}{
#' \strong{Package}      \tab The package name. \cr
#' \strong{Version}      \tab The package version. \cr
#' \strong{Library}      \tab The library this package was installed in. \cr
#' \strong{Source}       \tab The location from which this package was retrieved. \cr
#' \strong{Hash}         \tab (Optional) A unique hash for this package, used for package caching. \cr
#' }
#'
#' Additional remote fields, further describing how the package can be
#' retrieved from its corresponding source, will also be included as
#' appropriate (e.g. for packages installed from GitHub).
#'
#' @section \[Python\]:
#'
#' Metadata related to the version of Python used with this project (if any).
#'
#' \tabular{ll}{
#' \strong{Version} \tab The version of Python being used. \cr
#' \strong{Type}    \tab The type of Python environment being used ("virtualenv", "conda", "system") \cr
#' \strong{Name}    \tab The (optional) name of the environment being used.
#' }
#'
#' Note that the `Name` field may be empty. In that case, a project-local Python
#' environment will be used instead (when not directly using a system copy of Python).
#'
#' @family reproducibility
#' @name lockfile
#' @rdname lockfile
NULL

renv_lockfile_init <- function(project) {

  lockfile <- list()
  lockfile$renv         <- list(Version = renv_package_version("renv"))
  lockfile$R            <- renv_lockfile_init_r(project)
  lockfile$Bioconductor <- renv_lockfile_init_bioconductor(project)
  lockfile$Python       <- renv_lockfile_init_python(project)
  class(lockfile) <- "renv_lockfile"
  lockfile

}

renv_lockfile_init_r <- function(project) {

  repos <- getOption("repos")
  repos[repos == "@CRAN@"] <- "https://cran.rstudio.com/"

  list(
    Version = format(getRversion()),
    Repositories = repos
  )
}

renv_lockfile_init_bioconductor <- function(project) {

  # if BiocManager / BiocInstaller is available, ask for the
  # current repositories; otherwise preserve the last-used
  # repositories (if any)
  repos <- catch(renv_bioconductor_repos())
  if (inherits(repos, "error"))
    repos <- getOption("bioconductor.repos")

  if (is.null(repos))
    return(NULL)

  list(Repositories = repos)

}

renv_lockfile_init_python <- function(project) {

  python <- Sys.getenv("RENV_PYTHON", unset = NA)
  if (is.na(python))
    return(NULL)

  if (!file.exists(python))
    return(NULL)

  info <- renv_python_info(python)
  if (is.null(info))
    return(NULL)

  version <- renv_python_version(python)
  type <- info$type
  root <- info$root
  name <- renv_python_envname(project, root, type)

  list(Version = version, Type = type, Name = name)
}

renv_lockfile_path <- function(project) {
  file.path(project, "renv.lock")
}

renv_lockfile_save <- function(lockfile, project) {
  renv_lockfile_write(lockfile, file = renv_lockfile_path(project))
}

renv_lockfile_load <- function(project) {

  path <- renv_lockfile_path(project)
  if (file.exists(path))
    return(renv_lockfile_read(path))

  renv_lockfile_init(project = project)

}

renv_lockfile_sort <- function(lockfile) {

  # ensure C locale for consistent sorting
  renv_scope_locale("LC_COLLATE", "C")

  # extract R records (nothing to do if empty)
  records <- lockfile$R$Package
  if (empty(records))
    return(lockfile)

  # sort the records
  sorted <- records[sort(names(records))]
  lockfile$R$Package <- sorted

  # return post-sort
  lockfile

}
