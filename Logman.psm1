enum Ensure
{
    Absent
    Present
}

[DscResource()]
class Logman
{
    [DscProperty(Key)]
    [string] $DataCollectorSetName

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Mandatory)]
    [string] $XmlTemplatePath

    [Logman] Get()
    {
        $logmanquery = $this.Query()

        $returnObj = [Logman]::new()
        $returnObj.DataCollectorSetName = $this.DataCollectorSetName
        $returnObj.XmlTemplatePath      = $this.XmlTemplatePath

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
        if( $this.Ensure -eq [Ensure]::Present)
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
        elseif ($this.Ensure -eq [Ensure]::Absent) 
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
            Select-String -Pattern "^Name:\s*$($this.DataCollectorSetName)$") -replace "^Name:\s*",',' -as [string]
        return $logmanquery
    }
}
