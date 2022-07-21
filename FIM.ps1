Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already_Exists() {
    $baselineExists =Test-Path -Path .\baseline.txt 

    if($baselineExists) {

    #Delete
    Remove-Item -Path .\baseline.txt
    }
}

Write-Host "`nWhat would you like to do?"
Write-Host "`nA) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline?"

$response = Read-Host -Prompt "`nPlease enter 'A' or 'B'"

if ($response -eq "A".ToUpper()) {

#Delete baseline.txt if it already exists
    Erase-Baseline-If-Already-Exists

    #Calculate Hash from the target files and store in baseline.txt. Collect all files in the target folder
    $files = Get-ChildItem -Path .\Files

    #For each file, calculate the hash, and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
    
}

elseif ($response -eq "B".ToUpper()) {
    
    $fileHashDictionary = @{}

    #Load file|hash from baseline.txt, store them in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathsAndHashes) {
         $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    #Monitor files with saved Baseline
    while ($true) {
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path .\Files

        #For each file, calculate the hash, and write to baseline.txt
        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName
            "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append

            #Notify if a new file has been created
            if ($fileHashDictionary[$hash.Path] -eq $null) {

                Write-Host "$($hash.Path) has been created!"
            }
            else {

                # Notify if a new file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    # The file has not changed
                }
                else {

                    #File has been compromised!, notify the user
                    Write-Host "$($hash.Path) has changed!!!"
                }
            }
        }

        foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {

                #One of the baseline files must have been deleted, notify the user
                Write-Host "$($key) has been deleted!"
            }
        }
    }
}