## ---- [Script Parameters] ----
Param
(
    [Parameter(Mandatory=$False,HelpMessage="DateStart Format: yyyy-mm-dd")] [datetime] $DateStart,
    [Parameter(Mandatory=$False,HelpMessage="DateEnd Format: yyyy-mm-dd")] [datetime] $DateEnd,
    [Parameter(Mandatory=$False)] [Switch] $Upload
)


# Function Launch-Process - capture and display output from Start-Process
function Launch-Process
{
    <#
    .SYNOPSIS
        Pass parameters to StartProcess and capture the output
    .DESCRIPTION
        Use temporary files to capture output and errors
    .EXAMPLE
        Launch-Process -Process $ProcessHandler -Arguments $ProcessArguments
    .OUTPUTS
        Log file, process started
    .NOTES
        Version:        1.0
        Author:         Dean Smith | deanwsmith@outlook.com
        Creation Date:  2019-09-18
        Purpose/Change: Initial script creation
    #>
    ## ---- [Function Parameters] ----
    [CmdletBinding()]
    Param([string]$ProcessHandler,[string[]]$ProcessArguments)

    ## ---- [Function Beginning] ----
    Begin {}

    ## ---- [Function Execution] ----
    Process
    {
        Try
        {
            $StdOutTempFile = "$env:TEMP\$((New-Guid).Guid)"
            $StdErrTempFile = "$env:TEMP\$((New-Guid).Guid)"
            $Process = Start-Process -FilePath $ProcessHandler -ArgumentList $ProcessArguments -NoNewWindow -PassThru -Wait -RedirectStandardOutput $StdOutTempFile -RedirectStandardError $StdErrTempFile
            $ProcessOutput = Get-Content -Path $StdOutTempFile -Raw
            $ProcessError  = Get-Content -Path $StdErrTempFile -Raw
            If ($Process.ExitCode -ne 0)
            {
                If ($ProcessError)  { Throw $ProcessError.Trim()  }
                If ($ProcessOutput) { Throw $ProcessOutput.Trim() }
            }
            Else
            {
                If ([string]::IsNullOrEmpty($ProcessOutput) -eq $false) { Write-Output -InputObject $ProcessOutput }
            }
        }
        Catch   { $PSCmdlet.ThrowTerminatingError($_) }
        Finally { Remove-Item -Path $stdOutTempFile, $stdErrTempFile -Force -ErrorAction Ignore }
    }

    ## ---- [Function End] ----
    End {}
}    


