# GenerateTimelapse

A PowerShell script for users of [Netcam Studio](https://www.netcamstudio.com/), a Network Video Recorder / Video Management Service that has the ability to create timelapse videos and images.

This script is designed to create timelapse videos for all sources for a given day.


## Features

The Generate Timelapse PowerShell script uses a configuration file to allow easy management of your personal settings plus the names and details of your video sources.

The Generate Timelapse PowerShell script will:

* Identify the folders containing timelapse images
* Create a timelapse video for the previous day by default
* Merge timelapse videos together in the event of multiple folders being created
* Optionally upload the created videos to an authorised YouTube account
* Clean up the source image files, remove empty source image folders, and remove output videos older than a specified retention date
* Write results to a log file for analysis


## Prerequisites

To install the script on your system you will need the following information:

* A script location for your PowerShell scripts (e.g. "C:\Tools\Scripts" or "D:\ServerFolders\Company\Scripts")
* A folder for log files  (e.g. "C:\Tools\Scripts\Logs" or "D:\ServerFolders\Company\Scripts\Logs")
* A working install of [Netcam Studio ](https://www.netcamstudio.com/)
* Access to the [FFmpeg](https://ffmpeg.org/) utility (usually installed with Netcam Studio)
* (Optional) Installation of the [Powershell-YouTube-Upload](https://github.com/JoJoBond/Powershell-YouTube-Upload) repository


## Installation

A simple clone of the repository is all that is required:

* On the [GitHub page for this repository](https://github.com/instantdreams/GenerateTimelapse) select "Clone or Download" and copy the web URL
* Open your GIT Bash of choice and enter the following commands:
	* cd {base location of your scripts folder} (e.g. /d/ServerFolders/Company/Scripts)
	* git clone {repository url} (e.g. https://github.com/instantdreams/GenerateTimelapse.git)

This will install a copy of the scripts and files in the folder "GenerateTimelapse" under your script location.


## Configuration

Minor configuration is required before running the script:

* Open File Explorer and navigate to your script location
* Copy file "GenerateTimelapse-Sample.xml" and rename the result to "GenerateTimelapse.xml"
* Edit the file with your favourite text or xml editor
	* For JobFolder enter the full path to the script folder (e.g. "C:\Tools\Scripts\GenerateTimelapse")
	* For LogFolder enter the full path to the log folder (e.g. "C:\Tools\Scripts\Logs")
	* For Sources, enter the number, name, location, and description for each source (at least one is required)
	* The TimelapseFolder should match the location that Netcam Studio uses to write timelapse images
	* For OutFolder enter the full path to the output folder (e.g. "C:\Tools\Scripts\Output")
	* For VideoHandler enter the location to your installation of FFmpeg (e.g. "C:\Program Files\Netcam Studio - 64-bit\ffmpeg.exe")
	* For YouTubeUploadFolder and YouTubeUploadScript enter the location of your installation of the Powershell-YouTube-Upload repository
	* The retention days should be a negative number, which is used to calculate the number of days before the start date to remove files and folders
* Save the file and exit the editor


## Running

To run the script, open a PowerShell window and use the following commands:
```
Set-Location {script location}
.\GenerateTimelapse.ps1
```
For example, to generate timelapse videos for yesterday and upload the results to YouTuBe:
```
Set-Location "C:\Tools\Scripts\GenerateTimelapse"
.\GenerateTimelapse.ps1 -Upload
```
For exmaple, to generate timelapse videos for the 31st of May:
```
Set-Location "C:\Tools\Scripts\GenerateTimelapse"
.\GenerateTimelapse.ps1 -DateStart 2019-05-31
```


## Scheduling

This script was designed to run as a scheduled task to seamlessly create timelapse videos from many images. With Windows or Windows Server, the easiest way of doing this is to use Task Scheduler.

1. Start Task Scheduler
2. Select Task Scheduler Library
3. Right click and select Create Simple Task
4. Use the following entries:
* Name:			GenerateTimelapse
* Description:	Generate timelapse videos for all Netcam Video sources
* Account:		Use your script execution account
* Run whether user is logged on or not
* Trigger:		Daily at 01:00, enabled
* Action:		Start a program
	* Program:		PowerShell
	* Arguments:	-ExecutionPolicy Bypass -NoLogo -NonInteractive -File "{script location}\GenerateTimelapse\GenerateTimelapse.ps1" -Upload
	* Start in:	{script location}\GenerateTimelapse

Adjust the trigger as needed, and you will have refreshed playlists automatically.


## Troubleshooting

Please review the log files located in the log folder to determine any issues.


## Author

* **Dean W. Smith** - *Script Creation* - [instantdreams](https://github.com/instantdreams)


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details


## Security

This project has a security policy - see the [SECURITY.md](SECURITY.md) file for details