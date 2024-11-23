
#$sourceFile = 'C:\Users\rickg\Google Drive Streaming\My Drive\Music\Playlists\Christmas Favorites-fix-bug-rename.wpl'
#$destinationFile = 'C:\Users\rickg\Downloads\christmas-favorites-heidi.m3u'

$sourceFile = 'C:\Users\rickg\Google Drive Streaming\My Drive\Music\Playlists\Poppas Xmas-fix-bug-rename.wpl'
$destinationFile = 'C:\Users\rickg\Downloads\christmas-favorites-poppa.m3u'

$musicFilepath = 'C:\Users\rickg\Google Drive Streaming\My Drive\Music'

[xml]$xml = Get-Content $sourceFile

$wplMedia = $xml.smil.body.seq.media | ForEach-Object {
    [PSCustomObject]@{
        'src' = $_.src
        'albumTitle' = $_.albumTitle
        'albumArtist' = $_.albumArtist
        'trackArtist' = $_.trackArtist
        'trackTitle' =$_.trackTitle
        'duration' = $_.duration
    }
}

$wplMedia

# TODO: Build a new object for M3U

[string[]]$m3uLines = '#EXTM3U'

# TODO: Loop through the wplMedia and fix the paths for any object that has a src where the value starts with '\\Media\Music\' and replace it with '..\'
#   e.g.    this:    \\Media\Music\Bing Crosby\It's Christmas Time Disc 1\Bing Crosby-It's Christmas Time Disc 1-01-Silent Night.mp3
#           becomes: ..\Bing Crosby\It's Christmas Time Disc 1\Bing Crosby-It's Christmas Time Disc 1-01-Silent Night.mp3
$wplMedia | ForEach-Object {
    if ([string]::IsNullOrEmpty($_.src)) {
        $jsonString = ConvertTo-Json $_ -Compress
        Write-Output ("ERROR: No src for {0}" -f $_.trackTitle)

        Write-Output ("  attempting to fix..." -f $_.trackTitle)
        # Attempt to get the folder of the albumArtist
        $albumArtist = $_.albumArtist
        $albumArtistSearchPath = "$musicFilepath\$albumArtist"
        Write-Output ("  checking for albumArtist folder using path {0}" -f $albumArtistSearchPath)
        if (Test-Path $albumArtistSearchPath) {
            Write-Output ("  success! found {0}" -f $albumArtistSearchPath)

            # Attempt to get the file for the track
            $filter = ("*{0}*" -f $_.trackTitle)
            $file = Get-ChildItem -Path $albumArtistSearchPath -Recurse -Filter $filter
            if ($file) {
                Write-Output ("  success! found {0}" -f $file.FullName)
                #$relativePath = [System.IO.Path]::GetRelativePath($musicFilepath, $file.FullName)
                $relativeBathPath = Join-Path $musicFilepath -ChildPath 'Playlists'
                $relativePath = Resolve-Path -Path $file.FullName -Relative -RelativeBasePath $relativeBathPath 
                $m3uLines += $relativePath 
            } else {
                Write-Error -Message ("  that didn't work..." -f $_.trackTitle)
                $m3uLines += "ERROR: file not found " + $jsonString
            }
        }
        else {
            Write-Error -Message ("  that didn't work..." -f $_.trackTitle)
            $m3uLines += "ERROR: folder not found " + $jsonString
        }   
    }
    else {
        Write-Output ("Fixing src for {0}" -f $_.trackTitle)
        # Convert the src
        $srcFixed = $_.src.replace('\\Media\Music\', '..\')
        $m3uLines += $srcFixed
    }
}

# Save the m3u
$m3uLines | Out-File $destinationFile