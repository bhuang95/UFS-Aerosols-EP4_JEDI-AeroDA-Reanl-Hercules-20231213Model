!
! this module --load the optics tables speficied in a resource file
!             -- destroy the tables
!             -- get aod at observations location from aer mixing ratio profiles
! ! interface:
!

MODULE module_luts

  USE chem_miemod
  USE module_kinds
  USE ufo_vars_mod

  IMPLICIT NONE

  PRIVATE

  INCLUDE 'mpif.h'

  PUBLIC :: get_cf_aod       ! return aod from aer mass mixing ratio,
  PUBLIC :: get_miechannels ! convert wavelengths to channels using mietables

  REAL(kind=kind_real) :: channel_offset = 1_kind_real 

CONTAINS

! ------------------------------------------------------------------------------


  SUBROUTINE get_cf_aod(nx, nlat, n_layers,&
         &var_aerosols, wavelengths, rcfile,&
         &rh, aero_layers,&
         &aod) !, aod_layers)

    IMPLICIT NONE

    INTEGER, INTENT(in)  :: nx, nlat, n_layers
    CHARACTER(len=*), INTENT(in)  :: var_aerosols(:)
    REAL(kind=kind_real), INTENT(in)  :: wavelengths(:) ! [nm]
    CHARACTER(len=*), INTENT(in)  :: rcfile     
    REAL(kind=kind_real), INTENT(in)  :: aero_layers(:,:,:,:)
    REAL(kind=kind_real), INTENT(in)  :: rh(:,:,:)
    REAL(kind=kind_single), INTENT(out) :: aod(:,:,:)