# Function Identify-Timelapse - find the source folders
function Identify-Timelapse
{
    <#
    .SYNOPSIS
        Locate the timelapse folders
    .DESCRIPTION
        Identify the most recent timelapse folders for each source.
        For each folder, create appropriate parameters and call Create-Timelapse.
    .EXAMPLE
        Identify-Timelapse
    .OUTPUTS
        List of folders
    .NOTES
        Version:        1.0
        Author:         Dean Smith | deanwsmith@outlook.com
        Creation Date:  2019-05-20
        Purpose/Change: Initial script creation
        Version:        1.1
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-14
        Purpose/Change: Merged scripts to use functions
    #>
    ## ---- [Function Parameters] ----
    [CmdletBinding()]
    Param()

    ## ---- [Function Beginning] ----
    Begin {}

    ## ---- [Function Execution] ----
    Process
    {
        # Get a collection of timelapse folders sorted by date
        $TimelapseFolders = Get-ChildItem -Path $TimelapseFolder -Directory | 
            Sort-Object CreationTime |
            Select-Object -ExpandProperty FullName
        $TimeStamp = Get-Date -uformat "%T"
        Write-Output ("`r`n$TimeStamp`t${JobName}`tIdentify-Timelapse`nFolders:`t" + $TimelapseFolders.Count)

        # Create a collection of folders that match the regular expressions for each source
        $TimeStamp = Get-Date -uformat "%T"
        $LogMessage = "`r`n$TimeStamp`t${JobName}`tIdentify-Timelapse"
        ForEach ($Source in $Sources)
        {
            $Source.TimelapseFolders = $TimelapseFolders | Select-String -Pattern $Source.FolderFilter -AllMatches
            $LogMessage = $LogMessage + "`nSource " + $Source.Number + ":`t" + $Source.TimelapseFolders.Count + " Folders"
        }
        Write-Output ($LogMessage)

        # Loop through the list of folders for each source, create the arguments, and pass them to Create-Timelapse
        ForEach ($Source in $Sources)
        {
            $TimeStamp = Get-Date -uformat "%T"
            Write-Output ("`r`n$TimeStamp`t${JobName}`tIdentify-Timelapse`nSource " + $Source.Number + ":`tProcessing Started")
            $Count = 0
            ForEach ($Folder in $Source.TimelapseFolders)
            {
                $TimelapseFilename = $OutputFolder + "\Timelapse " + $Source.Name + " " + $DateStartDisplay + " " + $Count + ".mp4"
                $TimeStamp = Get-Date -uformat "%T"
                Write-Output ("`r`n$TimeStamp`t${JobName}`tIdentify-Timelapse`nIn Folder:`t$Folder`nOut File:`t$TimelapseFilename")
                Create-Timelapse -InputFolder $Folder -OutputFilename $TimelapseFilename
                $Count = $Count + 1
            }
            $TimeStamp = Get-Date -uformat "%T"
            Write-Output ("`r`n$TimeStamp`t${JobName}`tIdentify-Timelapse`nSource " + $Source.Number + ":`tProcessing Ended")
        }
    }

    ## ---- [Function End] ----
    End {}
}


# Function Create-Timelapse - Make a video
function Create-Timelapse
{
    <#
    .SYNOPSIS
         Create a timelapse video
    .DESCRIPTION
        Using a set of images across a date range create a timelapse video
    .PARAMETER InputFolder
        Folder containing timelapse images
    .PARAMETER OutputFilename
        Name of video file to create
    .EXAMPLE
        Create-Timelapse -InputFolder "D:\Security\Timelapse\[folder]" -OutputFilename "D:\Scripts\Output\[filename.mp4]"
    .OUTPUTS
        Video in mp4 format
    .NOTES
        Version:        1.0
        Author:         Dean Smith | deanwsmith@outlook.com
        Creation Date:  2019-05-20
        Purpose/Change: Initial script creation
        Version:        1.1
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-14
        Purpose/Change: Merged scripts to use functions
    #>
    ## ---- [Function Parameters] ----
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)] [string] $InputFolder,
        [Parameter(Mandatory=$True)] [string] $OutputFilename
    )

    ## ---- [Function Beginning] ----
    Begin
    {
        # Manage the input details - identify the current folder and build the path
        $InputPath = $InputFolder + "\*.*"
        $TimeStamp = Get-Date -uformat "%T"
        Write-Output ("`r`n$TimeStamp`t${JobName}`tCreate-Timelapse`nIn Folder:`t$InputFolder`nIn Path:`t$InputPath`nOut Folder:`t$OutputFolder`nOut File:`t$OutputFilename")
    }

    ## ---- [Function Execution] ----
    Process
    {
        # Identify a list of the files between yesterday and today
        $ImageFiles = Get-ChildItem -Path $InputPath -Recurse -Filter *.jpg | 
            Where-Object { $_.LastWriteTime -gt $DateStartSystem -and $_.LastWriteTime -lt $DateEndSystem } | 
            Select-Object FullName
        $TimeStamp = Get-Date -uformat "%T"
        Write-Output ("`r`n$TimeStamp`t${JobName}`tCreate-Timelapse`nImages:`t`t" + $ImageFiles.Count)

        # Only generate the video if there are images available
        If ($ImageFiles.Count -gt 0)
        {
            # Get the counter values for the first and last entries, then calculate the difference to get the frames
            $FirstEntry = $ImageFiles | Select-Object -first 1
            If ($FirstEntry -match $ImageFilter) { $FirstCounter = $Matches[4] }
            $LastEntry = $ImageFiles | Select-Object -last 1
            If ($LastEntry -match $ImageFilter) { $LastCounter = $Matches[4] }
            $TimelapseFrames = $LastCounter - $FirstCounter + 1
            $TimeStamp = Get-Date -uformat "%T"
            Write-Output ("`r`n$TimeStamp`t${JobName}`tCreate-Timelapse`nFirst:`t`t$FirstCounter`nLast:`t`t$LastCounter`nFrames:`t`t$TimelapseFrames")

            # Create the filename used for substitution within ffmpeg
            $InputMask = $FirstEntry.FullName -replace $ImageFilter,'$1_$2_$3_%06d'

            # Set up arguments for FFmpeg
            $CreateArguments = "-y -start_number $FirstCounter -i `"$InputMask`" -frames $TimelapseFrames -s 1920x1080 -vcodec libx264 `"$OutputFilename`""
            $TimeStamp = Get-Date -uformat "%T"
            Write-Output ("`r`n$TimeStamp`t${JobName}`nLocation:`t$VideoHandler`nFilename:`t$OutputFilename`nArguments:`t$CreateArguments")

            ## Call FFmpeg to create timelapse
            Launch-Process -ProcessHandler $VideoHandler -ProcessArguments $CreateArguments
            $TimeStamp = Get-Date -uformat "%T"
            Write-Output ("`r`n$TimeStamp`t${JobName}`tCreate-Timelapse`nStatus:`t`tImage file generated")
        }
        Else
        {
            $TimeStamp = Get-Date -uformat "%T"
            Write-Output ("`r`n$TimeStamp`t${JobName}`tCreate-Timelapse`nStatus:`t`tNo images found - no video file generated")
        }
    }

    ## ---- [Function End] ----
    End {}
}


