# Hemoglobin reference spectra

`prahl-hemoglobin-v1.csv` contains the numerical table compiled by Scott Prahl from W. B. Gratzer and N. Kollias, distributed in MNE-Python v1.10.2 as `mne/data/extinction_coef.mat`. The upstream BSD redistribution notice is preserved in `MNE-LICENSE.txt`; this third-party asset is covered by that notice. No upstream prose or fitting implementation is copied.

The JSON manifest pins the distribution, transformation and checksums. Wavelengths are in nm, 250–1000 at 2 nm spacing. Coefficients use decadic absorbance: A = epsilon * concentration_mol_per_L * pathlength_cm. They are not absorption coefficients for natural logarithms.

This table replaces the package's synthetic Gaussian models in fitting. Synthetic water, melanin and methemoglobin shapes remain available only through the explicit synthetic source and are not quantitative reference spectra. Neither these reference measurements nor a correct inversion validate diffuse tissue oxygenation measurements for a camera or clinical application.
