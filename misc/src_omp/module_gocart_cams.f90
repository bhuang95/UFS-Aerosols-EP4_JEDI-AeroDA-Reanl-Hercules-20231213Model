MODULE module_gocart_cams

  IMPLICIT NONE

  INTEGER, PARAMETER :: &
       &ndust_bins_gocart=5,nseas_bins_gocart=5,&
       &ndust_bins_cams=3,nseas_bins_cams=3

  REAL, PARAMETER :: &
       &gocart2cams_dust(ndust_bins_gocart,ndust_bins_cams+1)=&
       &RESHAPE([&
       &0.3212834,0.5308169,0.1478998,1.0000000,&
       &0.0000000,0.0000000,1.0000000,1.0000000,&
       &0.0000000,0.0000000,1.0000000,1.0000000,&
       &0.0000000,0.0000000,1.0000000,1.0000000,&
       &0.0000000,0.0000000,1.0000000,1.0000000],&
       &SHAPE(gocart2cams_dust),order=[2,1])

  REAL, PARAMETER :: &
       &gocart2cams_seas(nseas_bins_gocart,nseas_bins_cams+1)=&
       &RESHAPE([&
       &1.0000000,0.0000000,0.000000,1.0000000,&
       &0.3804677,0.6195323,0.000000,1.0000000,&
       &0.0000000,1.0000000,0.000000,1.0000000,&
       &0.0000000,0.3015030,0.698497,1.0000000,&
       &0.0000000,0.0000000,1.000000,1.0000000],&
       &SHAPE(gocart2cams_seas),order=[2,1])

CONTAINS

  SUBROUTINE translate_fv3gocart2cams(varname_in,varname_out)

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
       varname_out="SO4"
    CASE("so4")       
       varname_out="SO4"
    CASE("dust1","dust2","dust3","dust4","dust5")
       varname_out="DUST"
    CASE("seas1","seas2","seas3","seas4","seas5")
       varname_out="SEAS"
    CASE("no3an1")       
       varname_out="NITRATE1"
    CASE("no3an2")       
       varname_out="NITRATE2"
    CASE("no3an3")       
       varname_out="NITRATE3"
    CASE default
       PRINT *, "variable not in gocart species list: ",TRIM(varname_in)
       STOP(10)
    END SELECT

  END SUBROUTINE translate_fv3gocart2cams

  SUBROUTINE translate_cams2fv3gocart(varname_in,varname_out)
    
    CHARACTER(len=*) :: varname_in,varname_out

    SELECT CASE (TRIM(varname_in))
    CASE("BCPHOBIC")
       varname_out="bc1"
    CASE("BCPHILIC")
       varname_out="bc2"
    CASE("OCPHOBIC")
       varname_out="oc1"
    CASE("OCPHILIC")       
       varname_out="oc2"
    CASE("SO4")       
       varname_out="sulf"
    CASE("DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL")
       varname_out="dust"
    CASE("SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL")
       varname_out="seas"
    CASE default
       PRINT *, "variable not in gocart species list: ",TRIM(varname_in)
       STOP(11)
    END SELECT

  END SUBROUTINE translate_cams2fv3gocart

  SUBROUTINE translate_aero_names(varname_in,varname_out)
    
    CHARACTER(len=*) :: varname_in,varname_out

    SELECT CASE (TRIM(varname_in))
    CASE("BCPHOBIC")
       varname_out="bc1"
    CASE("BCPHILIC")
       varname_out="bc2"
    CASE("OCPHOBIC")
       varname_out="oc1"
    CASE("OCPHILIC")       
       varname_out="oc2"
    CASE("SO4")       
       varname_out="so4"
    CASE("NITRATE1")       
       varname_out="no3an1"
    CASE("NITRATE2")       
       varname_out="no3an2"
    CASE("NITRATE3")       
       varname_out="no3an3"
    CASE("DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL")
       varname_out="dust"
    CASE("SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL")
       varname_out="seas"
    CASE default
       PRINT *, "variable not in gocart species list: ",TRIM(varname_in)
       STOP(11)
    END SELECT

  END SUBROUTINE translate_aero_names
    
  SUBROUTINE translate_m2gocart2cams(varname_in,varname_out)

    CHARACTER(len=*) :: varname_in,varname_out

    SELECT CASE (TRIM(varname_in))
    CASE("BCPHOBIC")
       varname_out="BCPHOBIC"
    CASE("BCPHILIC")
       varname_out="BCPHILIC"
    CASE("OCPHOBIC")
       varname_out="OCPHOBIC"
    CASE("OCPHILIC")       
       varname_out="OCPHILIC"
    CASE("SO4")       
       varname_out="SO4"
    CASE("DU001","DU002","DU003","DU004","DU005")
       varname_out="DUST"
    CASE("SS001","SS002","SS003","SS004","SS005")
       varname_out="SEAS"
    CASE default
       PRINT *, "variable not in gocart species list: ",TRIM(varname_in)
       STOP(10)
    END SELECT

  END SUBROUTINE translate_m2gocart2cams

  SUBROUTINE translate_cams2m2gocart(varname_in,varname_out)
    
    CHARACTER(len=*) :: varname_in,varname_out

    SELECT CASE (TRIM(varname_in))
    CASE("BCPHOBIC")
       varname_out="BCPHOBIC"
    CASE("BCPHILIC")
       varname_out="BCPHILIC"
    CASE("OCPHOBIC")
       varname_out="OCPHOBIC"
    CASE("OCPHILIC")       
       varname_out="OCPHILIC"
    CASE("SO4")       
       varname_out="SO4"
    CASE("DUSTFINE","DUSTMEDIUM","DUSTCOARSE","DUSTTOTAL")
       varname_out="DU"
    CASE("SEASFINE","SEASMEDIUM","SEASCOARSE","SEASTOTAL")
       varname_out="SS"
    CASE default
       PRINT *, "variable not in gocart species list: ",TRIM(varname_in)
       STOP(11)
    END SELECT

  END SUBROUTINE translate_cams2m2gocart

END MODULE module_gocart_cams