# Function Merge-Timelapse - if multiple videos were created for a source, merge them together
function Merge-Timelapse
{
    <#
    .SYNOPSIS
        Merge videos together
    .DESCRIPTION
        In the output folder, identify videos by created date order.
        If multiple videos are found for a particular source, concatenate them.
        If one video is found, rename it.
        If no videos are found, log this fact.
    .EXAMPLE
        Merge-Timelapse
    .OUTPUTS
        Merged or renamed video in mp4 format
    .NOTES
        Version:        1.0
        Author:         Dean Smith | deanwsmith@outlook.com
        Creation Date:  2019-05-31
        Purpose/Change: Initial script creation
        Version:        1.1
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-14
        Purpose/Change: Merged scripts to use functions
        Version:        1.2
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-18
        Purpose/Change: Adjusted GCI to use LastWriteTime to make sure videos are merged in order
    #>
    ## ---- [Function Parameters] ----
    [CmdletBinding()]
    Param()

    ## ---- [Function Beginning] ----
    Begin {}

    ## ---- [Function Execution] ----
    Process
    {
        # Retrieve a list of all files in the Output Folder - using ExpandProperty to get the full path
        $OutputVideos = Get-ChildItem -Path $OutputFolder | 
            Sort-Object -Property LastWriteTime |
            Select-Object -ExpandProperty FullName
        $TimeStamp = Get-Date -uformat "%T"
        Write-Output ("`r`n$TimeStamp`t${JobName}`tMerge-Timelapse`nFiles:`t`t" + $OutputVideos.Count + " video files in output folder")

        # Create a collection of filenames that match the regular expressions
        $LogMessage = "`r`n$TimeStamp`t${JobName}`tMerge-Timelapse"
        ForEach ($Source in $Sources)
        {
            $Source.MergeVideos = $OutputVideos | Select-String -Pattern $Source.MergeFilter -AllMatches
            If ($Source.MergeVideos.Count -gt 0)
            { $Source.FinalFilename = $Source.MergeVideos[0] -replace $Source.MergeFilter,'$1$3$4$6' }
            Else
            { $Source.FinalFilename = "No videos available to merge" }
            $LogMessage = $LogMessage + "`nSource " + $Source.Number + ":`t" + $Source.MergeVideos.Count + "`t`tFinal Filename:`t" + $Source.FinalFilename
        }
        $TimeStamp = Get-Date -uformat "%T"
        Write-Output ($LogMessage)

        # Loop through the list of videos for each source to either merge, rename, or freak out
        ForEach ($Source in $Sources)
        {
            # More than one video to process - build a merge file
            If ($Source.MergeVideos.Count -gt 1)
            {
                # Create a merge file to hold the details of all the videos to be merged
                $OutputMergeFile = $JobFolder + "\Source" + $Source.Number + "Merge.txt"
                If (Test-Path $OutputMergeFile) { Remove-Item -Path $OutputMergeFile }
                New-Item -Path $OutputMergeFile -ItemType "file" | Out-Null

                # Add the videos to be merged to the merge file
                ForEach ($MergeVideo in $Source.MergeVideos)
                {
                    $MergeName = "file '" + $MergeVideo + "'"
                    Add-Content -Path $OutputMergeFile -Value $MergeName
                }

                # Set up arguments for FFmpeg
                $MergeArguments = "-f concat -safe 0 -i `"" + $OutputMergeFile + "`" -c copy `"" + $Source.FinalFilename + "`""
                $TimeStamp = Get-Date -uformat "%T"
                Write-Output ("`r`n$TimeStamp`t${JobName}`tMerge-Timelapse`nLocation:`t$VideoHandler`nFilename:`t" + $Source.FinalFilename + "`nArguments:`t$MergeArguments")

                # Call FFmpeg to merge timelapse videos
                If (Test-Path $Source.FinalFilename) { Remove-Item $Source.FinalFilename }
                Launch-Process -ProcessHandler $VideoHandler -ProcessArguments $MergeArguments

                # Remove individual files if new file created successfully
                If (Test-Path $Source.FinalFilename)
                {
                    ForEach ($MergeVideo in $Source.MergeVideos)
                    {
                        Remove-Item -Path $MergeVideo
                    }
                    If (Test-Path $OutputMergeFile) { Remove-Item -Path $OutputMergeFile }
                }
                $TimeStamp = Get-Date -uformat "%T"
                Write-Output ("`r`n$TimeStamp`t${JobName}`tMerge-Timelapse`nMerged:`t`t" + $Source.FinalFilename)
            }
            # Just one video to process - rename the file
            ElseIf ($Source.MergeVideos.Count -eq 1)
            {
                Rename-Item -Path $Source.MergeVideos[0] -NewName $Source.FinalFilename
                $TimeStamp = Get-Date -uformat "%T"
                Write-Output ("`r`n$TimeStamp`t${JobName}`tMerge-Timelapse`nRenamed To:`t" + $Source.FinalFilename)
            }
            # No videos to process - log this fact
            ElseIf ($Source.MergeVideos.Count -eq 0)
            {
                $TimeStamp = Get-Date -uformat "%T"
                Write-Output ("`r`n$TimeStamp`t${JobName}`tMerge-Timelapse`nStatus:`t`tNo videos present for Source " + $Source.Number)
            }
        }
    }

    ## ---- [Function End] ----
    End{}
}


