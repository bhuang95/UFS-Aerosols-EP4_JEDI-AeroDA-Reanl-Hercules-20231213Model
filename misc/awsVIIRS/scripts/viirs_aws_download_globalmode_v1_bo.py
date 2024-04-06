# -*- coding: utf-8 -*-
"""
SCRIPT TO DOWNLOAD VIIRS L2 DATA FROM NOAA ARCHIVE ON AWS
(GLOBAL DATA DOWNLOAD OVER RANGE OF OBSERVATION DATES)
@author: Dr. Amy Huff (amy.huff@noaa.gov)

Version 1 (v1) created on Dec 15 2021; tested in Python v3.8 and 3.9

VIIRS data available on AWS:
SNPP reprocessed data, 2012-2020

This script will access NOAA's JPSS VIIRS level 2 data archve on AWS and
download all of the files (global coverage) for each day over a range of 
days entered by the user. This script is intended for "power users" who
want global data coverage over a given observation period.

Be advised that there are ~550 VIIRS level 2 data files for each day, and 
individual files can be as large as 100-150 MB!

**installation of "s3fs" package is required to run the script***

Instructions: Run the script. You will be asked to enter the start and 
end dates for the observation range (range of days to download files),
and to enter the name of the directory where downloaded files will be
saved. If there are no errors in any of the entered information, the 
script will proceed to download VIIRS files to the specified directory.
If you need to stop the download while it is in progress, press the 
"control" and "c" keys.

"""
# Module to interface with AWS Simple Storage Service (S3)
import s3fs

# Module to set filesystem paths appropriate for user's operating system
from pathlib import Path

# Module for manipulating dates and times
import datetime

# Library to create progress bars for loops/functions
from tqdm import tqdm

# Module for accessing system-specific parameters and functions
import sys


# Create list of VIIRS data file names for specified observation dates
# Note: only SNPP VIIRS reprocessed data currently available on AWS
# Script will be updated when NOAA-20, operational files are available
def aws_viirs_list(start, end):
    
    # Access AWS using anonymous credentials
    aws = s3fs.S3FileSystem(anon=True)
    
    # Create list of dates encompassing beginning and end of specified period
    data = []
    date_generated = [start + datetime.timedelta(days=x) for x in range(0, (end-start).days + 1)]
    for date in date_generated:
        file_date = date.strftime('%Y%m%d')
        year = file_date[:4]
        month = file_date[4:6]
        day = file_date[6:]
        # Create list of file names for entire day (~550)
        #HBO#day_files = aws.ls('noaa-jpss/SNPP/VIIRS/SNPP_Aerosol_Optical_Depth_Reprocessed/' + year + '/' + month + '/' + day + '/', refresh=True)
        #day_files = aws.ls('noaa-jpss/SNPP/VIIRS/SNPP_VIIRS_Aerosol_Detection_EDR_Reprocessed/' + year + '/' + month + '/' + day + '/', refresh=True)
        day_files = aws.ls('noaa-jpss/SNPP/VIIRS/SNPP_VIIRS_Aerosol_Optical_Depth_EDR_Reprocessed/' + year + '/' + month + '/' + day + '/', refresh=True)
        # Add file names for entire day to overall list
        data.extend(day_files)
          
    return data


# Check user-entered directory for errors
def check_directory(directory_path_name):
    try:
        # Note: in Python 3.9, "exists.()" returns False for paths w/syntax 
        # errors instead of raising an exception
        Path(directory_path_name).exists()
        if Path(directory_path_name).exists() == False:
            error_message = 1  # Directory doesn't exist on user's computer
        elif len(directory_path_name) < 1:
            error_message = 2  # User forgot to enter a directory name
        else:
            error_message = 0
    except:
            error_message = 3  # Syntax error in entered directory name

    return error_message


# Check user-entered observation start/end dates for errors
def check_dates_range(start_date, end_date):
    
    date_errors = 0
    # Check format of start date
    if len(start_date) == 8:
        try:
            start = datetime.date(int(start_date[:4]), int(start_date[4:6]), int(start_date[6:]))
        except:
            print('\nIncorrect format for START date: must be "YYYYMMDD". Try again.')
            start = None
            date_errors += 1
    else:
        print('\nMissing digits in START date: must be "YYYYMMDD". Try again.') 
        start = None
        date_errors += 1
        
    # Check format of end date
    if len(end_date) == 8:
        try:
            end = datetime.date(int(end_date[:4]), int(end_date[4:6]), int(end_date[6:]))
        except:
            print('\nIncorrect format for END date: must be "YYYYMMDD". Try again.')
            end = None
            date_errors += 1
    else:
        print('\nMissing digits in END date: must be "YYYYMMDD". Try again.')
        end = None
        date_errors += 1
    
    # If "start" and "end" date formats are valid, check for errors
    if start != None and end != None:
        # Check if end date is earlier than start date
        if end < start:
            print('\nThe entered end date is earlier than the start date. Try again.')
            date_errors += 1
        # Check if end date is in the future
        today = datetime.date.today()
        if end > today:
            print('\nThe entered end date that is in the future.  Try again.')
            date_errors += 1
    
    return date_errors, start, end


