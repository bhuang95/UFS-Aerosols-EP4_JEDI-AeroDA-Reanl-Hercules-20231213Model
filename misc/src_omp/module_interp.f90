MODULE module_interp

  USE slint

  IMPLICIT NONE

CONTAINS

  SUBROUTINE p_interp_nxy(pin,pout,vardatain,vardataout)
    
    REAL, INTENT(in) :: pin(:,:,:,:),pout(:),vardatain(:,:,:,:)
    REAL, ALLOCATABLE, INTENT(out) :: vardataout(:,:,:,:)
    
    INTEGER :: i,j,k,l,m,nxy,nlevs,nplevs,nc,nt
    REAL :: p1,p2,w1,w2,pres

    ALLOCATE(vardataout(SIZE(pin,1),SIZE(pout),SIZE(pin,3),SIZE(pin,4)))

    nxy=SIZE(pin,1)
    nlevs=SIZE(pin,2)
    nplevs=SIZE(pout)
    nc=SIZE(pin,3)
    nt=SIZE(pin,4)

    DO k = 1,nplevs
       DO j=1,nc
          DO l=1,nt
             DO i=1,nxy
                pres=pout(k)
                IF (pres > pin(i,nlevs,j,l) ) THEN    
! lowest level values
                   vardataout(i,k,j,l)=vardatain(i,nlevs,j,l)
                ELSEIF (pres < pin(i,1,j,l) ) THEN
! top level values
                   vardataout(i,k,j,l)=vardatain(i,1,j,l) 
                ELSE
                   
                   DO m = 1, nlevs-1
                      IF (pres <= pin(i,m+1,j,l) .AND. &
                           &pres > pin(i,m,j,l) ) THEN
                         EXIT
                      ENDIF
                   ENDDO

                   p1 = pin(i,m,j,l)
                   p2 = pin(i,m+1,j,l)
                   w1 = LOG(pres/p1)/(LOG(p2/p1))
                   w2 = LOG(p2/pres)/(LOG(p2/p1))

                   vardataout(i,k,j,l)=w1*vardatain(i,m+1,j,l)+&
                        &w2*vardatain(i,m,j,l)

                ENDIF

             ENDDO
          ENDDO
       ENDDO
    ENDDO

  END SUBROUTINE p_interp_nxy

  SUBROUTINE h_interp(src_data,tgt_data)

    REAL, INTENT(in) :: src_data(:,:,:,:)
    REAL, INTENT(inout) :: tgt_data(:,:,:,:)

    INTEGER :: nlevs,nc,nt,i,j,k

    nlevs=SIZE(src_data,2)
    nc=SIZE(src_data,3)
    nt=SIZE(src_data,4)

    DO i=1,nt
       DO j=1,nc
          DO k=1,nlevs
             CALL bilinear_interp(src_data(:,k,j,i),tgt_data(:,k,j,i))
          ENDDO
       ENDDO
    ENDDO
    
  END SUBROUTINE h_interp

  SUBROUTINE p_interp_nx_ny(pin,pout,vardatain,vardataout)
    
    REAL, INTENT(in) :: pin(:,:,:,:),pout(:),vardatain(:,:,:,:)
    REAL, ALLOCATABLE, INTENT(out) :: vardataout(:,:,:,:)
    
    INTEGER :: i,j,k,l,m,nx,ny,nlevs,nplevs,nt
    REAL :: p1,p2,w1,w2,pres

    nx=SIZE(pin,1)
    ny=SIZE(pin,2)
    nlevs=SIZE(pin,3)
    nt=SIZE(pin,4)
    nplevs=SIZE(pout)

    ALLOCATE(vardataout(nx,ny,nplevs,nt))

    DO k = 1,nplevs
       pres=pout(k)
       DO l=1,nt
          DO i=1,nx
             DO j=1,ny
                IF (pres > pin(i,j,nlevs,l) ) THEN    
! lowest level values
                   vardataout(i,j,k,l)=vardatain(i,j,nlevs,l)
                ELSEIF (pres < pin(i,j,1,l) ) THEN
! top level values
                   vardataout(i,j,k,l)=vardatain(i,j,1,l) 
                ELSE
                   
                   DO m = 1, nlevs-1
                      IF (pres <= pin(i,j,m+1,l) .AND. &
                           &pres > pin(i,j,m,l) ) THEN
                         EXIT
                      ENDIF
                   ENDDO

                   p1 = pin(i,j,m,l)
                   p2 = pin(i,j,m+1,l)
                   w1 = LOG(pres/p1)/(LOG(p2/p1))
                   w2 = LOG(p2/pres)/(LOG(p2/p1))

                   vardataout(i,j,k,l)=w1*vardatain(i,j,m+1,l)+&
                        &w2*vardatain(i,j,m,l)

                ENDIF

             ENDDO
          ENDDO
       ENDDO
    ENDDO

  END SUBROUTINE p_interp_nx_ny

  
END MODULE module_interp
