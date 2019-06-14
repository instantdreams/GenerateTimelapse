# Security, Threat, and Risk Assessment
The PowerShell script uses Windows file system path and file item commands to identify a list of matching image files and uses ffmpeg to build a timelapse. It also uses ffpmeg to merge multiple videos together if more than one folder was used to create the image files for a time period. It will attempt to clean up the source and output folders, and uses Remove-Item to do so. There is minimal risk in using the script.

The configuration file contains information pertaining to your file system. It is excluded from the project using an entry in the project .gitignore file. Do not commit personal details to the project - instead, pull the sample file, rename, and add your personal configuration details.

The PowerShell script will optionally call a third party script, known as Powershell-YouTube-Upload, which will use a C# command line interface to attempt to upload any generated videos to your authorised YouTube account. Use of this script is at your own risk and subject to the security policy of the [Powershell-YouTube-Upload repository](https://github.com/JoJoBond/Powershell-YouTube-Upload).

# Disclosure Policy
Any security issues encountered with the script should be raised as an issue within this project. These issues will be triaged and resolved, and details of the resolution and release will be published via the issue.


# Security Update Policy
If an issue is encountered with this project, details of the severity and impact will be placed in the Known Issues section of this file.


# Security Configuration
No special configuration is required to apply security to this project.
For the upload capability, a `client_secrets.json` file has to be created from an authorised YouTube account.


# Known Issues
There are currently no issues with the project that require a security update.