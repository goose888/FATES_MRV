#!/usr/bin/env bash

SRCDIR=$HOME/FATES_MRV/E3SM
cd ${SRCDIR}
GITHASH1=`git log -n 1 --format=%h`
cd components/elm/src/external_models/fates
GITHASH2=`git log -n 1 --format=%h`

export SITE_NAME=sanrafael                         # Name of folder with site data
SETUP_CASE=fates_mxbreeding254_spinup_`date +"%Y-%m-%d"`
#SETUP_CASE=fates_mxbreeding254_spinup_gaussianhrv

CASE_NAME=${SETUP_CASE}_${GITHASH1}_${GITHASH2}
basedir=$HOME/FATES_MRV/E3SM/cime/scripts
#export SITE_BASE_DIR=/global/scratch/users/shijie/cesm_input_datasets/atm/datm7/ELM_USRDAT_datasets
export SITE_BASE_DIR=/pscratch/sd/s/sshu3/FATES_MRV
export ELM_USRDAT_DOMAIN=domain.lnd.r0125_gx1v6_SanRafael.c231020.nc
export ELM_USRDAT_SURDAT=surfdata_0.125x0.125_simyr2000_SanRafael_2pft.c231020.nc
export ELM_USRDAT_LUCDAT=landuse.timeseries_0.125x0.125_hist_simyr1850-2015.SanRafael.c231020.nc
DIN_LOC_ROOT=/global/cfs/cdirs/e3sm/inputdata
DIN_LOC_ROOT_CLMFORC=${DIN_LOC_ROOT}/atm/datm7

export CIME_MODEL=e3sm
#### load_machine_files
cd $basedir
export RES=ELM_USRDAT
export COMPSET=I1850ELMFATES
project=m2467

export paramfolder=/global/homes/s/sshu3/FATES_MRV/parameter_file_sandbox/backup_sr_calibrated_candidates254
ninst=254
./create_newcase -case ${SITE_BASE_DIR}/${CASE_NAME} -res ${RES} -compset ${COMPSET} -mach pm-cpu -project $project --ninst=$ninst --multi-driver
cd ${SITE_BASE_DIR}/${CASE_NAME}
export DIN_LOC_ROOT_FORCE=${SITE_BASE_DIR}
export ELM_SURFDAT_DIR=${SITE_BASE_DIR}
export ELM_DOMAIN_DIR=${SITE_BASE_DIR}

./xmlchange STOP_OPTION=nyears
./xmlchange CONTINUE_RUN=FALSE
./xmlchange DEBUG=FALSE
./xmlchange RESUBMIT=0

# For transient run 
./xmlchange --append ELM_BLDNML_OPTS="-bgc_spinup on"
./xmlchange STOP_N=100
./xmlchange REST_N=20
./xmlchange RUN_STARTDATE='0001-01-01'

./xmlchange DIN_LOC_ROOT=${DIN_LOC_ROOT}

# SET PATHS TO SCRATCH ROOT, DOMAIN AND MET DATA (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange ATM_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange LND_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange DATM_MODE=CLM1PT
./xmlchange ELM_USRDAT_NAME=${SITE_NAME}
./xmlchange DIN_LOC_ROOT_CLMFORC=${DIN_LOC_ROOT_FORCE}

# No need to change on perlmutter
#./xmlchange MAX_TASKS_PER_NODE=16     # for lawrencium-lr3
#./xmlchange MAX_MPITASKS_PER_NODE=16  # for lawrencium-lr3

./xmlchange EXEROOT=${SITE_BASE_DIR}/$CASE_NAME/bld
./xmlchange RUNDIR=${SITE_BASE_DIR}/$CASE_NAME/run
./xmlchange DOUT_S_ROOT=${SITE_BASE_DIR}/archive/$CASE_NAME

./xmlchange JOB_WALLCLOCK_TIME=11:50:00
./xmlchange STOP_OPTION=nyears
./xmlchange DATM_CLMNCEP_YR_ALIGN=1
./xmlchange DATM_CLMNCEP_YR_START=1979
./xmlchange DATM_CLMNCEP_YR_END=2022

