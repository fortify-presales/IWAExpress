#
# Example script to perform Fortify SCA static analysis
#

# Import some supporting functions
Import-Module $PSScriptRoot\modules\FortifyFunctions.psm1

$AppName = "IWAExpress"
$AppVersion = "shopping-cart"
$UploadToSSC = $False							# Upload issues to SSC by default
$SSCUrl = $Env:SSC_URL							# Get SSC URL from environment variable "SSC_URL"
$SSCAuthToken = $Env:SSC_AUTH_TOKEN				# SSC AnalysisUploadToken token from environment variable "SSC_AUTH_TOKEN"
												# Can be created using: fortifyclient token -gettoken AnalysisUploadToken  -url $SSCUrl -user [your-username] -password [your-password]

$ScanSwitches = "-Dcom.fortify.sca.Phase0HigherOrder.Languages=javascript,typescript -Dcom.fortify.sca.EnableDOMModeling=true -Dcom.fortify.sca.follow.imports=true -Dcom.fortify.sca.exclude.unimported.node.modules=true"

# Test we have Fortify installed successfully
Test-Environment

# Run the translation and scan

Write-Host Cleaning up workspace...
& sourceanalyzer '-Dcom.fortify.sca.ProjectRoot=.fortify' -b "$AppName" -clean

Write-Host Running translation...
& sourceanalyzer '-Dcom.fortify.sca.ProjectRoot=.fortify' $ScanSwitches -b "$AppName" -verbose `
	 -exclude ".\src\public\assets\js\lib" -exclude ".\src\public\assets\css\lib" -exclude ".\node_modules" ".\src"

Write-Host Running scan...
& sourceanalyzer '-Dcom.fortify.sca.ProjectRoot=.fortify' $ScanSwitches -b "$AppName" -verbose `
   -build-project "$AppName" -build-version "$AppVersion" -build-label "SNAPSHOT" -scan -f "$($AppName).fpr"

Write-Host Generating PDF report...
& ReportGenerator '-Dcom.fortify.sca.ProjectRoot=.fortify' -user "Demo User" -format pdf -f "$($AppName).pdf" -source "$($AppName).fpr"

if ($UploadToSSC -eq $True) {
	Write-Host Uploading results to SSC...
	& fortifyclient uploadFPR -file "$($AppName).fpr" -url $SSCUrl -authtoken $SSCAuthToken -application $AppName -applicationVersion $AppVersion
}

Write-Host Done.
