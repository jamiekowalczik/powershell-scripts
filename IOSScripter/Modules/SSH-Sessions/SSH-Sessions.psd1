# Module manifest for module 'SSH-Sessions.psm1'
#
# Created by: Joakim Svendsen
#
# Created on: 2012-04-19
#
@{

# Script module or binary module file associated with this manifest
ModuleToProcess = 'SSH-Sessions.psm1'

# Version number of this module.
ModuleVersion = '1.0.0.4'

# ID used to uniquely identify this module
GUID = ''

# Author of this module
Author = 'Joakim Svendsen'

# Company or vendor of this module
CompanyName = 'Svendsen Tech'

# Copyright statement for this module
Copyright = 'Copyright (c) 2012, Svendsen Tech. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Provides SSH session creation, management and interaction from PowerShell.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '2.0'

# Name of the Windows PowerShell host required by this module
PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = ''

# Processor architecture (None, X86, Amd64, IA64) required by this module
ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('Renci.SshNet.dll')

# Script files (.ps1) that are run in the caller's environment prior to importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in ModuleToProcess
NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @('Renci.SshNet.dll', 'SSH-Sessions.psm1', 'SSH-Sessions.psd1')

# Private data to pass to the module specified in ModuleToProcess
PrivateData = ''

}