import datetime as dt
import netCDF4 as nc
import numpy as np
import os, argparse, copy

'''
Command:
    python -a sfcanl -b sfc -n 6
'''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Calculate the ensemble mean of six-tile RESTART files'
        )
    )


    required = parser.add_argument_group(title='required arguments')

    required.add_argument(
        '-a', '--sfcanl',
        help=" sfcanl_data file",
        type=str, required=True)

    required.add_argument(
        '-b', '--sfc',
        help="sfc_data file",
        type=str, required=True)

    required.add_argument(
        '-i', '--mst',
        help="starting number of sfc_data files",
        type=int, required=True)

    required.add_argument(
        '-j', '--med',
        help="end number of sfc_data files",
        type=int, required=True)

    args = parser.parse_args()
    sfcanl = args.sfcanl
    sfc = args.sfc
    mst = args.mst
    med = args.med
    ntiles = 6

    for i in range(mst, med+1):
        mem=f'mem{i:03d}'
        for j in range(1,ntiles+1):
            tile=f'tile{j}'
            sfcin = f'{sfc}.{mem}.{tile}'
            sfcanlin = f'{sfcanl}.{mem}.{tile}'
            print(f'{mem}.{tile}')
            with nc.Dataset(sfcin,'a') as sfcfile:
                sfcvars = sfcfile.variables.keys()
                with nc.Dataset(sfcanlin,'r') as sfcanlfile:
                    sfcanlvars = sfcanlfile.variables.keys()
                    comvars = set(sfcvars).intersection(sfcanlvars)   #list(set(list(sfcvars)) & set(list(sfcanlvars)))
                    for comvar in comvars:
                        sfc_dims=sfcfile.variables[comvar].shape
                        sfcanl_dims=sfcanlfile.variables[comvar].shape
                        if (len(sfc_dims)) > 1 and (sfc_dims == sfcanl_dims):
                            #print(comvar)
                            rplarr = sfcanlfile.variables[comvar][:]
                            if not np.isnan(rplarr).any():
                                sfcfile.variables[comvar][:] = sfcanlfile.variables[comvar][:]
                                try:
                                    sfcfile.variables[comvar].delncattr('checksum')  # remove the checksum so fv3 does not complain
                                except AttributeError:
                                    pass  # checksum is missing, move on
