#!/usr/bin/env python3
# read/interpolate online aeronet AOD data and convert to netcdf
import netCDF4 as nc
import numpy as np
import inspect, sys, os, argparse
import pandas as pd
from datetime import datetime, timedelta
from builtins import object, str
from numpy import NaN
from pathlib import Path
from urllib.request import urlretrieve

import pyiodaconv.ioda_conv_engines as iconv
from collections import defaultdict, OrderedDict
from pyiodaconv.orddicts import DefaultOrderedDict

def dateparse(x):
    return datetime.strptime(x, '%d:%m:%Y %H:%M:%S')

def add_data(dates=None,
             product=None,
             latlonbox=None,
             daily=False,
             interp_to_aod_values=None,
             inv_type=None,
             freq=None,
             siteid=None,
             detect_dust=False, n_procs=1, verbose=10):
    a = AERONET()
    df = a.add_data(dates=dates,
                    product=product,
                    latlonbox=latlonbox,
                    daily=daily,
                    interp_to_aod_values=interp_to_aod_values,
                    inv_type=inv_type,
                    siteid=siteid,
                    freq=freq,
                    detect_dust=detect_dust)
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
                inv_type = '&ALM20=1'
        date_portion = 'year=' + sy + '&month=' + sm + '&day=' + sd + \
            '&hour=' + sh + '&year2=' + ey + '&month2=' + em + '&day2=' + ed +\
            '&hour2=' + eh
        if self.inv_type is not None:
            product = '&product=' + self.prod
        else:
            product = '&' + self.prod + '=1'
            self.inv_type = ''
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
        print(inv_type)
        print(time)
        print(latlonbox)
        if inv_type is None:
            inv_type = ''
        self.url = base_url + date_portion + product + \
            inv_type + time + latlonbox + '&if_no_html=1'
        #self.urlfile = product + '.txt'
        #print(self.url)
        #urlretrieve(self.url, self.urlfile)

    def read_aeronet(self):
        print('Reading Aeronet Data...')
        df = pd.read_csv(self.url,
                         engine='python',
                         header=None,
                         skiprows=7,
			 parse_dates={'time': [1, 2]},
                         date_parser=dateparse,
                         na_values=-999)
        columns = self.get_columns()
        df.columns = columns
        df.index = df.time
        df.rename(columns={
            'latitude(degrees)': 'latitude',
            'longitude(degrees)': 'longitude',
            'elevation(m)': 'elevation',
            'aeronet_site': 'siteid'
        },
            inplace=True)
        #df.dropna(subset=['latitude', 'longitude'], inplace=True)
        #df.dropna(axis=1, how='all', inplace=True)
        self.df = df

    def get_columns(self):
        header = pd.read_csv(self.url, skiprows=6, header=None,
                             nrows=1).values.flatten()
        final = ['time']
        for i in header:
            if "Date(" in i or 'Time(' in i:
                if "Last_Processing_Date(" in i or "Last_Processing_Time(" in i:
                    final.append(i.lower())
                else:
                    pass
            else:
                final.append(i.lower())
        return final

    def add_data(self,
                 dates=None,
                 product=None,
                 latlonbox=None,
                 daily=False,
                 interp_to_aod_values=None,
                 inv_type=None,
                 freq=None,
                 siteid=None,
                 detect_dust=False):
        self.latlonbox = latlonbox
        self.siteid = siteid
        if dates is None:  # get the current day
            self.dates = pd.date_range(start=pd.to_datetime('today'),
                                       end=pd.to_datetime('now'),
                                       freq='H')
        else:
            self.dates = dates
        self.prod = product.upper()
        if daily:
            self.daily = 20  # daily data
        else:
            self.daily = 10  # all points
        #if inv_type is not None:
        #    self.inv_type = 'ALM15'
        #else:
        self.inv_type = inv_type
        self.build_url()
        try:
            self.read_aeronet()
            print(self.url)
        except:
            print(self.url)
        if freq is not None:
            self.df = self.df.groupby('siteid').resample(
                freq).mean().reset_index()
        return self.df


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
	     description=(
		          'Reads online AERONET inversion data from NASA website '
			  ' and converts into IODA formatted output files')
    )

    required = parser.add_argument_group(title='required arguments')
    required.add_argument(
		    '-l', '--almqa',
		    help="AERONET inversion data levels ('ALM15 or ALM20') to be downloaded from NASA website",
		    type=str, required=True)
    required.add_argument(
		    '-t', '--time',
		    help="time (YYYYMMDDTHH) of AERONET inversion data files to be downloaded from NASA website",
		    type=str, required=True)
    required.add_argument(
		    '-w', '--window',
		    help="An integer/float number defines a time window centered at time argument in hours within which AERONET inversion data will be downloaded",
		    type=float, required=True)
    required.add_argument(
		    '-o', '--output',
		    help="path of AERONET inversion data IODA file",
		    type=str, required=True)

    args = parser.parse_args()
    aeronetlev = args.almqa
    date_center1 = args.time
    outfile = args.output
    hwindow1=args.window

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

    print('Download AERONET inversion data within +/- ' + str(hwindow) + ' hours at: ')
    print(date_center)

    dates = pd.date_range(start=date_start,end=date_end,freq='H')

    # Define wavelengths, channels and frequencies of AERONET inversion data
    aeronetinv_wav = np.array([440., 675, 870., 1020.], dtype=np.float32)
    aeronetinv_chan = np.array([3, 5, 6, 7], dtype=np.intc)
    speed_light = 2.99792458E8
    frequency = speed_light*1.0E9/aeronetinv_wav
    aeronetinv_wav_m = aeronetinv_wav*1.0E-3
    print('Calculate AERONET inverion data at wavelengths/channels/frequencies: ')
    print(aeronetinv_wav)
    print(aeronetinv_chan)
    print(frequency)

    # Read and extract online AERONET inversion data
    print('Read and extract online AERONET inversion data: AOD, SST, TAB, CAD')
    f3_aod_all_tmp = add_data(dates=dates, product='AOD', inv_type=aeronetlev)
    f3_ssa_all_tmp = add_data(dates=dates, product='SSA', inv_type=aeronetlev)
    f3_tab_all_tmp = add_data(dates=dates, product='TAB', inv_type=aeronetlev)
    f3_cad_all_tmp = add_data(dates=dates, product='CAD', inv_type=aeronetlev)
    if do_filter:
        mask = (filter_start_time <= f3_aod_all_tmp['time']) & ( f3_aod_all_tmp['time'] < filter_end_time)
        f3_aod_all = f3_aod_all_tmp[mask]
        f3_ssa_all = f3_ssa_all_tmp[mask]
        f3_tab_all = f3_tab_all_tmp[mask]
        f3_cad_all = f3_cad_all_tmp[mask]
        f3_aod_all = f3_aod_all.reset_index(drop=True)
        f3_ssa_all = f3_ssa_all.reset_index(drop=True)
        f3_tab_all = f3_tab_all.reset_index(drop=True)
        f3_cad_all = f3_cad_all.reset_index(drop=True)
    else:
        f3_aod_all = f3_aod_all_tmp
        f3_ssa_all = f3_ssa_all_tmp
        f3_tab_all = f3_tab_all_tmp
        f3_cad_all = f3_cad_all_tmp

    f3_aod=f3_aod_all[['time', 'siteid', 'longitude', 'latitude', 'elevation',
                       'if_retrieval_is_l2(without_l2_0.4_aod_440_threshold)', 'if_aod_is_l2', 'inversion_data_quality_level']]
    f3_ssa=f3_ssa_all[['time', 'siteid', 'longitude', 'latitude', 'elevation',
                       'if_retrieval_is_l2(without_l2_0.4_aod_440_threshold)', 'if_aod_is_l2', 'inversion_data_quality_level',
		      'single_scattering_albedo[440nm]','single_scattering_albedo[675nm]','single_scattering_albedo[870nm]','single_scattering_albedo[1020nm]']]
    f3_tab=f3_tab_all[['time', 'siteid', 'longitude', 'latitude', 'elevation',
                       'if_retrieval_is_l2(without_l2_0.4_aod_440_threshold)', 'if_aod_is_l2', 'inversion_data_quality_level',
                      'absorption_aod[440nm]', 'absorption_aod[675nm]', 'absorption_aod[870nm]', 'absorption_aod[1020nm]']]
    f3_cad=f3_cad_all[['time', 'siteid', 'longitude', 'latitude', 'elevation',
                       'if_retrieval_is_l2(without_l2_0.4_aod_440_threshold)', 'if_aod_is_l2', 'inversion_data_quality_level',
                      'aod_coincident_input[440nm]', 'aod_coincident_input[675nm]','aod_coincident_input[870nm]','aod_coincident_input[1020nm]']]
    f3=pd.concat([f3_aod, 
    	         f3_ssa[['single_scattering_albedo[440nm]','single_scattering_albedo[675nm]',
    			 'single_scattering_albedo[870nm]','single_scattering_albedo[1020nm]']],
    		 f3_tab[['absorption_aod[440nm]', 'absorption_aod[675nm]', 
    			'absorption_aod[870nm]', 'absorption_aod[1020nm]']], 
    		 f3_cad[['aod_coincident_input[440nm]', 'aod_coincident_input[675nm]',
    			'aod_coincident_input[870nm]','aod_coincident_input[1020nm]']]],axis=1, join='inner')
    # Write data into ASCII txt file for sanity check. 
    #cols=['time', 'siteid', 'longitude', 'latitude', 'elevation', 'if_retrieval_is_l2(without_l2_0.4_aod_440_threshold)', 'if_aod_is_l2', 'inversion_data_quality_level']
    #f3.to_csv('df_f3_all.txt', sep=' ', index=False)
    # Define AO D varname that match with those in f3
    nlocs, columns = f3.shape
    nchans = len(aeronetinv_chan)
    if nlocs==0:
        print('No avaiable AERONET inversion data at ' + date_center1 + '  and exit')
        exit(0)

    locationKeyList = [("latitude", "float"), ("longitude", "float"), ("datetime", "string")] 
    varDict = defaultdict(lambda: defaultdict(dict))
    outdata = defaultdict(lambda: DefaultOrderedDict(OrderedDict))
    varAttrs = DefaultOrderedDict(lambda: DefaultOrderedDict(OrderedDict))

    #obsvars = {'aerosol_optical_depth': ['aod_coincident_input[440nm]', 'aod_coincident_input[675nm]',
    #                                    'aod_coincident_input[870nm]', 'aod_coincident_input[1020nm]'],
    #           'absorption_aerosol_optical_depth': ['absorption_aod[440nm]', 'absorption_aod[675nm]',
    #                                                'absorption_aod[870nm]', 'absorption_aod[1020nm]'],
    #           'single_scattering_albedo': ['single_scattering_albedo[440nm]','single_scattering_albedo[675nm]',
    #                                        'single_scattering_albedo[870nm]', 'single_scattering_albedo[1020nm]']}

    obsvars = {'aerosolOpticalDepth': ['aod_coincident_input[440nm]', 'aod_coincident_input[675nm]',
                                        'aod_coincident_input[870nm]', 'aod_coincident_input[1020nm]'],
               'absorptionAerosolOpticalDepth': ['absorption_aod[440nm]', 'absorption_aod[675nm]',
                                                    'absorption_aod[870nm]', 'absorption_aod[1020nm]'],
               'singleScatteringAlbedo': ['single_scattering_albedo[440nm]','single_scattering_albedo[675nm]',
                                            'single_scattering_albedo[870nm]', 'single_scattering_albedo[1020nm]']}

    # A dictionary of global attributes.  More filled in further down.
    AttrData = {}
    AttrData['ioda_object_type'] = aeronetlev
    AttrData['sensor'] = 'aeronet'
    AttrData['center_datetime'] = date_center.strftime('%Y-%m-%dT%H:%M:%SZ')
    AttrData['window_in_hour'] = str(hwindow1)
    #AttrData['nlocs'] = np.int32(DimDict['nlocs'])
    #AttrData['nchans'] = np.int32(nchans)
    #AttrData['observation_type'] = 'AeronetInversion'
    #AttrData['sensor'] = 'aeronet'
    #AttrData['surface_type'] = 'ocean=0,land=1,costal=2'

    # A dictionary of variable dimensions. 
    DimDict = {}

    VarDims = {
        'aerosolOpticalDepth': ['Location', 'Channel'],
        'absorptionAerosolOpticalDepth': ['Location', 'Channel'],
        'singleScatteringAlbedo': ['Location', 'Channel'],
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
        outdata[varDict[key]['qcKey']] = np.where(outdata[varDict[key]['valKey']] == np.float32(-9999.), 1, 0)
        if key in ["aerosolOpticalDepth"]:
            outdata[varDict[key]['errKey']] = np.where(outdata[varDict[key]['valKey']] == np.float32(-9999.),
                                                       np.float32(-9999.), np.float32(0.02))
        else:
            outdata[varDict[key]['errKey']] = np.full((nlocs, nchans), np.float32(-9999.))

    outdata[('latitude', metaDataName)] = np.array(np.float32(f3['latitude']))
    outdata[('longitude', metaDataName)] = np.array(np.float32(f3['longitude']))
    outdata[('stationElevation', metaDataName)] = np.array(np.float32(f3['elevation']))
    varAttrs[('stationElevation', metaDataName)]['units'] = 'm'
    #outdata[('surface_type', 'MetaData')] = np.full((nlocs), 1)
    #varAttrs[('surface_type', 'MetaData')]['units'] = ''

    # Whether aaod and SSA reaches Level 2.0 without the threshold of aod440 >= 0.4 (0: yes, 1: no)
    #outdata[('aaod_ssa_l20_qc_without_l20_aod440_0.4_threshold', metaDataName)] = np.where(f3['if_retrieval_is_l2(without_l2_0.4_aod_440_threshold)'] == 1, 0, 1)
    outdata[('aaod_ssa_l20_qc_without_l20_aod440_0.4_threshold', metaDataName)] = np.where(f3['if_retrieval_is_l2(without_l2_0.4_aod_440_threshold)'] == 1, np.int32(0), np.int32(1))
    varAttrs[('aaod_ssa_l20_qc_without_l20_aod440_0.4_threshold', metaDataName)]['units'] = ''

    # Whether Coincident_AOD440nm in aeronet_cad.txt reaches Level 2.0 (0: yes, 1: no)
    #outdata[('aod_l20_qc', metaDataName)] = np.where(f3['if_aod_is_l2'] == 1, 0, 1)
    outdata[('aod_l20_qc', metaDataName)] = np.where(f3['if_aod_is_l2'] == 1, np.int32(0), np.int32(1))
    varAttrs[('aod_l20_qc', metaDataName)]['units'] = ''

    # aaod and ssa inversion type: 0 for ALM20 and 1 for ALM15
    #outdata[('aaod_ssa_l20_qc', metaDataName)] = np.where(f3['inversion_data_quality_level'] == 'lev20', 0, 1)
    outdata[('aaod_ssa_l20_qc', metaDataName)] = np.where(f3['inversion_data_quality_level'] == 'lev20', np.int32(0), np.int32(1))
    varAttrs[('aaod_ssa_l20_qc', metaDataName)]['units'] = ''

    c = np.empty([nlocs], dtype=object)
    c[:] = np.array(f3.siteid)
    outdata[('stationIdentification', metaDataName)] = c
    #varAttrs[('station_id', 'MetaData')]['units'] = ''

    d = np.empty([nlocs], dtype=object)
    for i in range(nlocs):
        d[i] = f3.time[i].strftime('%Y-%m-%dT%H:%M:%SZ')
    outdata[('dateTime', metaDataName)] = d
    #varAttrs[('datetime', 'MetaData')]['units'] = ''

    outdata[('sensorCentralFrequency', metaDataName)] = np.float32(frequency)
    varAttrs[('sensorCentralFrequency', metaDataName)]['units'] = 'Hz'
    outdata[('sensorCentralWavelength', metaDataName)] = np.float32(aeronetinv_wav_m)
    varAttrs[('sensorCentralWavelength', metaDataName)]['units'] = 'microns'
    outdata[('sensorChannelNumber', metaDataName)] = np.int32(aeronetinv_chan)
    #varAttrs[('sensor_channel', metaDataName)]['units'] = 'unitless'

    # Add global atrributes
    DimDict['Location'] = np.int32(nlocs)
    DimDict['Channel'] = np.int32(aeronetinv_chan)

    # Setup the IODA writer
    writer = iconv.IodaWriter(outfile, locationKeyList, DimDict)

    # Write out IODA NC files
    writer.BuildIoda(outdata, VarDims, varAttrs, AttrData)