# Function Upload-Timelapse - use a third party tool to upload the videos
function Upload-Timelapse
{
    <#
    .SYNOPSIS
        Upload generated timelapse videos to YouTube
    .DESCRIPTION
        If a video is found for a particular source, upload it.
    .EXAMPLE
        Upload-Timelapse
    .OUTPUTS
        Video uploaded to YouTube
    .NOTES
        Version:        1.0
        Author:         Dean Smith | deanwsmith@outlook.com
        Creation Date:  2019-05-31
        Purpose/Change: Initial script creation
        Version:        1.1
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-14
        Purpose/Change: Merged scripts to use functions
        Version:        1.2
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-18
        Purpose/Change: Adjusted Remove-Module name to be "YouTube"
        Version:        1.3
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-27
        Purpose/Change: Added logic to determine if upload was successful
    #>
    ## ---- [Function Parameters] ----
    [CmdletBinding()]
    Param()

    ## ---- [Function Beginning] ----
    Begin
    {
        # Jump to the module folder and load the YouTube script
        Push-Location $YouTubeUploadFolder
        Import-Module $YouTubeUploadScript
    }

    ## ---- [Function Execution] ----
    Process
    {
        # Loop through the list of filenames for each source to upload
        $TimeStamp = Get-Date -uformat "%T"
        $LogMessage = "`r`n$TimeStamp`t`t${JobName}`tUpload-Timelapse"
        ForEach ($Source in $Sources)
        {
            # Only upload a file if it exists
            If (Test-Path -Path $Source.FinalFilename)
            {
                $UploadTitle = Split-Path $Source.FinalFilename -Leaf
                $UploadTitle = $UploadTitle.Substring(0, $UploadTitle.LastIndexOf('.'))
                $VideoID = ""
                $VideoID = Add-YouTube-Video -File $Source.FinalFilename -Title $UploadTitle -CategoryID 22 -Description $Source.Description -PrivacyStatus "unlisted" -LocationDescription $Source.Location -RecordingDate $DateStartSystem
                If ($VideoID)
                {
                    $VideoURL = "https://youtu.be/" + $VideoID
                    $LogMessage = $LogMessage + "`n`nSource " + $Source.Number + ":`t`t" + $Source.Name + "`nFilename:`t`t" + $Source.FinalFilename + "`nTitle:`t`t`t" + $UploadTitle + "`nDescription:`t" + $Source.Description + "`nLocation:`t`t" + $Source.Location + "`nRecording Date:`t" + $DateStartSystem + "`nVideo URL:`t`t" + $VideoURL
                }
                Else
                {
                    $LogMessage = $LogMessage + "`n`nSource " + $Source.Number + ":`t`tVideo attempted to upload but failed"
                }
            }
            Else
            {
                $LogMessage = $LogMessage + "`nSource " + $Source.Number + ":`t`tNo video file found - nothing to upload"
            }
        }
        Write-Output ($LogMessage)
    }

    ## ---- [Function End] ----
    End
    {
        # Return to the calling folder
        Pop-Location
    }
}


