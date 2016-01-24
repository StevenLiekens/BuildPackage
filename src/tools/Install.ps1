param($installPath, $toolsPath, $package, $project)
$configFile =  $project.ProjectItems["packages.config"]
$fullPath = $configFile.Properties["FullPath"].Value
[xml]$config = Get-Content $fullPath
$nuget = $config |select-xml "//package[@id='NuGet.CommandLine']"
if ($nuget -ne $null)
{
    $node = $nuget.Node
    $node.SetAttribute("developmentDependency", "true")
    $config.Save($fullPath)
}
