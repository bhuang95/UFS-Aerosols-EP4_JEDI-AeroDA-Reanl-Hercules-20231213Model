PROGRAM  nucaps_co2ioda
!  to format nnr for ioda
!  MZP, March 2020

  USE module_nucaps_co, ONLY: nucaps_co, get_nucaps_co,&
       &write_ioda_nucaps_co

  USE module_obs_thinning, ONLY: obs_thinning_nucaps_co

  IMPLICIT NONE

  TYPE(nucaps_co), ALLOCATABLE, DIMENSION(:) :: nucaps_co_record, &
       &nucaps_co_thin_record

  CHARACTER(len=10) :: center_date_time
  INTEGER :: nobs,nobs_thin

  INTEGER :: i

  CONTINUE

  CALL get_nucaps_co(nucaps_co_record)
  nobs=SIZE(nucaps_co_record)

  IF (ALLOCATED(nucaps_co_thin_record)) DEALLOCATE(nucaps_co_thin_record)
  CALL obs_thinning_nucaps_co(nucaps_co_record,nobs,&
       &nucaps_co_thin_record,nobs_thin,&
       &center_date_time)

  CALL write_ioda_nucaps_co(nucaps_co_thin_record,nobs_thin,&
       &center_date_time)
  
END PROGRAM nucaps_co2ioda