# Loop to download data files
def download_files(data, save_path):
    
    # User can press "control + c" buttons to stop download
    print('\nTo stop download prior to completion, press "CTRL+C"\n')
    
    # Access AWS using anonymous credentials
    aws = s3fs.S3FileSystem(anon=True)
    
    # Download files to specified directory
    # Display download progress bar using tqdm library
    # Flush buffer prior to tqdm to avoid glich in Python < v3.9
    sys.stdout.flush()
    try:
        for file in tqdm(data, total=len(data), unit='files', 
                         bar_format="{desc}Downloading:{percentage:3.0f}%|{bar}|{n_fmt}/{total_fmt}[{elapsed}<{remaining}]"):
            # Set save_path + file_name as pathlib.Path object and convert to string
            full_path = str(save_path / file.split('/')[-1])
            # Download file from AWS archive
            aws.get(file, full_path)
        print('\nDownload complete!')
    except KeyboardInterrupt:
        print('\nDownload was interrupted by user.')


# Interface for user to download files
def get_files(save_path, start, end):
    
    # Create list of files on AWS matching user-entered info
    data = aws_viirs_list(start, end)
    
    if len(data) > 0:
        # Print directory where files will be saved & number of files
        print('\nA total of ' + str(len(data)) + ' data files will be saved to: ' + str(save_path))
        #ask_download = input('Would you like to download the files?\nType "yes" or "no" and hit "Enter"\n')
        ask_download = 'yes'
        if ask_download in ['yes', 'YES', 'Yes', 'y', 'Y']:
            download_files(data, save_path)
        else:
            print('\nFiles are not being downloaded.')
    else:
        print('\nNo files are available for entered date range.')
    
    
# Main function
if __name__ == '__main__':     

    # Check if user has required package(s) installed
    import pkg_resources
    package_list = ['s3fs']
    missing_packages = []
    for package in package_list:
        try:
            pkg_resources.get_distribution(package).version
        except:
            missing_packages.append(package)
    
    # If required package(s) missing, notify user & terminate script
    if len(missing_packages) > 0:
        print('The following required packages are not installed:')
        for x in missing_packages:
            print(x) 
        print('\nThe indicated package(s) must be installed in order to run the script.')
    else:
        # Ask user to enter start and end dates for time period of observations
        # Note: "input()" returns a string
        #start_date = input("Enter 8-digit START date for data in YYYYMMDD format: \n")
        start_date= sys.argv[1]  #"20171101"
        #end_date = input("Enter 8-digit END date for data in YYYYMMDD format: \n")
        end_date= sys.argv[2] #"20171103"
    
        # Check user-entered observation start/end dates for errors
        # If errors exist, warning message will print & script terminates
        date_errors, start, end = check_dates_range(start_date, end_date)
        
        # If no errors in observation start/end dates, then proceed to
        # have user enter directory to save downloaded files
        if date_errors == 0:
        
            # Ask user to enter name of directory to save downloaded files
            # Note: "input()" returns a string
            #user_save_path = input("Enter name of directory to save downloaded files (e.g., D://Data/):\n")
            user_save_path = sys.argv[3] #"/work/noaa/gsd-fv3-dev/bhuang/JEDI-FV3/expRuns/MISC/VIIRS-AWS/data"
        
            # Check user-entered directory name for errors
            # If no errors found, set directory name as pathlib.Path object
            save_path_error_message = check_directory(user_save_path)
            if save_path_error_message == 0:
                save_path = Path(user_save_path)
            else:
                save_path = 'error'
            
            # If errors exist in directory name, print warning message (script terminates)
            if save_path == 'error':
                if save_path_error_message == 1:
                    print('The directory entered to save files does not exist. Try again.')
                elif save_path_error_message == 2:
                    print('The field for the directory to save files is blank. Try again.')
                elif save_path_error_message == 3:
                    print('There is a syntax error in the the directory name to save files. Try again.')
            else:
                # If no errors found in user-entered info, then proceed to
                # download files for specified date range
                get_files(save_path, start, end)
