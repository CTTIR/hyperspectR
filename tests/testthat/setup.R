# Loading cuvis.r pulls in the Cubert SDK, whose Vimba camera layer writes a
# VmbCPP.log into the session temp directory as a side effect of being loaded.
# R CMD check reports that as "detritus in the temp directory", so remove it
# once the suite finishes. Harmless when the SDK is absent.
if (requireNamespace("withr", quietly = TRUE)) {
  withr::defer(
    {
      for (f in c("VmbCPP.log", "CuvisLog.log")) {
        p <- file.path(tempdir(), f)
        if (file.exists(p)) unlink(p, force = TRUE)
      }
    },
    teardown_env()
  )
}
