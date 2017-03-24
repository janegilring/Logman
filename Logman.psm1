enum Ensure
{
    Absent
    Present
}

[DscResource()]
class Logman
{
    [DscProperty(Key)]
    [ValidateNotNullOrEmpty()]
    [string] $DataCollectorSetName

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty()]
    [ValidateNotNullOrEmpty()]
    [string] $XmlTemplatePath

    [DscProperty()]
    [ValidateNotNullOrEmpty()]
    [string] $LogFilePath

    [Logman] Get()
    {
        $logmanquery = $this.Query()

        $returnObj = [Logman]::new()
        $returnObj.DataCollectorSetName = $this.DataCollectorSetName
        $returnObj.XmlTemplatePath  = $this.XmlTemplatePath
        $returnObj.LogFilePath = $this.GetLogPath()

        if ($logmanquery -eq $this.DataCollectorSetName) 
        {
            $returnObj.Ensure = [Ensure]::Present
        }
        else 
        {
            $returnObj.Ensure = [Ensure]::Absent
        }

        return $returnObj
    }

    [void] Set()
    {
        $logmanquery = $this.Query()

        if($this.Ensure -eq [Ensure]::Present)
        {
            if ($logmanquery -eq [string]::Empty -and $this.XmlTemplatePath)
            {
                if (Test-Path -Path $this.XmlTemplatePath) 
                {
                    Write-Verbose -Message "Importing logman Data Collector Set $($this.DataCollectorSetName) from Xml template $($this.XmlTemplatePath)"

                    $null = logman.exe import -n $this.DataCollectorSetName -xml $this.XmlTemplatePath
                }
                else 
                {
                    Write-Verbose -Message "$($this.XmlTemplatePath) not found or temporary inaccessible, trying again on next consistency check"
                }
            }

            $CurrentLogPath = $this.GetLogPath()
            if ($CurrentLogPath -ne $this.LogFilePath)
            {
                Write-Verbose -Message "Updating LogFilePath $CurrentLogPath to $($this.LogFilePath)"
                $this.UpdateLogPath()
            }
        }
        else
        {
            Write-Verbose -Message "Removing logman Data Collector Set $($this.DataCollectorSetName)"
            $null = logman.exe delete $this.DataCollectorSetName
        }
    }
 
    [bool] Test()
    {
        $logmanquery = $this.Query()

        if ($logmanquery -eq $this.DataCollectorSetName) 
        {
            Write-Verbose -Message "Data Collector $($this.DataCollectorSetName) exists"

            
            if ($this.LogFilePath -and $this.LogFilePath -ne $this.GetLogPath())
            {
                Write-Verbose -Message "LogFilePath is not configured correctly"
                return $false
            }

            if ($this.Ensure -eq [Ensure]::Present) 
            {
                return $true
            }
            else
            {
                return $false
            }
        }
        else 
        {
            Write-Verbose -Message "Data Collector $($this.DataCollectorSetName) does not exist"

            if ($this.Ensure -eq [Ensure]::Present) 
            {
                return $false
            }
            else
            {
                return $true
            }
        }
    }

    [string] Query ()
    {
        $logmanquery = (logman.exe query $this.DataCollectorSetName |
            Select-String -Pattern "^Name:\s*$($this.DataCollectorSetName)$") -replace "^Name:\s*",'' -as [string]
        return $logmanquery
    }

    [string] GetLogPath ()
    {
        $logmanquery = ((logman.exe query $this.DataCollectorSetName |
            Select-String -Pattern "^Output\sLocation:\s*") -replace "^Output\sLocation:\s*",''  -split '_')[0] -as [string]
        return $logmanquery
    }

    [void] UpdateLogPath ()
    {
        logman.exe -stop $this.DataCollectorSetName
        logman.exe -update $this.DataCollectorSetName -o "$($this.LogFilePath)"
        Logman.exe -start $this.DataCollectorSetName
    }
}
