#!/usr/bin/env python3

# Description:
#        This code reads and (or) interpolates online AERONET AOD data at available
#        wavelenths (340/380/440/500/675/870/1020/1640 nm) and write into IODA format.
#
# Usage:
#        python aeronet_aod2ioda.py -t 2021080500 -w 6 -l 1 -q AOD15 -o aeronet_aod.nc
#        -t: time of AERONET AOD data in YYYYMMDDHH format
#        -w: time wihdow in hours within which AERONET AOD will be collected
#            (e.g., [time-window/2, time+window/2])
#        -l: Option for lunar AOD (=1, otherwise, =0)
#        -q: AOD QC level (e.g., AOD15, AOD20)
#        -o: output file name.
#
# Contact:
#        Bo Huang (bo.huang@noaa.gov) from CU/CIRES and NOAA/ESRL/GSL
#
# Acknowledgement:
#        Barry Baker from ARL for his initial preparation for this code.
#
# Additional notes:
#        An example of interpolating AOD at other wavelengths (e.g., 550) is illustrated
#        by defining "aod_new_wav" which is assigned to "interp_to_aod_values" in add_data
#        function.
#        (1) A tension spline function is applied for the interpolation to avoid
#            overshoots and the interpolation is based on log(wavelength).
#        (2) For the purpose of testing the interpolation capability, interpolated AOD
#            at 550 nm is calculated and only saved in outcols (as aod_int_550nm) and f3
#            variables, but not written out in the output IODA file. If desired too write
#            out interpolated AOD value, please define/modify aod_new_chan, frequency_new,
#            outcols, obsvars variables.
#        (3) Since current hofx utility for AERONET AOD only includes 1-8 channels
#            that correspond to eight available wavelengths, it may not work for additional
#            interpolated AOD (e.g., 550nm) hofx calculation.

#import time
import netCDF4 as nc
import numpy as np
import inspect, sys, os, argparse
import pandas as pd
from datetime import datetime, timedelta
from builtins import object, str
from pathlib import Path

#sys.path.append('/home/Bo.Huang/JEDI-2020/miscScripts-home/JEDI-Support/aeronetScript/readAeronet/lib-python/')
#sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/ioda-bundle/ioda-bundle-20230809/build/lib/')
#sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/ioda-bundle/ioda-bundle-20230809/build/lib/python3.9/')
#sys.path.append('/scratch1/BMC/gsd-fv3-dev/MAPP_2018/bhuang/JEDI-2020/JEDI-FV3/expCodes/ioda-bundle/ioda-bundle-20230809/build/iodaconv/src/')
#import pytspack as pts

import pyiodaconv.ioda_conv_engines as iconv
from collections import defaultdict, OrderedDict
from pyiodaconv.orddicts import DefaultOrderedDict

def dateparse(x):
    return datetime.strptime(x, '%d:%m:%Y %H:%M:%S')


def add_data(dates=None,
             product='AOD15',
             lunar_merge=1,
             latlonbox=None,
             daily=False,
             interp_to_aod_values=None,
             inv_type=None,
             freq=None,
             siteid=None,
             n_procs=1, verbose=10):
    a = AERONET()
    df = a.add_data(dates=dates,
                    product=product,
                    lunar_merge=lunar_merge,
                    latlonbox=latlonbox,
                    daily=daily,
                    interp_to_aod_values=interp_to_aod_values,
                    inv_type=inv_type,
                    siteid=siteid,
                    freq=freq)
    return df.reset_index(drop=True)


