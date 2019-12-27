ConsoleWriteErrorLine("Not yet implemented.")
Exit 1

$json = au3pm_json_load()
$dependencies = $json.Item("dependencies")

For $dependency In $dependencies
    ConsoleWriteLine($dependency&"@"&$dependencies.Item($dependency))
    ;$iLevel = 0
    ;$nestedDependencies = getPackageDependencies($dependency, $dependencies.Item($dependency)) ;FIXME: loop this in while loop? (keep an eye out for circular dependencies)
    ;FIXME: implement, when dependencies exists with nested dependencies (for testing!)
Next
