# Logman
DSC Resource for importing data collector sets to Performance Monitor using logman.exe

## Installation

The module is available on the PowerShell Gallery, which provides an easy installation & update experience.

**1. Start PowerShell (on Windows 7 - 10)**  

Simply press the Start button and search for "PowerShell". You will likely get two hits:
"Windows PowerShell" and "Windows PowerShell ISE". The first one is a command console while  
the PowerShell ISE also has a script editor. If you're a beginner it might be easier  
to start with the PowerShell ISE, as it provides helpful features such as IntelliSense.  
It also has a script editor, which is useful when building a script which we will do  
in this article.

**2. Allow PowerShell scripts to be executed**  

PowerShell has a feature called "execution policy" which by default is set to "Restricted",  
meaning that no scripts is allowed to run. In the context of this article, I will recommend  
to set the execution policy to "RemoteSigned". This means that you can run scripts locally  
without having to sign it with a digital signature.

Run the following command to configure the execution policy:  
*Set-ExecutionPolicy RemoteSigned*

Make sure you start PowerShell with "Run As Administrator" before running the command.

**3. Install the Logman module**  

The module is available from the PowerShell Gallery, meaning we can install it by simply running the following:  
*Install-Module -Name Logman* 

If this is the first time you run this command, you will be prompted to install NuGet which is being 
 used under the hood to interact with the PowerShell Gallery. Answer Yes when prompted to install 
this prerequisite. Next, you will be warned that the PowerShell Gallery by default is configured  
as an untrusted source. Answer Yes to acknowledge this and install the module.

Now the module is installed and is ready to be used.

If the module is updated at a later point in time, you can get the latest version simply by running Update-Module:
*Update-Module -Name Logman* 