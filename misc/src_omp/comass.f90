PROGRAM comass
  
  IMPLICIT NONE
  
  REAL, PARAMETER :: r_earth = 6378.e3,pi = ACOS(-1.0),&
       &cototalmass=400.e9

  REAL :: co_column
  
  co_column=cototalmass/(4.*pi*r_earth**2)

  PRINT *,co_column
  
END PROGRAM comass

