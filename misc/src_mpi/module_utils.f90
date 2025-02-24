MODULE module_utils

  PUBLIC :: upper2lower, lower2upper, replace_text, getindex, indexx

  INTERFACE indexx
     MODULE PROCEDURE indexx_r,indexx_d
  END INTERFACE indexx

CONTAINS

  FUNCTION upper2lower(str) RESULT(string)

    IMPLICIT NONE

    CHARACTER(*), INTENT(in) :: str
    CHARACTER(LEN(str))      :: string

    INTEGER :: ic, i

    CHARACTER(26), PARAMETER :: upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    CHARACTER(26), PARAMETER :: lower = 'abcdefghijklmnopqrstuvwxyz'

!   lowcase each letter if it is lowecase
    string = str
    DO i = 1, LEN_TRIM(str)
       ic = INDEX(upper, str(i:i))
       IF (ic > 0) string(i:i) = lower(ic:ic)
    END DO

  END FUNCTION upper2lower

  FUNCTION lower2upper(str) RESULT (string)

    IMPLICIT NONE

    CHARACTER(*), INTENT(in) :: str
    CHARACTER(LEN(str))      :: string

    INTEGER :: ic, i

    CHARACTER(26), PARAMETER :: upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    CHARACTER(26), PARAMETER :: lower = 'abcdefghijklmnopqrstuvwxyz'

!   lowcase each letter if it is lowecase
    string = str
    DO i = 1, LEN_TRIM(str)
       ic = INDEX(lower, str(i:i))
       IF (ic > 0) string(i:i) = upper(ic:ic)
    END DO

  END FUNCTION lower2upper

  FUNCTION replace_text(s,text,rep) RESULT(outs) 
    CHARACTER(*)        :: s,text,rep
    CHARACTER(LEN(s)+100) :: outs  ! provide outs with extra 100 char len
    INTEGER             :: i, nt, nr

    outs = s ; nt = LEN_TRIM(text) ; nr = LEN_TRIM(rep)
    DO
       i = INDEX(outs,text(:nt)) ; IF (i == 0) EXIT
       outs = outs(:i-1) // rep(:nr) // outs(i+nt:)
    END DO

  END FUNCTION replace_text

  INTEGER FUNCTION getindex(varnames,usrname)
    IMPLICIT NONE
    CHARACTER(len=*),INTENT(in) :: varnames(:)
    CHARACTER(len=*),INTENT(in) :: usrname
    INTEGER i
    getindex=-1
    DO i=1,SIZE(varnames)
       IF(TRIM(usrname)==TRIM(varnames(i))) THEN
          getindex=i
          EXIT
       ENDIF
    ENDDO
  END FUNCTION getindex

  SUBROUTINE indexx_r(n,arr,indx)
    INTEGER n,indx(n),M,NSTACK
    REAL arr(n)
    PARAMETER (M=7,NSTACK=50)
    INTEGER i,indxt,ir,itemp,j,jstack,k,l,istack(NSTACK)
    REAL a
    DO j=1,n
       indx(j)=j
    ENDDO
    jstack=0
    l=1
    ir=n
1   IF(ir-l.LT.M)THEN
       DO j=l+1,ir
          indxt=indx(j)
          a=arr(indxt)
          DO i=j-1,1,-1
             IF(arr(indx(i)).LE.a)GOTO 2
             indx(i+1)=indx(i)
          ENDDO
          i=0
2         indx(i+1)=indxt
       ENDDO
       IF(jstack.EQ.0)RETURN
       ir=istack(jstack)
       l=istack(jstack-1)
       jstack=jstack-2
    ELSE
       k=(l+ir)/2
       itemp=indx(k)
       indx(k)=indx(l+1)
       indx(l+1)=itemp
       IF(arr(indx(l+1)).GT.arr(indx(ir)))THEN
          itemp=indx(l+1)
          indx(l+1)=indx(ir)
          indx(ir)=itemp
       ENDIF
       IF(arr(indx(l)).GT.arr(indx(ir)))THEN
          itemp=indx(l)
          indx(l)=indx(ir)
          indx(ir)=itemp
       ENDIF
       IF(arr(indx(l+1)).GT.arr(indx(l)))THEN
          itemp=indx(l+1)
          indx(l+1)=indx(l)
          indx(l)=itemp
       ENDIF
       i=l+1
       j=ir
       indxt=indx(l)
       a=arr(indxt)
