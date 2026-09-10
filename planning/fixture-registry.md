# Validation fixture registry

| Fixture | Evidence type | Construction / provenance | Intended assertion |
|---|---|---|---|
| Asymmetric 2×3×2 image | Algebraic spatial fixture | Distinct row/column/band values; ENVI bytes written with explicit traversal loops | Orientation for BSQ/BIL/BIP, both byte orders and TIFF |
| Linear/quadratic wavelength ramps | Algebraic spectral fixture | Exact polynomials on a uniform nm grid | SG support, signs, derivative scaling and backend equivalence |
| Identity endmembers | Analytic optimization fixture | Equality solution (0.5, 0.5) for y=(1,1); boundary solution (1,0) for y=(2,0.2) | Equality constraint and optimality |
| Masked outliers and NA pixels | Software robustness fixture | Identical valid values plus one excluded extreme/missing pixel | Invariance, failure isolation and pixel correspondence |
| Uniform/adjacent hot pixels | Algebraic detector fixture | Constant image with known corruptions; independent neighbor mean 5 | Robust detection and immutable replacement |
| Prahl Hb table v1 | Tabulated measurement reference | [Pinned manifest](../inst/extdata/prahl-hemoglobin-v1.json), MNE-Python v1.10.2 distribution, retained notice | Reference values, checksum, units and support |
| Exact 70/30 Hb mixture | Analytic model fixture | Direct decadic forward calculation from tabulated coefficients, independent of the simulator | Reference inversion and domain equivalence |
| Sensitivity cases | Synthetic model stress study | [Frozen case generator](../validation/model-sensitivity.R), explicit response/noise/gain/offset cases and holdout fractions | Expose model mismatch; not empirical tissue accuracy |
| Shiny uploads/downloads | Browser integration fixture | Real browser, extensionless upload/download paths, complete archive inspection | End-to-end explorer behavior |
| Cubert SDK fixtures | Mocked integration | Existing controlled SDK substitutions in test-io-cubert.R | Wrapper behavior only |
| TIVITA container fixture | Synthetic vendor-format fixture | tivis.r packaged example; [reader tests](../tests/testthat/test-io-tivita.R) | Binary/interface behavior only |
| Group evaluation fixture | Statistical software fixture | Four known groups, deterministic separable labels, unequal repeated observation counts | No group overlap and correct inference unit |

No real phantom, independent clinical cohort or hardware acquisition is included.
The simulator's `sto2_ground_truth` field is a legacy name for its own parameters,
not independent physiological evidence.
