# BuildPackage
![NuGet badge](https://img.shields.io/nuget/v/BuildPackage.svg)

https://www.nuget.org/packages/BuildPackage/

By installing this package into a project, the project build is extended with a build step that creates NuGet packages.

# How To
Install the package directly into the project that must be packaged using the package manager GUI or console.

CMD:
```
nuget.exe install BuildPackage
```

Powershell:
```ps
Install-Package BuildPackage
```

Edit the packages.config file to indicate that `NuGet.CommandLine` is not required to run your app by marking it as a `developmentDependency`. (Unless your app *does* depend on NuGet.exe to run, in which case you should ignore this advice)

Do the same thing for `BuildPackage` if your NuGet client didn't set it already.
```xml
<package id="BuildPackage" version="..." targetFramework="..." developmentDependency="true" />
<package id="NuGet.CommandLine" version="..." targetFramework="..." developmentDependency="true" />
```

That's it! That's all you have to do. The next time you build your project, an extra build step will run `nuget.exe pack` on your project file.

The script supports incremental building and cleaning. Packages that are created this way will be removed the next time you do a `Clean`.

To get the best results, add a customized nuspec file to each project that you will package this way. More information: https://docs.nuget.org/create/nuspec-reference

# Behind the Scenes
Upon installation, NuGet adds imports to the custom build targets in this package to your project file. The imported targets file contain self-bootstrapping code to ensure that the `BuildPackage` target is executed when you build your project. It does this by extending MSBuild's `BuildDependsOn` property.

```xml
<BuildDependsOn>$(BuildDependsOn);BuildPackage</BuildDependsOn>
```

In a typical project, this evaluates to the following sequence of build targets:
 1. BeforeBuild
 2. CoreBuild
 3. AfterBuild
 4. BuildPackage

The `BuildPackage` target itself depends on another target: `BuildPackageCore`.

```xml
<Target Name="BuildPackage" DependsOnTargets="BuildPackageCore" Outputs="$(Packages)" Condition=" '$(BuildPackage)' == 'True' " />
<Target Name="BuildPackageCore">
...
</Target>
```

This is where the magic happens. When executed, the `BuildPackageCore` target finds `NuGet.exe` somewhere in your packages folder, then executes `NuGet.exe pack` on your project file.

The full command line looks like this:
```sh
NuGet.exe pack $(MSBuildProjectFile) -Symbols -IncludeReferencedProjects -OutputDirectory $(OutDir) -Properties Configuration=$(Configuration).
```

The output of this command is parsed with a regular expression.
```regex
Successfully created package '(?<package>.+)'.
```

For every regex match that is found in the output, a line is added to the FileListAbsolute.txt file to support incremental cleaning.

# Limitations

Build artifacts are packaged on every build. There are some limitations to this approach. It's not possible to create a single package that contains multiple build configurations. This is a showstopper for cross-platform development where targeting multiple platforms requires rebuilding with different compiler options. This limiation does not apply to Portable Class Libraries (PCL) if used correctly.

# Advanced Features
 - Package dependencies
 - Organize package contents
 - Enable/Disable BuildPackage
 - Override path to NuGet.exe

## Package Dependencies
Packages are built with the `-IncludeReferencedProjects` option. You can customize the nuspec file of the project file and each referenced project to control how this option behaves.

From docs.nuget.org:
 > If a referenced project has a corresponding nuspec file that has the same name as the project, then that referenced project is added as a dependency. Otherwise, the referenced project is added as part of the package.
 
## Organize Package Contents
You can add a build step that exectutes before building the package. This option was added to support convention based working directories.

MSBuild:
```xml
<Target Name="AfterBuild">
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

You can also set it at the solution level by setting an environment variable.

CMD:
```
SET BuildPackage=False
MSBuild MySolution.sln
```

Or you can explicitly pass it as a parameter.

CMD:
```
MSBuild MySolution.sln /p:BuildPackage=False
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
```
SET NuGetToolPath=C:\bin\NuGet.exe
msbuild MySolution.sln
```

TIP: you can set `NuGetToolPath` to `NuGet.exe` if it is available on your `PATH`.
