import datetime as dt
import netCDF4 as nc
import os, argparse

'''
Command:
    python calc_ensmean_restart.py -f 'fv_tracer.res.tile1.nc' -n 4 -v 'INVARS.nml'
'''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Calculate the ensemble mean of six-tile RESTART files'
        )
    )


    required = parser.add_argument_group(title='required arguments')

    required.add_argument(
        '-f', '--tfile',
        help="Input fv3 tracer or core file",
        type=str, required=True)

    required.add_argument(
        '-n', '--enssize',
        help="Ensemble size",
        type=float, required=True)

    required.add_argument(
        '-v', '--variable',
        help="Input file containing the  variables",
        type=str, required=True)

    args = parser.parse_args()
    tfile = args.tfile
    nens = args.enssize
    invarnml = args.variable

    with open(invarnml, 'r') as fd:
	    invars=fd.read().strip().split(',')
    print(invars)
	
    fmean = f'ensmean.{tfile}'
    with nc.Dataset(fmean,'a') as meanfile:
        for i in range(1, int(nens)+1):
            mem=f'mem{i:03d}'
            fmem = f'{mem}.{tfile}'
            print(fmem)
            with nc.Dataset(fmem,'r') as memfile:
                for vname in invars:
                    mdata = meanfile.variables[vname][:]
                    edata = memfile.variables[vname][:]
                    if i == 1:
                        mdata = edata/nens
                    else:
                        mdata += edata/nens
                    meanfile.variables[vname][:] = mdata[:]
#                    try:
#                        meanfile.variables[vname].delncattr('checksum')  # remove the checksum so fv3 does not complain
#                    except AttributeError:
#                        pass  # checksum is missing, move on