# Function Cleanup-Timelapse - everything is finished, time to tidy up
function Cleanup-Timelapse
{
    <#
    .SYNOPSIS
        Cycle through the Timelapse folders and the Output folder and remove old items
    .DESCRIPTION
        For all Timelapse folders, remove items older than retention date.
        If a Timelapse folder is empty, remove it as well
        For Output folder, remove items older than retention date.
    .EXAMPLE
        Cleanup-Timelapse
    .OUTPUTS
        Folders with fewer items in them, someimes fewer folders, too
    .NOTES
        Version:        1.0
        Author:         Dean Smith | deanwsmith@outlook.com
        Creation Date:  2019-05-31
        Purpose/Change: Initial script creation
        Version:        1.1
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-14
        Purpose/Change: Merged scripts to use functions
        Version:        1.2
        Author:         Dean Smith | deanwsmith@outlook.com
        Update Date:    2019-06-28
        Purpose/Change: Slight tweaks to correct logic
    #>
    ## ---- [Function Parameters] ----
    [CmdletBinding()]
    Param()

    ## ---- [Function Beginning] ----
    Begin {}

    ## ---- [Function Execution] ----powershell
    Process
    {
        # Get a collection of timelapse folders sorted by date - again - because the scope is by function
        $TimelapseFolders = Get-ChildItem -Path $TimelapseFolder -Directory | 
            Sort-Object CreationTime |
            Select-Object -ExpandProperty FullName
        $TimeStamp = Get-Date -uformat "%T"
        Write-Output ("`r`n$TimeStamp`t${JobName}`tCleanup-Timelapse`nTimelapse:`t" + $TimelapseFolders.Count)

        # Loop through each Timelapse Folder and remove images older than retention days, then remove folders if they are empty
        $TimeStamp = Get-Date -uformat "%T"
        $LogMessage = "`r`n$TimeStamp`t${JobName}`tCleanup-Timelapse"
        ForEach ($Folder in $TimelapseFolders)
        {
            $TimelapseFolderItems = Get-ChildItem -Path $Folder | Where-Object { $_.LastWriteTime -lt $DeletionDate }
            $TimelapseFolderItemCount = $TimelapseFolderItems.Count
            $TimelapseFolderItems | Remove-Item
            $LogMessage = $LogMessage + "`nFolder " + $Folder + ": " + $TimelapseFolderItemCount + " Items Removed"
            If ((Get-ChildItem $Folder | Select-Object -First 1 | Measure-Object).Count -eq 0)
            {
                Remove-Item -Path $Folder -Recurse
                $LogMessage = $LogMessage + "`nFolder " + $Folder + " removed because it is now empty"
            }
        }

        # For the Output Folder, remove videos older than retention days
        $OutputFolderItems = Get-ChildItem -Path $OutputFolder | Where-Object { $_.LastWriteTime -lt $DeletionDate }
        $OutputFolderItemCount = $OutputFolderItems.Count
        $OutputFolderItems | Remove-Item
        $LogMessage = $LogMessage + "`nOutput: "+ $OutputFolderItemCount + " Items Deleted"

        # Write out the details to the transcript
        Write-Output ($LogMessage)
    }

    ## ---- [Function End] ----
    End {}
}


