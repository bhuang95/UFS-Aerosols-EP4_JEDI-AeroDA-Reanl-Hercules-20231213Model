import datetime as dt
import netCDF4 as nc
import os, argparse, copy

'''
Command:
    python calc_ensmean_restart.py -t 1 -f 'fv_tracer.res.tile1.nc' -n 4 -v 'INVARS.nml'
'''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Calculate the ensemble mean of six-tile RESTART files'
        )
    )


    required = parser.add_argument_group(title='required arguments')

    required.add_argument(
        '-i', '--mstart',
        help="Starting number of member",
        type=int, required=True)

    required.add_argument(
        '-j', '--mend',
        help="Ending number of member",
        type=int, required=True)

    required.add_argument(
        '-v', '--variable',
        help="Input file containing the  variables",
        type=str, required=True)

    args = parser.parse_args()
    mst = args.mstart
    med = args.mend
    invarnml = args.variable

    cntlpre = "CNTL"
    emeanpre = "EMEAN"
    cmmpre = "CMM"
    jedienspre = "JEDITMP"
    rplenspre = "RPL"
    rceenspre = "RCE"

    with open(invarnml, 'r') as fd:
	    invars=fd.read().strip().split(',')

    print(invars)
	
    for j in range(1,7):
        tile=f'tile{j}'
        cntlname = f'{cntlpre}.{tile}'
        emeanname = f'{emeanpre}.{tile}'
        cmmname = f'{cmmpre}.{tile}'
        with nc.Dataset(cmmname,'a') as cmmfile:
            with nc.Dataset(cntlname,'r') as cntlfile:
                with nc.Dataset(emeanname,'r') as emeanfile:
                    for vname in invars:
                        cmmdata = cntlfile.variables[vname][:] - emeanfile.variables[vname][:] 
                        cmmfile.variables[vname][:] = cmmdata[:]

    for j in range(1,7):
        tile=f'tile{j}'
        cmmname = f'{cmmpre}.{tile}'
        with nc.Dataset(cmmname,'r') as cmmfile:
            for i in range(mst, med+1):
                mem=f'mem{i:03d}'
                print(f'{tile}-{mem}')
                jediensname = f'{jedienspre}.{mem}.{tile}'
                rplensname = f'{rplenspre}.{mem}.{tile}'
                rceensname = f'{rceenspre}.{mem}.{tile}'
                with nc.Dataset(jediensname,'r') as jediensfile:
                    with nc.Dataset(rplensname,'a') as rplensfile:
                        with nc.Dataset(rceensname,'a') as rceensfile:
                            for vname in invars:
                                jedidata = jediensfile.variables[vname][:]
                                cmmdata = cmmfile.variables[vname][:] 
                                rcedata = jedidata[:] + cmmdata[:]
                                rcedata[rcedata < 0.0] = 0.0
                                rplensfile.variables[vname][:] = jedidata[:]
                                rceensfile.variables[vname][:] = rcedata[:]
                                try:
                                    rplensfile.variables[vname].delncattr('checksum')  # remove the checksum so fv3 does not complain
                                except AttributeError:
                                    pass  # checksum is missing, move on
                                try:
                                    rceensfile.variables[vname].delncattr('checksum')  # remove the checksum so fv3 does not complain
                                except AttributeError:
                                    pass  # checksum is missing, move on
