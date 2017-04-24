. C:\work\sxa\main\Projects\Compass\Build\localDevEnvironment.ps1 

# -------------------------------------------------------------------------------------------------------------------------

$FilterHash =   @{FilterName="Publisher";
    FilterValue="Allscripts Healthcare Solution*";
    PropertyFilters = 
    @( 
        @{VersionMajor=$SCMMajorVersion; VersionMinor=$SCMMinorVersion; DisplayName="Sunrise Emergency Care*Client*"}
        @{VersionMajor=$SCMMajorVersion; VersionMinor=$SCMMinorVersion; DisplayName="Sunrise Emergency Care*SQL*"}
        ,@{VersionMajor=$SCMMajorVersion; VersionMinor=$SCMMinorVersion; DisplayName="Sunrise Ambulatory*Client*"}
        ,@{VersionMajor=$SCMMajorVersion; VersionMinor=$SCMMinorVersion; DisplayName="Sunrise Clinical Manager*Client*"}
        ,@{VersionMajor=$SCMMajorVersion; VersionMinor=$SCMMinorVersion; DisplayName="Sunrise Clinical Manager*SQL*"}
      #,@{DisplayVersion=("{0}.{1}.*" -f $HeliosMajorVersion,$HeliosMinorVersion); DisplayName="Allscripts Gateway*"}
    )
  }

$RegValueNames = @("Publisher", "UninstallString", "DisplayName", "DisplayVersion", "VersionMajor", "VersionMinor", "Comments")

# -------------------------------------------------------------------------------------------------------------------------

$UninstallKeyPath =   "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"

  $PrimaryFilterName = $FilterHash["FilterName"]
  $PrimaryFilterValue = $FilterHash["FilterValue"]

  $PrimaryDataSet = Get-ChildItem $UninstallKeyPath | 
        Where-Object {$_.Property -contains $PrimaryFilterName } | 
        Where-Object { (Get-ItemProperty -Path $_.PSPath -Name $PrimaryFilterName).$PrimaryFilterName -like $PrimaryFilterValue } |
        Select-Object -InputObject {Get-ItemProperty -Path $_.PSPath -Name $RegValueNames -ErrorAction SilentlyContinue} *

  $Ret = @()
  If($PrimaryDataSet -ne $null) {
    ForEach($SecondaryFilter in $FilterHash["PropertyFilters"]) {
      #SecondaryFilters 
      $Temp = $PrimaryDataSet
        # Successively winnow down $PrimaryDataSet by each key in a single secondary filter.
      ForEach($KeyName in $SecondaryFilter.Keys) {
        $Temp = @($Temp | where { 
            # If the following fails, $ip will be null ($Null)
            $ip = Get-ItemProperty -Path $_.PSPath -Name $KeyName -ErrorAction SilentlyContinue
            ($ip -eq $Null) -or ($ip.$KeyName -like $SecondaryFilter[$KeyName]) 
        })
      }
      $Ret = $Ret + $Temp
	}
  }