<#
.SYNOPSIS
    Automatically generate timelapse videos for all sources
.DESCRIPTION
    Identify the most recent source folders and launch CreateTimelapse for each folder, then upload to YouTube
.EXAMPLE
    .\GenerateTimelapse.ps1
    .\GenerateTimelapse.ps1 -DateStart 2019-05-31
    .\GenerateTimelapse.ps1 -Upload
    .\GenerateTimelapse.ps1 -DateStart 2019-05-31 -Upload
    .\GenerateTimelapse.ps1 -DateStart 2019-05-01 -DateEnd 2019-05-31
.PARAMETER Date
    Date to process files, optional
.PARAMETER Upload
    Switch to upload videos to YouTube
.OUTPUTS
    Video in mp4 format from CreateTimelapse uploaded to YouTube
.NOTES
    Version:        1.0
    Author:         Dean Smith | deanwsmith@outlook.com
    Creation Date:  2019-05-20
    Purpose/Change: Initial script creation
    Version:        1.1
    Author:         Dean Smith | deanwsmith@outlook.com
    Update Date:    2019-06-06
    Purpose/Change: Merged scripts to use functions
    Version:        1.2
    Author:         Dean Smith | deanwsmith@outlook.com
    Update Date:    2019-06-18
    Purpose/Change: Tweaked MergeTimelapse to change sort order
    Version:        1.3
    Author:         Dean Smith | deanwsmith@outlook.com
    Update Date:    2019-06-28
    Purpose/Change: Added error logic to UploadTimelapse and adjusted logic in CleanupTimelapse
#>

## ---- [Execution] ----

# Set the start and end dates
If($PSBoundParameters.ContainsKey('DateStart'))
{
    $DateStartDisplay = (Get-Date($DateStart) -Format "dd-MMM-yyyy")
    $DateStartSystem  = (Get-Date($DateStart) -Format "yyyy-MM-dd")
}
Else
{
    $DateStartDisplay = (Get-Date((Get-Date).AddDays(-1)) -Format "dd-MMM-yyyy")
    $DateStartSystem  = (Get-Date((Get-Date).AddDays(-1)) -Format "yyyy-MM-dd")
}
If($PSBoundParameters.ContainsKey('DateEnd'))
{
    $DateEndDisplay   = (Get-Date($DateEnd) -Format "dd-MMM-yyyy")
    $DateEndSystem    = (Get-Date($DateEnd) -Format "yyyy-MM-dd")
}
Else
{
    $DateEndDisplay   = (Get-Date -Format "dd-MMM-yyyy")
    $DateEndSystem    = (Get-Date -Format "yyyy-MM-dd")
}

