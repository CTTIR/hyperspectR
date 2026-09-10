# Audit finding closure register

Owner role for the engineering changes: package maintainer. Independent scientific,
statistical and device review remains separate from these software closures.

Each case has a permanent assertion using independently constructed values, a
known mathematical solution, or the actual explorer workflow. The baseline
reproductions are recorded in [audit-baseline.md](audit-baseline.md). No test uses
the temporary audit directory or downloads its expected values at runtime.

| Finding | Correction | Permanent evidence |
|---|---|---|
| F01 | Removed scene stretching from indices; old StO2 ratio method errors | [Model regressions](../tests/testthat/test-model-regressions.R), scene independence and migration assertion |
| F02 | SG output uses true full-window centers, with matching FWHM | [Contract regressions](../tests/testthat/test-contract-regressions.R), polynomial support |
| F03 | Spatial plots use row-fast data with x=column/y=row | [Spatial regressions](../tests/testthat/test-io-spatial-regressions.R), asymmetric image and index values |
| F04 | Raster cell conversion and ENVI no-flip handling corrected | [Spatial regressions](../tests/testthat/test-io-spatial-regressions.R), external TIFF view and independently encoded ENVI |
| F05 | Pinned tabulated Hb reference replaces Gaussian fitting data | [Model regressions](../tests/testthat/test-model-regressions.R), published values and known 70% mixture |
| F06 | Explicit reflectance/absorbance domain replaces value-range guessing | [Model regressions](../tests/testthat/test-model-regressions.R), equivalent reflectance/absorbance and rejected unknown domain |
| F07 | Masks applied before estimation, with NA locations retained | [Contract](../tests/testthat/test-contract-regressions.R) and [model](../tests/testthat/test-model-regressions.R) regressions for ROI, summary, PCA, unmixing and classification |
| F08 | Expected byte count and exact decoded length checked | [Spatial regressions](../tests/testthat/test-io-spatial-regressions.R), truncated binary |
| F09 | Analysis conditional panel uses valid JavaScript | [Explorer regressions](../tests/testthat/test-explorer-regressions.R), full app construction; [browser scenarios](../validation/browser.R) |
| F10 | ENVI upload stages a checked header/binary pair | [Explorer regressions](../tests/testthat/test-explorer-regressions.R) and [browser scenarios](../validation/browser.R), paired and incomplete uploads |
| F11 | Supplied cube initializes once | [Browser scenarios](../validation/browser.R), supplied-cube processing persists and reset restores it |
| F12 | Results invalidated on cube/parameter change; obsolete workers cancelled | [Explorer regressions](../tests/testthat/test-explorer-regressions.R), index/analysis invalidation and cancellation |
| F13 | SG derivative coefficients have correct sign and nm scaling | [Contract](../tests/testthat/test-contract-regressions.R) and [backend](../tests/testthat/test-io-spatial-regressions.R) polynomial assertions |
| F14 | Equality-constrained active-set solver replaces soft penalty | [Model regressions](../tests/testthat/test-model-regressions.R), identity and boundary solutions, KKT checks |
| F15 | Calibration dimensions, wavelength grids and known settings checked | [Contract regressions](../tests/testthat/test-contract-regressions.R), incompatible wavelengths and calibration QC |
| F16 | Wavelength sorting reorders FWHM with data | [Contract regressions](../tests/testthat/test-contract-regressions.R), reverse-order band metadata |
| F17 | ENVI micrometer conversion includes FWHM | [Spatial regressions](../tests/testthat/test-io-spatial-regressions.R), independent header values |
| F18 | Repair excludes center and detected/invalid neighbors | [Contract regressions](../tests/testthat/test-contract-regressions.R), replacement equals 5 |
| F19 | Robust neighborhood detection handles zero spread and adjacent defects | [Contract regressions](../tests/testthat/test-contract-regressions.R), uniform and adjacent hot pixels |
| F20 | Random-spectrum wavelengths follow each complete spectrum | [Spatial regressions](../tests/testthat/test-io-spatial-regressions.R), labeled spectral ramp |
| F21 | Shared spatial reconstruction preserves narrow dimensions | [Contract](../tests/testthat/test-contract-regressions.R), [spatial](../tests/testthat/test-io-spatial-regressions.R), and [model](../tests/testthat/test-model-regressions.R) one-row/column/pixel cases |
| F22 | PCA component count limited by sample and numerical rank | [Model regressions](../tests/testthat/test-model-regressions.R), three-pixel cube and saved transform |
| F23 | Unsupported wide integer reads/writes rejected | [Spatial regressions](../tests/testthat/test-io-spatial-regressions.R), encoded payloads and no partial output files |
| F24 | TIFF wavelength entry supplied to reader | [Explorer regressions](../tests/testthat/test-explorer-regressions.R) and [browser scenarios](../validation/browser.R), missing and valid wavelength input |
| F25 | Download bundles header, binary and provenance at Shiny's supplied path | [Explorer regressions](../tests/testthat/test-explorer-regressions.R), extensionless destination; [browser scenarios](../validation/browser.R), actual downloaded archive |

Additional regressions cover interrupted ENVI replacement rollback, unknown
wavelength metadata, classifier prediction, held-out preprocessing, batch resume,
and independent-group uncertainty. A software finding's closure does not imply
clinical validation of an associated method.
