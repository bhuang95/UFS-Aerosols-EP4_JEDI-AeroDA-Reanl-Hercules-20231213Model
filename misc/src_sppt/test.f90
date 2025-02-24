PROGRAM test
  
  REAL :: a(3),vmin,vmax

  a(1)=-1
  a(2)=0
  a(3)=1

  vmin=-1
  vmax=1

  PRINT *,'@@@1',MIN(a,vmin)
  PRINT *,'@@@1',MAX(a,vmin)
  PRINT *,'@@@2',MIN(a,vmax)
  PRINT *,'@@@2',MAX(a,vmax)


END PROGRAM test
  
