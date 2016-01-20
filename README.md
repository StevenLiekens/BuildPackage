# BuildPackage
Sources for the BuildPackage package.

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

That's it! That's all you have to do. The next time you build your project, an extra build step will run `nuget.exe pack` on your project file. The script supports incremental building and cleaning, too!

# Advanced Features
 - Enable/Disable packaging outputs
 - Override path to nuget.exe

## Enabling/Disabling
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

## Custom Tool Path
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