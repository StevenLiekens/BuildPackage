# BuildPackage

[![Join the chat at https://gitter.im/StevenLiekens/BuildPackage](https://badges.gitter.im/StevenLiekens/BuildPackage.svg)](https://gitter.im/StevenLiekens/BuildPackage?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
![NuGet badge](https://img.shields.io/nuget/v/BuildPackage.svg)

https://www.nuget.org/packages/BuildPackage/

By installing this package into a project, the project build is extended with a build step that creates NuGet packages.

# How To
Install the package directly into the project that must be packaged using the package manager GUI or console.

Powershell:
```ps
Install-Package BuildPackage
```

Edit the packages.config file to indicate that `NuGet.CommandLine` is not required to run your app by marking it as a `developmentDependency`. Do the same thing for `BuildPackage` if your NuGet client didn't set it already.
```xml
<package id="BuildPackage" version="..." targetFramework="..." developmentDependency="true" />
<package id="NuGet.CommandLine" version="..." targetFramework="..." developmentDependency="true" />
```

That's it! That's all you have to do. The next time you build your project, an extra build step will run `nuget.exe pack` on your project file.

The script supports incremental building and cleaning. Packages that are created this way will be removed the next time you do a `Clean`.

To get the best results, add a customized nuspec file to each project that you will package this way. More information: https://docs.nuget.org/create/nuspec-reference

# Behind the Scenes
Upon installation, NuGet adds imports for the custom build targets in this package to your project file. The imported targets file contains self-bootstrapping code to ensure that the `BuildPackage` target is executed when you build your project. It does this by extending MSBuild's `PrepareForRunDependsOn` property.

```xml
<PrepareForRunDependsOn>$(PrepareForRunDependsOn);BuildPackage</PrepareForRunDependsOn>
```

In a typical project, this evaluates to the following sequence of build targets:
 1. CopyFilesToOutputDirectory
 2. BuildPackage
 3. PrepareForRun

The `BuildPackage` target itself depends on three other targets:
 1. BeforeBuildPackage
 2. CoreBuildPackage
 3. AfterBuildPackage
 
The `CoreBuildPackage` target is where the magic happens. Do not override this target! The other targets (BeforeBuildPackage, AfterBuildPackage) are extensibility points that you can override.

```xml
<Target Name="BuildPackage" DependsOnTargets="$(BuildPackageDependsOn)" Condition=" '$(BuildPackage)' == 'True' " />
<Target Name="CoreBuildPackage">
...
</Target>
```

When executed, the `CoreBuildPackage` target finds `NuGet.exe` somewhere in your packages folder, then executes `NuGet.exe pack` on your project file. It is smart about which options it should pass to NuGet.exe such as the current build configuration and output directory. The full command line looks like this:
```sh
"C:\src\HelloWorld\packages\NuGet.CommandLine.3.3.0\tools\NuGet.exe" pack "HelloWorld.csproj" -OutputDirectory "bin\Debug\\" -BasePath "bin\Debug\\" -Symbols -IncludeReferencedProjects -Properties Configuration=Debug -NonInteractive
```

The output of this command is parsed with a regular expression.
```regex
Successfully created package '(?<package>.+)'.
```

An item is added to the `BuildPackageOutputs` item group for every regex match that is found in the output. Additionally, a line is added to the `obj\$(MSBuildProjectName).FileListAbsolute.txt` file to support incremental cleaning.

```xml
<ItemGroup>
  <!-- Each item contains the path to a nupkg file -->
  <BuildPackageOutputs Include=".nupkg">
    <!-- Boolean metadata indicates whether the package is a symbols package -->
    <Symbols>True/False</Symbols>
  </BuildPackageOutputs>
</ItemGroup>
```

# Limitations

Build artifacts are packaged on every build. There are some limitations to this approach. It's not possible to create a single package that contains multiple build configurations. This is a showstopper for cross-platform development where targeting multiple platforms requires rebuilding with different compiler options. This limiation does not apply to Portable Class Libraries (PCL) if used correctly.

# Advanced Features
 - Enable/Disable BuildPackage
 - Package dependencies
 - Organize package contents
 - Override path to NuGet.exe

## Enable/Disable BuildPackage
You can enable or disable packaging by setting the value of an MSBuild property named `BuildPackage` to `False`. You can do this at the project level or at the build configuration level.

MSBuild:
```xml
<!-- Disable packaging at the project level -->
<PropertyGroup>
	<BuildPackage>False</BuildPackage>
</PropertyGroup>
```

MSBuild:
```xml
<!-- Disable packaging at the build configuration level -->
<PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
	<BuildPackage>False</BuildPackage>
</PropertyGroup>
```

You can also set it at the solution level by setting an environment variable or by passing it as a parameter to MSBuild on the command line.

CMD:
```sh
SET BuildPackage=False
MSBuild MySolution.sln
```

CMD:
```sh
MSBuild MySolution.sln /p:BuildPackage=False
```

## Package Dependencies
Packages are built with the `-IncludeReferencedProjects` option. You can customize the nuspec file of the project file and each referenced project to control how this option behaves.

From docs.nuget.org:
 > If a referenced project has a corresponding nuspec file that has the same name as the project, then that referenced project is added as a dependency. Otherwise, the referenced project is added as part of the package.
 
## Organize Package Contents
You can add a build step that executes before building the package. This option was added to support convention based working directories. **This option breaks incremental building and cleaning**.

MSBuild:
```xml
<Target Name="BeforeBuildPackage">
  <!--
    Copy, move or delete files to turn $(OutDir) into a convention based working directory
    Task reference: https://msdn.microsoft.com/en-us/library/7z253716.aspx
    Conventions: https://docs.nuget.org/create/creating-and-publishing-a-package#from-a-convention-based-working-directory
  -->
  <ItemGroup>
    <Images Include="$(OutDir)*.jpg" />
  </ItemGroup>
  <MakeDir Directories="$(OutDir)content\images\" />
  <Move SourceFiles="@(Images)" DestinationFolder="$(OutDir)content\images\" />
</Target>
```

## Override Path to NuGet.exe
The build script will try to find NuGet.exe somewhere in your project's `packages` folder. You can override this behavior by setting an MSBuild variable named `NuGetToolPath`.

MSBuild:
```xml
<PropertyGroup>
	<NuGetToolPath>C:\bin\NuGet.exe</NuGetToolPath>
</PropertyGroup>
```

CMD:
```sh
SET NuGetToolPath=C:\bin\NuGet.exe
msbuild MySolution.sln
```

TIP: you can set `NuGetToolPath` to `NuGet.exe` if it is available on your `PATH`.

# MSBuild Parameter Reference
Most (but not all) NuGet command line options can be customized by setting the value of a corresponding MSBuild property.

| Property                              | Pack command option       | Value                                                |
| ------------------------------------- | ------------------------- | ---------------------------------------------------- |
| BuildPackage                          |                           | Boolean. Default: True.                              |
| NuGetToolPath                         |                           | String. (file)                                       |
| BuildPackageOutputDirectory           | OutputDirectory           | String. Default: $(OutDir)                           |
| BuildPackageBasePath                  | BasePath                  | String. Default: $(OutDir)                           |
| BuildPackageVersion                   | Version                   | String. (semver)                                     |
| BuildPackageExclude                   | Exclude                   | String. (glob)                                       |
| BuildPackageSymbols                   | Symbols                   | Boolean. Default: True.                              |
| BuildPackageTool                      | Tool                      | Boolean. Default: True for console and windows apps. |
| BuildPackageNoDefaultExcludes         | NoDefaultExcludes         | Boolean.                                             |
| BuildPackageNoPackageAnalysis         | NoPackageAnalysis         | Boolean.                                             |
| BuildPackageIncludeReferencedProjects | IncludeReferencedProjects | Boolean. Default: True.                              |
| BuildPackageExcludeEmptyDirectories   | ExcludeEmptyDirectories   | Boolean.                                             |
| BuildPackageProperties                | Properties                | String. Default: Configuration=$(Configuration)      |
| BuildPackageAdditionalProperties      | Properties                | String.                                              |
| BuildPackageDetailed                  | Verbosity                 | Boolean.                                             |
| BuildPackageMinClientVersion          | MinClientVersion          | String. (semver)                                     |
| BuildPackageMSBuildVersion            | MSBuildVersion            | Number. (4, 12 or 14)                                |

More information: https://docs.nuget.org/consume/command-line-reference#pack-command-options
