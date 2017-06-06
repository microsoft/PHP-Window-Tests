# Scripts used to automated PGO builds of PHP

## Introduction

See pgo.php for list of applications and URLs we use to train the instrumented PHP binary.  
Currently, the following applications and versions are used:

  - Drupal 7.8
  - Wordpress 3.2.1
  - Joomla 1.7.2
  - MediaWiki 1.17.0
  - phpBB 3.0.9
  - Symfony 2.0.6 Standard Edition

++Drupal++
Default install with MySQL DB.  Activated several plugins, including forum and blog.  A forum, blog and article post were also created to allow us to profile different types of pages.

++Wordpress++
Default install with MySQL DB.  Created a second test blog entry which will end up being called "wordpress/index.php?p=4".  Also created a comment on this new blog entry.

++Joomla++
Default install with MySQL DB.  Opted to import the sample websites during the installation.  We also access these during the profiling stage (see pgo.php).

++Mediawiki++
Default install with MySQL DB.  Created a second page called "Test_Page".

++phpBB++
Default install with MySQL DB.

++Symfony2++
Configured with MySQL DB.
Installed [Acme Pizza Bundle](https://github.com/beberlei/AcmePizzaBundle)

## Setup

### Build host

#### Structure

- c:\php-sdk - the root SDK directory
- c:\php-sdk\pgo-build - the path to the PGO scripts, this repository checkout
- c:\php-sdk\php\php.exe - PHP binary (any compatible with pgo.php)

#### Setup

- setup WinRM service and add the training VM to the trusted hosts
- create the build environment as described in [https://wiki.php.net/internals/windows/stepbystepbuild](https://wiki.php.net/internals/windows/stepbystepbuild)
- download and put PHP binaries into c:\php-sdk\php

### Remote PGO host

#### Structure
- c:\pgo - Base PGO dir
- c:\pgo\scripts - PGO scripts on the remote side
- c:\pgo\php-nts-bin\php.exe - path to a PHP binary
- c:\apps - application path
- C:\inetpub\wwwroot\pgo\* - IIS virtual host training sites directories

#### Setup

- setup WinRM service and add the build VM to the trusted hosts
- download and put PHP binaries into c:\pgo\php-nts-bin
- go to the control panel turn on IIS feature
- put pgo.php into c:\pgo\scripts
- put pgo-iis.ps1 into c:\pgo\scripts
- start powershell as administrator and run the following command, to allow the PS script execution through winrs
```
PS> Set-ExecutionPolicy Unrestricted
```
- install VS2015 redistributable for both x64 and x86
- copy the corresponding version of pgort140.dll (can be found in your VS2015 dirs) into c:\windows\system32 and c:\windows\syswow64 for x64 and x86 respectively

#### Remote PGO host exports
| Local path | Network share |
|--------|--------|
| c:\pgo | \\\\&lt;pgo host&gt;\pgo       |
| c:\apps\Apache24 | \\\\&lt;pgo host&gt;\Apache24 |



