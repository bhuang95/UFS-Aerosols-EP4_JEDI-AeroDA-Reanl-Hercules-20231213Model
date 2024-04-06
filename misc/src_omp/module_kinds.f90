MODULE module_kinds

  USE, INTRINSIC :: iso_c_binding

  IMPLICIT NONE

  INTEGER, parameter :: kind_single = c_float
  INTEGER, parameter :: kind_float = kind_single
  INTEGER, parameter :: kind_real   = c_double
  INTEGER, parameter :: kind_quad   = c_long_double

  INTEGER, parameter :: kind_int    = c_int
  INTEGER, parameter :: kind_long   = c_long

  INTEGER, PARAMETER :: SINGLE=kind_single,DOUBLE=c_double
  INTEGER, PARAMETER :: r_single=SINGLE,r_kind=DOUBLE

END MODULE module_kinds
