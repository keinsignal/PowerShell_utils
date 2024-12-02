# Quick & Dirty copy of share definitions from one machine to another. 
# Drive letters must be identical on both. Paths will be created if they
# do not already exist (but will not create the whole directory tree if
# sharing subfolders).

$oldmaps = Import-Clixml 'C:\temp\dmaps.xml' # Exported via "Get-SmbShare | Export-CliXml"

$oldmaps | % {
    if ($_.Name -notmatch '\$$') {
        "{0,-23} {1}" -f $_.Name, $_.Path
        if (-not $(Test-Path -Path $_.Path -PathType Container)) {
            "{0} does not exist, fixing..." -f $_.Path
            New-Item -Path $_.Path -ItemType Directory | Out-Null
        }
        # Probably not safe to just copy these across as-is ("$_ | New-SmbShare" <= BAD IDEA)
        New-SmbShare -Path $_.Path -Name $_.Name -Description $_.Description `
                     -ConcurrentUserLimit $_.ConcurrentUserLimit `
                     -SecurityDescriptor $_.SecurityDescriptor

    }
}