# Load configuration details and set up job and log details
$ConfigurationFile = ".\GenerateTimelapse.xml"
If (Test-Path $ConfigurationFile)
{
	Try
	{
        $Job = New-Object xml
        $Job.Load("$ConfigurationFile")
		$JobFolder = $Job.Configuration.JobFolder
		$JobName = $Job.Configuration.JobName
		$LogFolder = $Job.Configuration.LogFolder
        $JobDate = Get-Date -Format FileDateTime
        $LogFile = "$LogFolder\${JobName}-$JobDate.log"
        $Sources = New-Object System.Collections.ArrayList
        ForEach ($Source in $Job.Configuration.Sources.Source)
        {
            $temp = "" | select "Number", "Name", "Location", "Description", "FolderParse", "FolderFilter", "TimelapseFolders", "MergeParse", "MergeFilter", "MergeVideos", "FinalFilename"
            $temp.Number = $Source.Number
            $temp.Name = $Source.Name
            $temp.Location = $Source.Location
            $temp.Description = $Source.Description
            $temp.FolderParse = '(\d{8})(?:_)(\d{6})(?:_' + $Source.Number + ')'
            $temp.FolderFilter = [regex] $temp.FolderParse
            $temp.TimelapseFolders = New-Object System.Collections.ArrayList
            $temp.MergeParse = '^(.*)(.*)(Timelapse ' + $Source.Name + ' )(' + $DateStartDisplay + ')(\s\d)(\.mp4)'
            $temp.MergeFilter = [Regex] $temp.MergeParse
            $temp.MergeVideos = New-Object System.Collections.ArrayList
            $temp.FinalFilename = ""
            $Sources.Add($temp) | Out-Null
        }
        $TimelapseFolder = $Job.Configuration.TimelapseFolder
        $OutputFolder = $Job.Configuration.OutputFolder
        $VideoHandler = $Job.Configuration.VideoHandler
        $YouTubeUploadFolder = $Job.Configuration.YouTubeUploadFolder
        $YouTubeUploadScript = $Job.Configuration.YouTubeUploadScript
        $RetentionDays = $Job.Configuration.RetentionDays
        $DeletionDate = Get-Date((Get-Date($DateStartSystem)).AddDays($RetentionDays)) -Format "dd-MMM-yyyy"
        $ImageParse = '(?<=TimeLapse_)(.*)(?:_)(.*)(?:_)(.*)(?:_)(.*)(?=.jpg)'
        $ImageFilter = [regex] $ImageParse
	}
	Catch [system.exception]
    {
        Write-Output "Caught Exception: $($Error[0].Exception.Message)"
    }
}

# Start Transcript
Start-Transcript -Path $Logfile -NoClobber -Verbose -IncludeInvocationHeader
$Timestamp = Get-Date -UFormat "%T"
Write-Output ("-" * 79 + "`r`n$Timestamp`t${JobName}: Starting Transcript`r`n" + "-" * 79)
Write-Output ("`r`n$TimeStamp`t${JobName}`n`t`t`tDisplay`t`t`t`tSystem`nStart Date:`t$DateStartDisplay`t`t`t$DateStartSystem`nEnd Date:`t$DateEndDisplay`t`t`t$DateEndSystem")

# Call functions in order to process timelapse images into timelapse videos, merge them, upload them if requested, then clean up afterwards
Identify-Timelapse
Merge-Timelapse
If ($Upload) { Upload-Timelapse }
Cleanup-Timelapse

## Stop Transcript
$Timestamp = Get-Date -UFormat "%T"
Write-Output ("`r`n" + "-" * 79 + "`r`n$Timestamp`t${JobName}: Stopping Transcript`r`n" + "-" * 79)
Stop-Transcript