!later can declare as optional output
    REAL(kind=kind_single), ALLOCATABLE :: &
         &aod_layers(:,:,:,:)
    
    REAL(kind=kind_real), ALLOCATABLE :: idxchannel(:) 
    INTEGER             :: idxtable
    INTEGER :: iq, n, m, i, j, k, rc, nch, nq

    REAL(kind=kind_real) :: bext_, tau_

    TYPE(chem_mie) :: mietables        ! mie tables
    CHARACTER(len=16), ALLOCATABLE :: vname(:)        ! variable name

    nch=SIZE(wavelengths)
    nq=SIZE(var_aerosols)

    ALLOCATE(aod_layers(nx, nlat, n_layers, nch))
    ALLOCATE(vname(nq))
    ALLOCATE(idxchannel(nch))

    rc = 0

    mietables = chem_miecreate(rcfile,rc)
    IF ( rc /= 0 ) THEN
       PRINT *, 'cannot create mie tables from '//TRIM(rcfile)
       CALL mpi_abort(mpi_comm_world, rc)
    END IF

    DO n = 1, nch
       idxchannel(n) = -1 ! this is really the channel index
       DO m = 1, mietables%nch
          IF ( ABS(wavelengths(n) - (1.e9)*mietables%channels(m)) < &
               &channel_offset ) THEN
             idxchannel(n) = m
             EXIT
          END IF
       END DO
    END DO

    IF ( ANY(idxchannel < 0) ) THEN
       PRINT *, 'mie resource files does not set the required channel'
       PRINT *, 'channels requested:  ', wavelengths
       PRINT *, 'channels on rc file: ', 1.e+9 * mietables%channels
       rc = 99
       CALL mpi_abort(mpi_comm_world, rc)
    END IF

    DO iq =1, nq

       SELECT CASE (TRIM(var_aerosols(iq)))

       CASE (var_du001)
          vname(iq) = 'du001'
       CASE (var_du002)
          vname(iq) = 'du002'
       CASE (var_du003)
          vname(iq) = 'du003'
       CASE (var_du004)
          vname(iq) = 'du004'
       CASE (var_du005)
          vname(iq) = 'du005'

       CASE (var_ss001)
          vname(iq) = 'ss001'
       CASE (var_ss002)
          vname(iq) = 'ss002'
       CASE (var_ss003)
          vname(iq) = 'ss003'
       CASE (var_ss004)
          vname(iq) = 'ss004'
       CASE (var_ss005)
          vname(iq) = 'ss005'

       CASE (var_bcphobic)
          vname(iq) = 'bcphobic'
       CASE (var_bcphilic)
          vname(iq) = 'bcphilic'

       CASE (var_ocphobic)
          vname(iq) = 'ocphobic'
       CASE (var_ocphilic)
          vname(iq) = 'ocphilic'

       CASE (var_sulfate)
          vname(iq) = 'so4'

       CASE ('mass_fraction_of_nitrate001_in_air') 
          vname(iq) = 'no3an1'

       CASE ('mass_fraction_of_nitrate002_in_air')
          vname(iq) = 'no3an2'

       CASE ('mass_fraction_of_nitrate003_in_air')
          vname(iq) = 'no3an3'

       END SELECT
    ENDDO

    aod_layers = 0.0_kind_single

    DO iq = 1,nq

       idxtable = chem_miequeryidx(mietables,vname(iq),rc)

       IF ( rc/=0 .OR. idxtable == -1) THEN
          PRINT *, 'cannot get mie index for '//vname(iq)
          CALL mpi_abort(mpi_comm_world, rc)
       END IF

       DO n = 1, nch
          DO j = 1, nx
             DO i = 1, nlat 
                DO k =1, n_layers

                   CALL chem_miequery(mietables, idxtable, idxchannel(n),&
                        &aero_layers(j,i,k,iq), rh(j,i,k),&
                        &bext=bext_, rc= rc)
                  
                   aod_layers(j,i,k,n) = aod_layers(j,i,k,n) + &
                        &bext_*aero_layers(j,i,k,iq) 
                   
                END DO
             END DO
          END DO
       END DO
       
       IF ( rc /= 0 ) THEN
          PRINT *, 'cannot get chem_miequery'
          CALL mpi_abort(mpi_comm_world, rc)
       END IF
       
    ENDDO

    aod=SUM(aod_layers,dim=3)

    CALL chem_miedestroy(mietables, rc)
    IF ( rc /= 0 ) THEN
       PRINT *, 'cannot destroy mietables'
       CALL mpi_abort(mpi_comm_world, rc)
    END IF

    DEALLOCATE(idxchannel)
    DEALLOCATE(aod_layers)
    DEALLOCATE(vname)

  END SUBROUTINE get_cf_aod

  SUBROUTINE get_miechannels(rcfile,miechannels,rc)

!converts wavelengths to channels #'s in mietable

    IMPLICIT NONE

    CHARACTER(len=*), INTENT(in) :: rcfile
    INTEGER, INTENT(inout) :: miechannels(:)
    INTEGER, INTENT(out) :: rc

    TYPE(chem_mie) :: mietables
    INTEGER :: m,n,nch
    INTEGER, ALLOCATABLE :: channels(:)

    rc=0

    mietables = chem_miecreate(rcfile,rc)
    IF ( rc /= 0 ) THEN
       PRINT *, 'cannot create mie tables from '//TRIM(rcfile)
       CALL mpi_abort(mpi_comm_world, rc)
    END IF

    nch=SIZE(miechannels)

    ALLOCATE(channels(nch))

    DO n = 1, nch
       channels(n) = -1 ! this is really the channel index
       DO m = 1, mietables%nch
          IF ( ABS(miechannels(n) - (1.e9)*mietables%channels(m)) < channel_offset ) THEN
             channels(n) = m
             EXIT
          END IF
       END DO
    END DO

    IF ( ANY(channels < 0) ) THEN
       PRINT *, 'mie resource files does not set the required channel'
       PRINT *, 'channels requested:  ', channels
       PRINT *, 'channels on rc file: ', 1.e+9 * mietables%channels
       rc = 99     
       CALL mpi_abort(mpi_comm_world, rc)  
    END IF

    miechannels=channels

    DEALLOCATE(channels)

  END SUBROUTINE get_miechannels

END MODULE module_luts