./xmlchange NTASKS_ATM=1
./xmlchange NTASKS_CPL=1
./xmlchange NTASKS_OCN=1
./xmlchange NTASKS_WAV=1
./xmlchange NTASKS_GLC=1
./xmlchange NTASKS_ICE=1
./xmlchange NTASKS_ROF=1
./xmlchange NTASKS_LND=1

for x  in `seq 1 1 $ninst`; do
    expstr=$(printf %04d $x)
    echo $expstr
    cat > user_nl_elm_$expstr <<EOF
suplphos = 'ALL'
suplnitro = 'ALL'
fsurdat = '${ELM_SURFDAT_DIR}/${ELM_USRDAT_SURDAT}'
finidat = ''
fates_paramfile = '${paramfolder}/fates_params_sr_ens_${expstr}.nc'
flanduse_timeseries = 'landuse.timeseries_0.125x0.125_hist_simyr1850-2015.SanRafael.c231020.nc'
check_finidat_year_consistency = .false.
do_harvest = .false.
do_transient_pfts = .false.
use_fates_logging = .false.
use_fates_nocomp = .true.
use_fates_fixed_biogeog = .true.
use_fates_inventory_init = .false.
!fates_inventory_ctrl_filename = '${SITE_BASE_DIR}/bci_inv_file_list.txt'
use_fates_ed_st3 = .false.
hist_empty_htapes = .false.
hist_mfilt = 60, 10
hist_nhtfrq = 0, -8760
hist_fexcl1 = 'FATES_WOOD_PRODUCT'
hist_fexcl2 = 'TBOT','QBOT'
EOF

    cat > user_nl_datm <<EOF
taxmode = "cycle","cycle","cycle"
streams = "datm.streams.txt.CLM1PT.ELM_USRDAT_NOZBOT 1979 1979 2022",
          "datm.streams.txt.presaero.clim_2000 1 1 1",
          "datm.streams.txt.topo.observed 1 1 1"  
EOF

done

./case.setup

# HERE WE NEED TO MODIFY THE STREAM FILE (DANGER ZONE - USERS BEWARE CHANGING)
./preview_namelists

for x  in `seq 1 1 $ninst`; do
    expstr=$(printf %04d $x)
    echo $expstr
   
    cp /pscratch/sd/s/sshu3/cesm_input_datasets/atm/datm7/ELMPT_data_streams/datm.streams.txt.CLM1PT.ELM_USRDAT_NOZBOT ${SITE_BASE_DIR}/${CASE_NAME}/run/datm.streams.txt.CLM1PT.ELM_USRDAT_NOZBOT
    cp /pscratch/sd/s/sshu3/cesm_input_datasets/atm/datm7/ELMPT_data_streams/datm.streams.txt.presaero.clim_2000 ${SITE_BASE_DIR}/${CASE_NAME}/run/datm.streams.txt.presaero.clim_2000
    cp /pscratch/sd/s/sshu3/cesm_input_datasets/atm/datm7/ELMPT_data_streams/datm.streams.txt.topo.observed ${SITE_BASE_DIR}/${CASE_NAME}/run/datm.streams.txt.topo.observed
    cp /pscratch/sd/s/sshu3/cesm_input_datasets/atm/datm7/ELMPT_data_streams/datm_in ${SITE_BASE_DIR}/${CASE_NAME}/run/datm_in
done
cp /pscratch/sd/s/sshu3/FATES_MRV/landuse.timeseries_0.125x0.125_hist_simyr1850-2015.SanRafael.c231020.nc ${SITE_BASE_DIR}/${CASE_NAME}/run/
#cp /global/scratch/users/shijie/cesm_input_datasets/atm/datm7/sanrafael_era5_bias_corrected/*.nc /global/scratch/users/shijie/FATES_MRV/${SITE_NAME}/CLM1PT_data
./case.build
#./case.submit --skip-preview-namelist

