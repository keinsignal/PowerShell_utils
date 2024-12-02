#========================================================================
#	Title: LogArchive.ps1]
# Author: Eric Hillman
#	Purpose: Manages archiving and deletion of log files
# Last update: 2024-11-27

[CmdletBinding()]
param( 
	$LogFolder = "c:\inetpub\logs\LogFiles\W3SVC",  # We probably don't want a default LogFolder, but making this mandatory isn't the right answer either
	$LogFolderList = $null,                        # because it's ignored if LogFolderList is set
	$LogFilePattern = "*.log",
	[int]$ArchiveDays = 5, 
	[int]$DeleteDays = 30,
    [switch]$Recurse = $False,
	[switch]$Force,
    [switch]$Help
)

#
$TODO = @'
TODO: 
Better error handling? Currently there isn't much. [GETTING THERE]
Email notifications? Might at least be useful to notify on errors somehow. [TURNS OUT THIS SUCKS TO DO]
Preserve timestamps, make the .zip files have the same LastWriteTime as the original log. [DONE]
'@

$USAGE = @'
Usage: Archive-Logs.ps1 (-LogFolder <path\to\logs\> | -LogFolderList <file_containing_list_of_folders>)
 (-LogFilePattern <pattern>) (-ArchiveDays <n>) (-DeleteDays <x>) (-Recurse) (-Verbose) (-Force)
 
Options: 
 -LogFolder: full path to folder where logs are. Default is "c:\inetpub\logs\LogFiles\W3SVC"
 -LogFolderList: path to file containing a list of such folders, one per line. Overrides -LogFolder.
 -LogFilePattern: file matching expression, default is "*.log"
 -ArchiveDays: files older than this number of days will be archived (zipped). Default is 5. Set to 0 to bypass archiving.
 -DeleteDays: archives older than this number of days will be deleted. Default is 30. Set to 0 to disable deletion. Deletes logs instead of archives if ArchiveDays is set to 0
 -Recurse: search subfolders. Defaults to off
 -Verbose: be a chatty little script.
 -Force: overwrite existing archives. If not used, script will halt if it encounters a pre-existing archive.
 -Help: print this message
 
 Note: Archive files will have the same timestamp as the original logfile (if the script is run with sufficient privileges). 
       If a log file is more than DeleteDays old, it will be archived the first time the script is run, and then deleted on the next run.
       Recommend running as admin, or as "SYSTEM" with "Highest Privileges" enabled if running through Task Scheduler.
'@

if ($Help) {Write-Host $USAGE; exit;}

$Now = Get-Date
$ArchiveTime = $Now.AddDays(-$ArchiveDays)
$DeleteTime = $Now.AddDays(-$DeleteDays)

$ArchiveFilePattern = $LogFilePattern + ".zip"

Write-Verbose "Starting search"

if ($LogFolderList.Length -gt 0) { 
  if (! (Test-Path $LogFolderList)) { throw "File $LogFolderList not found" } 
  $FolderList = (Get-Content $LogFolderList).Trim() | ? { $_ -ne "" }
}
else { $FolderList = @( $LogFolder ) }

#### ERROR HANDLING NOTES (or lack thereof)
## Things we aren't testing for here:
## FolderList is empty (only happens if LogFolderList is specified but points to empty file).
## All folders exist (will crash out on first unexisting folder encountered)
## Need to rethink how this is all handled & unset default for LogFolder while intelligently handling its absence
##   see "about_parameter_sets" for a possible solution here.


foreach ($folder in $FolderList) {
  if ($Recurse) {  
	Write-Verbose "Searching folder $folder (recurse on)"
    $Files = Get-Childitem -Path "$folder\*" -Include $LogFilePattern -Recurse
    $Archives = Get-Childitem -Path "$folder\*" -Include $ArchiveFilePattern -Recurse
  } 
  else {  
	Write-Verbose "Searching folder $folder (no recurse)"
    $Files = Get-Childitem -Path "$folder\*" -Include $LogFilePattern 
    $Archives = Get-Childitem -Path "$folder\*" -Include $ArchiveFilePattern 
  }

  if ($ArchiveDays -gt 0) { 
    Write-Verbose "Archiving enabled"
    Add-Type -Assembly System.IO.Compression.FileSystem 

    foreach ($file in $Files) {
      if ($file.LastWriteTime -le $ArchiveTime) {
        $ZipFile = $file.FullName + ".zip"
        Write-Verbose "About to archive $($file.FullName) to $ZipFile"
        $last_write = $file.LastWriteTime
        
        ## Check to see if file exists
        ## This is currently a fatal error - script will not attempt to continue!
        if (Test-Path $ZipFile) {
          if ($Force) {
            Write-Verbose "Overwriting $ZipFile"
            Remove-Item $ZipFile -Force
          }
          else {
            throw "Archive file $ZipFile already exists; will not overwrite without -Force."
          }
        }
        $this_arch = [System.IO.Compression.ZipFile]::Open($ZipFile, "Create")
        $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
          $this_arch,
          $file.FullName,
          $file.Name
        )
        # Close the archive
        $this_arch.Dispose()
        $this_arch = $null
        # Set archive file date to match log file
        Set-ItemProperty -Path $ZipFile -Name LastWriteTime -Value $last_write
        # Remove the original logfile
        Remove-Item $file -Force
      }
    }
  }

  if ($DeleteDays -gt 0) {
    foreach ($archive in $Archives) {
      if ($archive.LastWriteTime -le $DeleteTime) {
        Write-Verbose "Deleting $archive"
        Remove-Item $archive -Force
      }
    }
	if ($ArchiveDays -eq 0) {
		foreach ($file in $Files) {
			if ($file.LastWriteTime -le $DeleteTime) {
				Write-Verbose "Deleting $file"
				Remove-Item $file
			}
		}
	}
  }
}