MODULE module_gocart_reanalysis

  IMPLICIT NONE

CONTAINS

  SUBROUTINE translate_fv3gocart2reanalysis(varname_in,varname_out)

    CHARACTER(len=*) :: varname_in,varname_out

    SELECT CASE (TRIM(varname_in))
    CASE("bc1")
       varname_out="BCPHOBIC"
    CASE("bc2")
       varname_out="BCPHILIC"
    CASE("oc1")
       varname_out="OCPHOBIC"
    CASE("oc2")       
       varname_out="OCPHILIC"
    CASE("sulf")       
       varname_out="SULFATE"
    CASE("so4")       
       varname_out="SULFATE"
    CASE("dust1")
       varname_out="DUST_BIN_1"
    CASE("dust2")
       varname_out="DUST_BIN_2"
    CASE("dust3")
       varname_out="DUST_BIN_3"
    CASE("dust4")
       varname_out="DUST_BIN_4"
    CASE("dust5")
       varname_out="DUST_BIN_5"
    CASE("seas1")
       varname_out="SEAS_BIN_1"
    CASE("seas2")
       varname_out="SEAS_BIN_2"
    CASE("seas3")
       varname_out="SEAS_BIN_3"
    CASE("seas4")
       varname_out="SEAS_BIN_4"
    CASE("seas5")
       varname_out="SEAS_BIN_5"
    CASE("T")
       varname_out="T"
    CASE("sphum")
       varname_out="SPHUM"
    CASE default
       PRINT *, "variable not in reanalysis list: ",TRIM(varname_in)
       STOP(10)
    END SELECT

  END SUBROUTINE translate_fv3gocart2reanalysis
  
  END MODULE module_gocart_reanalysis
