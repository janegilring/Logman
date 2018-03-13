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
    [string] $XmlTemplatePath

    [DscProperty()]
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

                    $output = logman.exe import -n $this.DataCollectorSetName -xml $this.XmlTemplatePath
                    if ( $output -match '^Error:' )
                    {
                        throw $output
                    }
                    $output = logman.exe -start $this.DataCollectorSetName
                    if ( $output -match '^Error:' )
                    {
                        throw $output
                    }
                }
                else 
                {
                    Write-Verbose -Message "$($this.XmlTemplatePath) not found or temporary inaccessible, trying again on next consistency check"
                }
            }

            $CurrentLogPath = $this.GetLogPath()
            $ExpectedLogPath = $this.GetExpectedLogPath()
            if ([string]::IsNullOrEmpty($ExpectedLogPath) -eq $false -and $CurrentLogPath -ne $ExpectedLogPath)
            {
                Write-Verbose -Message "Updating LogFilePath $CurrentLogPath to $ExpectedLogPath"
                $this.UpdateLogPath()
            }
        }
        else
        {
            Write-Verbose -Message "Removing logman Data Collector Set $($this.DataCollectorSetName)"
            $null = logman.exe -stop $this.DataCollectorSetName
            $output = logman.exe delete $this.DataCollectorSetName
            if ( $output -match '^Error:' )
            {
                throw $output
            }
        }
    }
 
    [bool] Test()
    {
        $logmanquery = $this.Query()

        if ($logmanquery -eq $this.DataCollectorSetName) 
        {
            Write-Verbose -Message "Data Collector $($this.DataCollectorSetName) exists"

            $CurrentLogPath = $this.GetLogPath()
            $ExpectedLogPath = $this.GetExpectedLogPath()
            if ([string]::IsNullOrEmpty($ExpectedLogPath) -eq $false -and $CurrentLogPath -ne $ExpectedLogPath)
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
            Select-String -Pattern "^Output\sLocation:\s*") -replace "^Output\sLocation:\s*(.+_)[^_]+",'$1') -as [string]
        return $logmanquery
    }

    [string] GetExpectedLogPath()
    {
        $setting = $this.LogFilePath
        if ( [string]::IsNullOrEmpty($setting) )
        {
            return $setting
        }
        if ( -not $setting.EndsWith('_') )
        {
            $setting += '_'
        }
        return $setting
    }

    [void] UpdateLogPath ()
    {
        $null = logman.exe -stop $this.DataCollectorSetName
        $output = logman.exe -update $this.DataCollectorSetName -o "$($this.GetExpectedLogPath())"
        if ( $output -match '^Error:' )
        {
            throw $output
        }
        $output = logman.exe -start $this.DataCollectorSetName
        if ( $output -match '^Error:' )
        {
            throw $output
        }
    }
}
