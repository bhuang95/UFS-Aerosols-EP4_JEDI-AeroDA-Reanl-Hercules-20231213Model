MODULE module_m2gocart2cams

  USE module_gocart_cams
  USE module_utils, ONLY: upper2lower
  USE module_m2


CONTAINS

  SUBROUTINE aggregate_m2gocart2cams(m2file,species,&
       &varnames_gocart,varname_cams,vardataij)


    CHARACTER(len=*), INTENT(in) :: m2file
    CHARACTER(len=*), INTENT(in) :: species
    CHARACTER(len=*), INTENT(in) :: varnames_gocart(:)
    CHARACTER(len=*), INTENT(in) :: varname_cams
    REAL, ALLOCATABLE, INTENT(out) :: vardataij(:,:,:,:)

    INTEGER :: nvars
    INTEGER :: ii,ig,jg,nlon,nlat,nlevs,nt
    CHARACTER(len=1) :: jgc
    CHARACTER(len=2) :: m2short
    REAL, ALLOCATABLE :: tmp(:,:,:,:)

    LOGICAL :: dust,seas

    dust=.FALSE.
    seas=.FALSE.

    IF (INDEX(upper2lower(species),"dust") > 0) THEN 
       dust=.TRUE.
       m2short='DU'
    ELSE IF (INDEX(upper2lower(species),"seas") > 0) THEN 
       seas=.TRUE.
       m2short='SS'
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

!       PRINT *,upper2lower(varnames_gocart(ig))
!       PRINT *,upper2lower(m2short)
       
       IF (INDEX((upper2lower(varnames_gocart(ig))),&
            &TRIM(upper2lower(m2short))) > 0) THEN

!search for dust/seas bin index to match conversion table
          DO jg=1,LEN_TRIM(varnames_gocart(ig))
             WRITE(jgc,'(i1)')jg
             IF (INDEX(varnames_gocart(ig),jgc) > 0) EXIT
          ENDDO
          
          IF (ALLOCATED(tmp)) DEALLOCATE(tmp)
          CALL read_m2_var(m2file,varnames_gocart(ig),tmp)

          IF (.NOT. ALLOCATED(vardataij)) THEN
             nlon=SIZE(tmp,1)
             nlat=SIZE(tmp,2)
             nlevs=SIZE(tmp,3)
             nt=SIZE(tmp,4)

             ALLOCATE(vardataij(nlon,nlat,nlevs,nt))

             IF (dust) THEN 
                vardataij=tmp*gocart2cams_dust(jg,ii)
             ELSEIF (seas) THEN 
                vardataij=tmp*gocart2cams_seas(jg,ii)
             ELSE
                PRINT *,'cant be here'
                STOP(13)
             ENDIF

!             PRINT *,'@@@1',' Aggregating ',TRIM(varnames_gocart(ig)),jg,jgc,' for ',TRIM(varname_cams),gocart2cams_seas(jg,ii)


          ELSE

             IF (dust) THEN 
                vardataij=vardataij+tmp*gocart2cams_dust(jg,ii)
             ELSEIF (seas) THEN 
                vardataij=vardataij+tmp*gocart2cams_seas(jg,ii)
             ELSE
                PRINT *,'cant be here'
                STOP(14)
             ENDIF

!             PRINT *,'@@@2',' Aggregating ',TRIM(varnames_gocart(ig)),jg,jgc,' for ',TRIM(varname_cams),gocart2cams_seas(jg,ii)

          ENDIF

       ENDIF

    ENDDO
    
    IF (ALLOCATED(tmp)) DEALLOCATE(tmp)
       
  END SUBROUTINE aggregate_m2gocart2cams

END MODULE module_m2gocart2cams
