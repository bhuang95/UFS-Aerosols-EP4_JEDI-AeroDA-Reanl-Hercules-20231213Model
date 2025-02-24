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

    jedienspre = "JEDITMP"
    rplenspre = "RPL"

    with open(invarnml, 'r') as fd:
	    invars=fd.read().strip().split(',')

    print(invars)

    for j in range(1,7):
        tile=f'tile{j}'
        for i in range(mst, med+1):
            mem=f'mem{i:03d}'
            print(f'{tile}-{mem}')
            jediensname = f'{jedienspre}.{mem}.{tile}'
            rplensname = f'{rplenspre}.{mem}.{tile}'
            with nc.Dataset(jediensname,'r') as jediensfile:
                with nc.Dataset(rplensname,'a') as rplensfile:
                        for vname in invars:
                            #jedidata = jediensfile.variables[vname][:]
                            rplensfile.variables[vname][:] = jediensfile.variables[vname][:]
                            try:
                                rplensfile.variables[vname].delncattr('checksum')  # remove the checksum so fv3 does not complain
                            except AttributeError:
                                pass  # checksum is missing, move on