3      continue
       i=i+1
       if(arr(indx(i)).lt.a)goto 3
4      continue
       j=j-1
       if(arr(indx(j)).gt.a)goto 4
       if(j.lt.i)goto 5
       itemp=indx(i)
       indx(i)=indx(j)
       indx(j)=itemp
       goto 3
5      indx(l)=indx(j)
       indx(j)=indxt
       jstack=jstack+2
       if(jstack.gt.NSTACK)pause 'NSTACK too small in indexx'
       if(ir-i+1.ge.j-l)then
          istack(jstack)=ir
          istack(jstack-1)=i
          ir=j-1
       else
          istack(jstack)=j-1
          istack(jstack-1)=l
          l=i
       endif
    endif
    goto 1
  END subroutine indexx_r


  SUBROUTINE indexx_d(n,arr,indx)
    INTEGER n,indx(n),M,NSTACK
    REAL(kind=8) arr(n)
    PARAMETER (M=7,NSTACK=50)
    INTEGER i,indxt,ir,itemp,j,jstack,k,l,istack(NSTACK)
    REAL(kind=8) a
    DO j=1,n
       indx(j)=j
    ENDDO
    jstack=0
    l=1
    ir=n
1   IF(ir-l.LT.M)THEN
       DO j=l+1,ir
          indxt=indx(j)
          a=arr(indxt)
          DO i=j-1,1,-1
             IF(arr(indx(i)).LE.a)GOTO 2
             indx(i+1)=indx(i)
          ENDDO
          i=0
2         indx(i+1)=indxt
       ENDDO
       IF(jstack.EQ.0)RETURN
       ir=istack(jstack)
       l=istack(jstack-1)
       jstack=jstack-2
    ELSE
       k=(l+ir)/2
       itemp=indx(k)
       indx(k)=indx(l+1)
       indx(l+1)=itemp
       IF(arr(indx(l+1)).GT.arr(indx(ir)))THEN
          itemp=indx(l+1)
          indx(l+1)=indx(ir)
          indx(ir)=itemp
       ENDIF
       IF(arr(indx(l)).GT.arr(indx(ir)))THEN
          itemp=indx(l)
          indx(l)=indx(ir)
          indx(ir)=itemp
       ENDIF
       IF(arr(indx(l+1)).GT.arr(indx(l)))THEN
          itemp=indx(l+1)
          indx(l+1)=indx(l)
          indx(l)=itemp
       ENDIF
       i=l+1
       j=ir
       indxt=indx(l)
       a=arr(indxt)
3      continue
       i=i+1
       if(arr(indx(i)).lt.a)goto 3
4      continue
       j=j-1
       if(arr(indx(j)).gt.a)goto 4
       if(j.lt.i)goto 5
       itemp=indx(i)
       indx(i)=indx(j)
       indx(j)=itemp
       goto 3
5      indx(l)=indx(j)
       indx(j)=indxt
       jstack=jstack+2
       if(jstack.gt.NSTACK)pause 'NSTACK too small in indexx'
       if(ir-i+1.ge.j-l)then
          istack(jstack)=ir
          istack(jstack-1)=i
          ir=j-1
       else
          istack(jstack)=j-1
          istack(jstack-1)=l
          l=i
       endif
    endif
    goto 1
  END subroutine indexx_d

  SUBROUTINE rank(n,indx,irank)
    INTEGER n,indx(n),irank(n)
    INTEGER j
    DO j=1,n
       irank(indx(j))=j
    ENDDO
    RETURN
  END SUBROUTINE rank

END MODULE module_utils
