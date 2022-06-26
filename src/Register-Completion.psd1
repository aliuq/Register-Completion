@{

# Script module or binary module file associated with this manifest.
RootModule = 'Register-Completion.psm1'

# Version number of this module.
ModuleVersion = '0.0.14'

# ID used to uniquely identify this module
GUID = '9628389e-7e96-4fd0-94ed-004bdd2f3f95'

# Author of this module
Author = 'aliuq'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) aliuq. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Easy to register custom completions'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.0'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Convert-JsonToHash', 'Get-CompletionKeys', 'Register-Completion'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = 'cache_all_completion', 'cache_command_list'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{
    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'register','completion','auto-completion'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'v0.0.14: refactor first release'
    }
 }
}

