#!/usr/bin/env python
import os, argparse
import cdsapi

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Download EC CAMSEAC4 AOD reanalysis'
        )
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
    '-c', '--cycle',
    help="Cycle date in (YYYYMMDDTHH)",
    type=str, required=True)

    c = cdsapi.Client(url="https://ads.atmosphere.copernicus.eu/api/v2", key="8252:ed7cb229-e3e2-40d8-8fc6-2656806a3d29")

    args = parser.parse_args()
    cycle=args.cycle
    cyear=cycle[0:4]
    cmon=cycle[4:6]
    cday=cycle[6:8]
    chour=cycle[8:]

    cdate_ymd=f'{cyear}-{cmon}-{cday}'
    cdate_h=f'{chour}:00'
    outfile=f'camseac4-550nm-AOD-{cycle}.nc'
    c.retrieve(
        'cams-global-reanalysis-eac4',
        {
            'date': cdate_ymd,
	    'format': 'netcdf',
	    'variable': 'total_aerosol_optical_depth_550nm',
	    'time': [
    	    cdate_h
            ],
            #'grid': [
            #    '0.5/0.5',
            #]
        },
    outfile)
