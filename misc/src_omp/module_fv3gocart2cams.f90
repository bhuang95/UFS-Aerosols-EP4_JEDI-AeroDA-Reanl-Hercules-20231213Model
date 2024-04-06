MODULE module_fv3gocart2cams

  USE module_fv3
  USE module_gocart_cams
  USE module_utils, ONLY: upper2lower

CONTAINS

  SUBROUTINE aggregate_fv3gocart2cams(fv3files_tracer,species,&
       &varnames_gocart,varname_cams,vardataij)


    CHARACTER(len=*), INTENT(in) :: fv3files_tracer(:)
    CHARACTER(len=*), INTENT(in) :: species
    CHARACTER(len=*), INTENT(in) :: varnames_gocart(:)
    CHARACTER(len=*), INTENT(in) :: varname_cams
    REAL, ALLOCATABLE, INTENT(out) :: vardataij(:,:,:,:)

    INTEGER :: nvars
    INTEGER :: ii,ig,jg,nxy,nlevs,nc,nt
    CHARACTER(len=1) :: jgc
    REAL, ALLOCATABLE :: tmp(:,:,:,:)

    LOGICAL :: dust,seas

    dust=.FALSE.
    seas=.FALSE.

    IF (INDEX(upper2lower(species),"dust") > 0) THEN 
       dust=.TRUE.
    ELSE IF (INDEX(upper2lower(species),"seas") > 0) THEN 
       seas=.TRUE.
    ELSE
       PRINT *,'cant be here'
       STOP(15)
    ENDIF

    nvars=SIZE(varnames_gocart)
    
    IF (INDEX(upper2lower(varname_cams),TRIM(species)) > 0) THEN
       IF (INDEX(varname_cams,'FINE') > 0) THEN
          ii=1
       ELSE IF (INDEX(varname_cams,'MEDIUM') > 0) THEN
          ii=2
       ELSE IF (INDEX(varname_cams,'COARSE') > 0) THEN
          ii=3
       ELSE IF (INDEX(varname_cams,'TOTAL') > 0) THEN
          ii=4
       ELSE
          PRINT *,'cant be here'
          STOP(12)
       ENDIF
    ENDIF

    DO ig=1,nvars
       
       IF (INDEX(upper2lower(varnames_gocart(ig)),&
            &TRIM(upper2lower(species))) > 0) THEN

!search for dust/seas bin index to match conversion table
          DO jg=1,LEN_TRIM(varnames_gocart(ig))
             WRITE(jgc,'(i1)')jg
             IF (INDEX(varnames_gocart(ig),jgc) > 0) EXIT
          ENDDO
          
          IF (ALLOCATED(tmp)) DEALLOCATE(tmp)
          CALL read_fv3_var(fv3files_tracer,varnames_gocart(ig),tmp)

          IF (.NOT. ALLOCATED(vardataij)) THEN
             nxy=SIZE(tmp,1)
             nlevs=SIZE(tmp,2)
             nc=SIZE(tmp,3)
             nt=SIZE(tmp,4)

             ALLOCATE(vardataij(nxy,nlevs,nc,nt))

             IF (dust) THEN 
                vardataij=tmp*gocart2cams_dust(jg,ii)
             ELSEIF (seas) THEN 
                vardataij=tmp*gocart2cams_seas(jg,ii)
             ELSE
                PRINT *,'cant be here'
                STOP(13)
             ENDIF

          ELSE

             IF (dust) THEN 
                vardataij=vardataij+tmp*gocart2cams_dust(jg,ii)
             ELSEIF (seas) THEN 
                vardataij=vardataij+tmp*gocart2cams_seas(jg,ii)
             ELSE
                PRINT *,'cant be here'
                STOP(14)
             ENDIF

          ENDIF

       ENDIF

    ENDDO
    
    IF (ALLOCATED(tmp)) DEALLOCATE(tmp)
       
  END SUBROUTINE aggregate_fv3gocart2cams

END MODULE module_fv3gocart2cams
