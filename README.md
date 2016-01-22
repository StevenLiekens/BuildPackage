# BuildPackage
![nuget](https://img.shields.io/nuget/v/BuildPackage.svg)

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

Edit the packages.config file to indicate that this package is not required to run your app by marking it as a `developmentDependency`.
```xml
<package id="BuildPackage" version="1.0.0" targetFramework="net40" developmentDependency="true" />
<package id="NuGet.CommandLine" version="3.3.0" targetFramework="net40" developmentDependency="true" />
```

That's it! That's all you have to do. The next time you build your project, an extra build step will run `nuget.exe pack` on your project file. The script supports incremental building and cleaning, too!

# Limitations

The `BuildPackage` build target runs after the `AfterBuild` target. All build artifacts in project's `$(OutDir)` are packaged on every build. There are some limitations to this approach.

 - It's not possible to create a single package that contains multiple build configurations.
 - Build artifacts from referenced projects are included in the package.
   - Workaround 1: add a nuspec file and customize its `<files>` and `<dependencies>` sections. Recommended, especially if your package depends on other NuGet packages.
   - Workaround 2: disable "Copy Local" for references that should not be included in the package. Not recommended.

# Advanced Features
 - Organize package contents
 - Enable/Disable BuildPackage
 - Override path to NuGet.exe
 
## Organize Package Contents
You can add a build step that organizes the output directory before building the package.

MSBuild:
```xml
<Target Name="AfterBuild">
	<!-- Copy, move or delete files to create the perfect package -->
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
