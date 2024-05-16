# FATES_MRV
Works related to FATES MRV project.
1. Climate forcing generation: The raw climate forcing is based on ERA5 3-hourly 1/8 degree global climate forcing product, but fuse with the TerraClimate daily 1/24 deg global temperature and wind speed and Daymet daily 1 km x 1 km vapor pressure to adjust relative humidity. The central lat-lon location is used to extract the corresponding location and we later perform a simple bias correction based fusion for global temperature, wind speed and relative humidity.
2. Extract land surface dataset and wood harvest time series based on ELM surface dataset (global 1/8 degree, simulation year 2000).
3. Generate FATES parameter file with 2-PFT. Allometry equations are based on Mexican forest inventory for Peublo state collected and fitted by Jessica Needham.
4. PPE is performed to cover a wide enough parameter space and produce enough good candidates of paramter combinations for each simulation site. A list of criterias for selecting good candidates can be found in PPE_plot.ipynb or PPE_plot_perlmutter.ipynb.
5. Simulation with rotational logging (35-year length of rotation cycle) is performed using the parameter combinations from all candidates (N=27). We first produced a hypothetical curve and then run the model and try to match the secondary forest age and age straucture following the hypothetical curve.
6. 