class AERONET(object):
    def __init__(self):
        from numpy import concatenate, arange
        self.baseurl = 'https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_v3?'
        self.dates = [
            datetime.strptime('2016-06-06 12:00:00', '%Y-%m-%d %H:%M:%S'),
            datetime.strptime('2016-06-10 13:00:00', '%Y-%m-%d %H:%M:%S')
        ]
        self.datestr = []
        self.df = pd.DataFrame()
        self.daily = None
        self.prod = None
        self.lunar_merge = None
        self.inv_type = None
        self.siteid = None
        self.objtype = 'AERONET'
        self.usecols = concatenate((arange(30), arange(65, 83)))
        self.latlonbox = None
        self.url = None
        self.new_aod_values = None

    def build_url(self):
        sy = self.dates.min().strftime('%Y')
        sm = self.dates.min().strftime('%m').zfill(2)
        sd = self.dates.min().strftime('%d').zfill(2)
        sh = self.dates.min().strftime('%H').zfill(2)
        ey = self.dates.max().strftime('%Y').zfill(2)
        em = self.dates.max().strftime('%m').zfill(2)
        ed = self.dates.max().strftime('%d').zfill(2)
        eh = self.dates.max().strftime('%H').zfill(2)
        if self.prod in [
                'AOD10', 'AOD15', 'AOD20', 'SDA10', 'SDA15', 'SDA20', 'TOT10',
                'TOT15', 'TOT20'
        ]:
            base_url = 'https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_v3?'
            inv_type = None
        else:
            base_url = 'https://aeronet.gsfc.nasa.gov/cgi-bin/print_web_data_inv_v3?'
            if self.inv_type == 'ALM15':
                inv_type = '&ALM15=1'
            else:
                inv_type = '&AML20=1'
        date_portion = 'year=' + sy + '&month=' + sm + '&day=' + sd + \
            '&hour=' + sh + '&year2=' + ey + '&month2=' + em + '&day2=' + ed +\
            '&hour2=' + eh
        if self.inv_type is not None:
            product = '&product=' + self.prod
        else:
            product = '&' + self.prod + '=1'
            self.inv_type = ''

        if self.lunar_merge == 1:
            lunar_merge = '&lunar_merge=1'
        elif self.lunar_merge == 0:
            lunar_merge = '&lunar_merge=0'
        else:
            lunar_merge = ''

        time = '&AVG=' + str(self.daily)
        if self.siteid is not None:
            latlonbox = '&site={}'.format(self.siteid)
        elif self.latlonbox is None:
            latlonbox = ''
        else:
            lat1 = str(float(self.latlonbox[0]))
            lon1 = str(float(self.latlonbox[1]))
            lat2 = str(float(self.latlonbox[2]))
            lon2 = str(float(self.latlonbox[3]))
            latlonbox = '&lat1=' + lat1 + '&lat2=' + \
                lat2 + '&lon1=' + lon1 + '&lon2=' + lon2
        print(base_url)
        print(date_portion)
        print(product)
        print(lunar_merge)
        print(inv_type)
        print(time)
        print(latlonbox)
        if inv_type is None:
            inv_type = ''
        self.url = base_url + date_portion + product + \
            inv_type + time + lunar_merge + latlonbox + '&if_no_html=1'
        print(self.url)

    def read_aeronet(self):
        print('Reading Aeronet Data...')
        df = pd.read_csv(self.url,
                         engine='python',
                         header=None,
                         skiprows=6,
                         parse_dates={'time': [1, 2]},
                         date_parser=dateparse,
                         na_values=-999)

        columns = self.get_columns()
        df.columns = columns
        df.index = df.time
        df.rename(columns={
            'site_latitude(degrees)': 'latitude',
            'site_longitude(degrees)': 'longitude',
            'site_elevation(m)': 'elevation',
            'aeronet_site': 'siteid'
        },
            inplace=True)
        df.dropna(subset=['latitude', 'longitude'], inplace=True)
        df.dropna(axis=1, how='all', inplace=True)
        self.df = df
        print('Done with reading')

    def get_columns(self):
        header = pd.read_csv(self.url, skiprows=5, header=None,
                             nrows=1).values.flatten()
        final = ['time']
        for i in header:
            if "Date(" in i or 'Time(' in i:
                pass
            else:
                final.append(i.lower())
        return final

    def add_data(self,
                 dates=None,
                 product='AOD15',
                 lunar_merge=1,
                 latlonbox=None,
                 daily=False,
                 interp_to_aod_values=None,
                 inv_type=None,
                 freq=None,
                 siteid=None):
        self.latlonbox = latlonbox
        self.siteid = siteid
        if dates is None:  # get the current day
            self.dates = pd.date_range(start=pd.to_datetime('today'),
                                       end=pd.to_datetime('now'),
                                       freq='H')
        else:
            self.dates = dates
        self.prod = product.upper()
        self.lunar_merge = lunar_merge
        if daily:
            self.daily = 20  # daily data
        else:
            self.daily = 10  # all points
        if inv_type is not None:
            self.inv_type = 'ALM15'
        else:
            self.inv_type = inv_type
        if 'AOD' in self.prod:
            self.new_aod_values = interp_to_aod_values
        self.build_url()
        try:
            self.read_aeronet()
        except Exception:
            print(self.url)
        nlocs, columns = self.df.shape
        if nlocs == 0:
            print('No avaiable AERONET AOD and exit')
            exit(-1)
        if freq is not None:
            self.df = self.df.groupby('siteid').resample(
                freq).mean().reset_index()
        if self.new_aod_values is not None:
            self.calc_new_aod_values()
        return self.df

    def calc_new_aod_values(self):

        def _tspack_aod_interp(row, new_wv=[440., 470., 550., 670., 870., 1240.]):
            try:
                import pytspack
            except ImportError:
                print('You must install pytspack before using this function')
            #aod_columns = [aod_column for aod_column in row.index if 'aod_' in aod_column]
            if self.lunar_merge == 0:
                aod_columns = ['aod_340nm', 'aod_380nm', 'aod_440nm', 'aod_500nm', 'aod_675nm', 'aod_870nm', 'aod_1020nm', 'aod_1640nm']
            elif self.lunar_merge == 1:
                aod_columns = ['aod_440nm', 'aod_500nm', 'aod_675nm', 'aod_870nm', 'aod_1020nm','aod_1640nm']
            else:
                print('lunar_merge is not defined and exit.')
                exit(100)
            aod_columns_nu = ['aod_440nm', 'aod_500nm', 'aod_675nm', 'aod_870nm']
            aods_nu = row[aod_columns_nu]
            aods_all = row[aod_columns]
            nu_true = (aods_nu.isnull().values.any()) 
            if not nu_true:
                aods = row[aod_columns]
                wv = [np.float32(aod_column.replace('aod_', '').replace('nm', '')) for aod_column in aod_columns]
                a = pd.DataFrame({'aod': aods}).reset_index()
                # Interpolate AOD based on log(wv)
                #wv_log = np.log(wv, dtype='float64')
                #new_wv_log = np.log(new_wv, dtype='float64')
                #a['wv'] = wv_log
                a['wv'] = wv
                df_aod_nu = a.dropna()
                df_aod_nu.aod.values[:] = np.where(df_aod_nu.aod.values[:] <= np.float32(0.0), np.nan, df_aod_nu.aod.values[:])
                df_aod_nu_sorted = df_aod_nu.sort_values(by='wv').dropna()
                x, y, yp, sigma = pytspack.tspsi(np.log(np.float32(df_aod_nu_sorted.wv.values)), np.log(np.float32(df_aod_nu_sorted.aod.values)))
                yi = pytspack.hval(np.log(np.float32(new_wv)), x, y, yp, sigma)
                return np.float32(np.exp(yi))
            else:
                return new_wv * np.nan

        out = self.df.apply(_tspack_aod_interp, axis=1, result_type='expand', new_wv=self.new_aod_values)
        names = 'aod_intp_' + pd.Series(self.new_aod_values.astype(int).astype(str)) + 'nm'
        out.columns = names.values
        self.df = pd.concat([self.df, out], axis=1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=(
            'Reads online AERONET data from NASA website '
            ' and converts into IODA formatted output files')
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
        '-t', '--time',
        help="time (YYYYMMDDTHH) of AERONET AOD files to be downloaded from NASA website",
        type=str, required=True)
    required.add_argument(
        '-w', '--window',
        help="An integer number in hour defines a time window [time-window/2, time+window/2] for AERONET AOD",
        type=float, required=True)
    required.add_argument(
        '-o', '--output',
        help="path of AERONET AOD IODA file",
        type=str, required=True)
    required.add_argument(
        '-l', '--lunar',
        help="Lunar AOD (=1, otherwise, = 0)",
        type=int, required=True)
    required.add_argument(
        '-q', '--aodqa',
        help="AOD quality (AOD15 or AOD20)",
        type=str, required=True)
    required.add_argument(
        '-p', '--intp550',
        help="Interp 550 nm AOD (=1, otherwise, = 0)",
        type=int, required=True)

    args = parser.parse_args()
    date_center1 = args.time
    hwindow1 = args.window
    outfile = args.output
    lunar=args.lunar
    aodqa=args.aodqa
    intpaod=args.intp550

    date_center = datetime.strptime(date_center1, '%Y%m%d%H')
    do_filter = False
    hwindow = hwindow1
    if hwindow % 2 == 1:
        do_filter = True
        filter_hwindow = hwindow/2.0
        filter_start_time = date_center + timedelta(hours=-1.*filter_hwindow)
        filter_end_time = date_center + timedelta(hours=filter_hwindow)
        hwindow += 1
    hwindow = hwindow/2.0
    date_start = date_center + timedelta(hours=-1.*hwindow)
    date_end = date_center + timedelta(hours=hwindow)

    print('Download AERONET AOD within +/- ' + str(hwindow) + ' hours at: ')
    print(date_center)

    dates = pd.date_range(start=date_start, end=date_end, freq='H')

    # Define AOD wavelengths, channels and frequencies
    if lunar == 1:
        aod_wav = np.array([440., 500., 675, 870., 1020., 1640.], dtype=np.float32)
        aod_chan = np.array([3, 4, 5, 6, 7, 8], dtype=np.intc)
    else:
        aod_wav = np.array([340., 380., 440., 500., 675, 870., 1020., 1640.], dtype=np.float32)
        aod_chan = np.array([1, 2, 3, 4, 5, 6, 7, 8], dtype=np.intc)

    # An example of interpolating AOD at 550 nm
    if intpaod == 1:
        aod_new_wav = np.array([550.], dtype=np.float32)
        aod_new_chan = np.array([9], dtype=np.intc)
        aod_wav = np.concatenate([aod_wav, aod_new_wav])
        aod_chan = np.concatenate([aod_chan, aod_new_chan])
    else:
        aod_new_wav = None
        aod_new_chan = None
    speed_light = 2.99792458E8
    frequency = speed_light*1.0E9/aod_wav
    aod_wav_m=aod_wav*1.0E-3
    print('Extract AERONET AOD at wavelengths/channels/frequencies: ')
    print(aod_wav)
    print(aod_chan)
    print(frequency)

    if lunar == 1:
        if intpaod == 1:
            outcols = ['time', 'siteid', 'longitude', 'latitude', 'elevation',
                       'aod_440nm', 'aod_500nm', 'aod_675nm',
                       'aod_870nm', 'aod_1020nm', 'aod_1640nm', 'aod_intp_550nm']
            obsvars = {'aerosolOpticalDepth': ['aod_440nm', 'aod_500nm',
                                               'aod_675nm', 'aod_870nm',
                                               'aod_1020nm', 'aod_1640nm', 'aod_intp_550nm']}
        else:
            outcols = ['time', 'siteid', 'longitude', 'latitude', 'elevation',
                       'aod_440nm', 'aod_500nm', 'aod_675nm',
                       'aod_870nm', 'aod_1020nm', 'aod_1640nm']
            obsvars = {'aerosolOpticalDepth': ['aod_440nm', 'aod_500nm',
                                               'aod_675nm', 'aod_870nm',
                                               'aod_1020nm', 'aod_1640nm']}
    else:
        if intpaod == 1: 
            outcols = ['time', 'siteid', 'longitude', 'latitude', 'elevation',
                       'aod_340nm', 'aod_380nm', 'aod_440nm', 'aod_500nm', 'aod_675nm',
                       'aod_870nm', 'aod_1020nm', 'aod_1640nm', 'aod_intp_550nm']
            obsvars = {'aerosolOpticalDepth': ['aod_340nm', 'aod_380nm',
                                               'aod_440nm', 'aod_500nm',
                                               'aod_675nm', 'aod_870nm',
                                               'aod_1020nm', 'aod_1640nm', 'aod_intp_550nm']}
        else:
            outcols = ['time', 'siteid', 'longitude', 'latitude', 'elevation',
                       'aod_340nm', 'aod_380nm', 'aod_440nm', 'aod_500nm', 'aod_675nm',
                       'aod_870nm', 'aod_1020nm', 'aod_1640nm']
            obsvars = {'aerosolOpticalDepth': ['aod_340nm', 'aod_380nm',
                                               'aod_440nm', 'aod_500nm',
                                               'aod_675nm', 'aod_870nm',
                                               'aod_1020nm', 'aod_1640nm']}

    f3_tmp = add_data(dates=dates, product=aodqa, lunar_merge=lunar, interp_to_aod_values=aod_new_wav)
    if do_filter:
       mask = (filter_start_time <= f3_tmp['time']) & ( f3_tmp['time'] < filter_end_time)
       f3 = f3_tmp[mask]
       f3 = f3.reset_index(drop=True)
    else:
       f3 = f3_tmp

    # Define AOD varname that match with those in f3 (match aod_wav and aod_chan)
    nlocs, columns = f3.shape
    if nlocs == 0:
        print('No avaiable AERONET AOD at ' + date_center1 + '  and exit')
        exit(-1)

    locationKeyList = [("latitude", "float"), ("longitude", "float"), ("dateTime", "string")]
    varDict = defaultdict(lambda: defaultdict(dict))
    outdata = defaultdict(lambda: DefaultOrderedDict(OrderedDict))
    varAttrs = DefaultOrderedDict(lambda: DefaultOrderedDict(OrderedDict))

    # A dictionary of global attributes.  More filled in further down.
    AttrData = {}
    AttrData['ioda_object_type'] = aodqa
    AttrData['sensor'] = 'aeronet'
    if lunar == 1:
        AttrData['lunar_aod'] = 'YES'
    else:
        AttrData['lunar_aod'] = 'NO'

    AttrData['center_datetime'] = date_center.strftime('%Y-%m-%dT%H:%M:%SZ')
    AttrData['window_in_hour'] = str(hwindow1)

    # A dictionary of variable dimensions.
    DimDict = {}

    # A dictionary of variable names and their dimensions.
    VarDims = {
        'aerosolOpticalDepth': ["Location", "Channel"],
        'sensorCentralFrequency': ['Channel'],
        'sensorCentralWavelength': ['Channel'],
        'sensorChannelNumber': ['Channel']
    }

    # Get the group names we use the most.
    metaDataName = iconv.MetaDataName()
    obsValName = iconv.OvalName()
    obsErrName = iconv.OerrName()
    qcName = iconv.OqcName()

    # Define varDict variables
    print('Define varDict variables')
    for key, value in obsvars.items():
        print(key, value)
        varDict[key]['valKey'] = key, obsValName
        varDict[key]['errKey'] = key, obsErrName
        varDict[key]['qcKey'] = key, qcName
        varAttrs[key, obsValName]['coordinates'] = 'longitude latitude stationElevation'
        varAttrs[key, obsErrName]['coordinates'] = 'longitude latitude stationElevation'
        varAttrs[key, qcName]['coordinates'] = 'longitude latitude stationElevation'
        varAttrs[key, obsValName]['_FillValue'] = -9999.
        varAttrs[key, obsErrName]['_FillValue'] = -9999.
        varAttrs[key, qcName]['_FillValue'] = -9999
        varAttrs[key, obsValName]['units'] = '1'
        varAttrs[key, obsErrName]['units'] = '1'

    for key, value in obsvars.items():
        outdata[varDict[key]['valKey']] = np.array(np.float32(f3[value].fillna(np.float32(-9999.))))
        outdata[varDict[key]['qcKey']] = np.where(outdata[varDict[key]['valKey']] == np.float32(-9999.),
                                                    1, 0)
        outdata[varDict[key]['errKey']] = np.where(outdata[varDict[key]['valKey']] == np.float32(-9999.),
                                                   np.float32(-9999.), np.float32(0.02))
    
    if intpaod == 1:
        if lunar == 1:
            outdata[varDict['aerosolOpticalDepth']['errKey']][:,5]=outdata[varDict['aerosolOpticalDepth']['errKey']][:,1]
            outdata[varDict['aerosolOpticalDepth']['qcKey']][:,5]=np.where(outdata[varDict['aerosolOpticalDepth']['valKey']][:,5] == np.float32(-9999.), 
                                                                              1, outdata[varDict['aerosolOpticalDepth']['qcKey']][:,1])
        else:
            outdata[varDict['aerosolOpticalDepth']['errKey']][:,8]=outdata[varDict['aerosolOpticalDepth']['errKey']][:,3]
            outdata[varDict['aerosolOpticalDepth']['qcKey']][:,8]=np.where(outdata[varDict['aerosolOpticalDepth']['valKey']][:,8] == np.float32(-9999.), 
                                                                              1, outdata[varDict['aerosolOpticalDepth']['qcKey']][:,3])

    # Add metadata variables
    outdata[('latitude', metaDataName)] = np.array(np.float32(f3['latitude']))
    outdata[('longitude', metaDataName)] = np.array(np.float32(f3['longitude']))
    outdata[('stationElevation', metaDataName)] = np.array(np.float32(f3['elevation']))
    varAttrs[('stationElevation', metaDataName)]['units'] = 'm'

    c = np.empty([nlocs], dtype=object)
    c[:] = np.array(f3.siteid)
    outdata[('stationIdentification', metaDataName)] = c

    # Define datetime
    d = np.empty([nlocs], dtype=object)
    for i in range(nlocs):
        d[i] = f3.time[i].strftime('%Y-%m-%dT%H:%M:%SZ')
    outdata[('dateTime', metaDataName)] = d

    outdata[('sensorCentralFrequency', metaDataName)] = np.float32(frequency)
    varAttrs[('sensorCentralFrequency', metaDataName)]['units'] = 'Hz'
    outdata[('sensorCentralWavelength', metaDataName)] = np.float32(aod_wav_m)
    varAttrs[('sensorCentralWavelength', metaDataName)]['units'] = 'microns'
    outdata[('sensorChannelNumber', metaDataName)] = np.int32(aod_chan)

    # Add global atrributes
    DimDict['Location'] = nlocs
    DimDict['Channel'] = aod_chan

    # Setup the IODA writer
    writer = iconv.IodaWriter(outfile, locationKeyList, DimDict)

    # Write out IODA NC files
    writer.BuildIoda(outdata, VarDims, varAttrs, AttrData)

    #f3.to_csv('f3.txt') #, sep=' ', na_rep='NaN', index=False, columns=outcols)
