@REM +-----------------------------------------------------------------------+
@REM | Name: sfcadmin.bat                                                    |
@REM +-----------------------------------------------------------------------+
@REM | Function: Perform baisc SFC administration tasks                      |
@REM | Author: Paul Carvell - Sopra Steria Limited                           |
@REM |                                                                       |
@REM | Prerequisites: Requires Cloud Foundry CLI and Conduit plugin,         |
@REM |                PostgreSQL psql client and GIT for Windows to be       |
@REM |                installed                                              |
@REM +-----------------------------------------------------------------------+
@REM | *** UPDATE VERSION WHEN ADDING HISTORY ****                           |
@REM +-----------------------------------------------------------------------+
@REM | History: 0.1 - 24/10/2019  PRC  Initial version                       |
@REM |          0.2 - 01/11/2019  PRC  Add menus for Prod/PreProd            |
@REM |          1.0 - 04/11/2019  PRC  Initial Release version               |
@REM |          1.1 - 06/11/2019  PRC  Add stuff for Prod step 1             |
@REM |          1.2 - 08/11/2019  PRC  Add stuff for PreProd                 |
@REM |          1.3 - 14/11/2019  PRC  Add options to process all steps      |
@REM |          1.4 - 18/11/2019  PRC  Fix picking wrong var for db name     |
@REM |          1.5 - 19/11/2019  PRC  Add menu for Prod rollback,           |
@REM |                                 yellow highlight for skipped tasks    |
@REM |                                 and Sandbox menu (for certs)          |
@REM |          1.6 - 26/11/2019  PRC  Add Log Capture menu                  |
@REM |          1.7 - 03/12/2109  PRC  Move secret stuff into update vars    |
@REM |                                 and don't allow push to PreProd if    |
@REM |                                 manifest pointing at PROD             |
@REM |          1.8 - 04/12/2109  PRC  Change Rollback menu to Emergency menu|
@REM |                                 with fixed offline page and perform   |
@REM |                                 actions to put this up under one opt  | 
@REM |          1.9 - 05/12/2109  PRC  Give warning that cloud foundry       |
@REM |                                 commands are active in noruncf        |
@REM |                                 version and open browser for smoketest|
@REM |         1.10 - 05/12/2109  PRC  Show size of current log being        |
@REM |                                 captured, allow "E" option from all   |
@REM |                                 menus hidden option except on main and|
@REM |                                 add env variable for cf user id       |
@REM |         1.11 - 10/12/2109  PRC  Remove "login" from app URLS and ask  |
@REM |                                 add database between stop and start   |
@REM |         1.12 - 11/12/2109  PRC  Add appropriate binding message when  |
@REM |                                 offline deployed in Prod menu, update |
@REM |                                 manifest automatically, add google    |
@REM |                                 analytics                             |
@REM |         1.13 - 13/12/2109  PRC  Add GIT checks before deployments     |
@REM |         1.14 - 17/12/2109  PRC  Move google analytics to after update |
@REM |                                 of offline page                       |
@REM |         2.00 - 20/12/2019  PRC  Add initial logging                   |
@REM |         2.01 - 27/12/2019  PRC  Log output of commands run. Also      |
@REM |                                 set variables before AWS secrets      |
@REM |         2.02 - 03/01/2020  PRC  Change ordering of setting of secrets |
@REM |                                 and cf variables as user and password |
@REM |                                 script vars set for AWS update code   |
@REM |         2.03 - 08/01/2020  PRC  Don't log cf setenv commands          |
@REM |         2.04 - 23/01/2020  PRC  Run database scripts                  |
@REM |         2.05 - 24/01/2020  PRC  Use file dialogue for database scripts|
@REM |                                 and set initial location for certs    |
@REM |         2.06 - 29/01/2020  PRC  Create Sandbox options for deploy to  |
@REM |                                 sfcanalysis environment               |
@REM |         2.07 - 03/02/2020  PRC  Include creation of a Github Release  |
@REM |                                 as part of the deployment process     |
@REM |         2.08 - 19/02/2020  PRC  Correct Google Analytics URL and      |
@REM |                                 update AWS Access Keys                |
@REM |         2.09 - 25/02/2020  PRC  Move AWS Access Keys to environment   |
@REM |                                 Variables                             |
@REM |         2.10 - 28/02/2020  PRC  Add extra comments and correct path   |
@REM |                                 for Release Notes                     |
@REM |         2.11 - 04/03/2020  PRC  Fix bug in AWS secret for analysis    |
@REM |                                 deployment (removed key-id in 2.09)   |
@REM +-----------------------------------------------------------------------+
@REM | *** UPDATE VERSION VAR BELOW WHEN ADDING HISTORY ****                 |
@REM +-----------------------------------------------------------------------+
TITLE SFCADMIN

SET version=2.11

Setlocal EnableDelayedExpansion
ECHO OFF

SET redbackground=[41m
SET greenbackground=[42m
SET yellowbackground=[43m
SET bluebackground=[44m
SET cyanbackground=[46m
SET magentabackground=[45m
SET clearbackground=[0m

@REM *************************************************************************
@REM Define backspace (to enable us to have leading spaces in front of prompts
@REM *************************************************************************
for /f %%A in ('"prompt $H&for %%B in (1) do rem"') do set "BS=%%A"

@REM *******************
@REM Clear all variables
@REM *******************

SET cloudfoundryid=
SET currentspace=
SET liveactive=
SET livebinding=
SET preprodcurrentbinding=
SET alternativeactive=
SET activemessage=
SET bindingmessage=
SET preprodbindingmessage=
SET previousactive=
SET nextactive=
SET var=
SET continue=
SET menu_selection=
SET openbrowser=
SET dbpass=
SET dbport=
SET dbhost=
SET dbuser=

SET extraspace=

@REM ******************
@REM Show splash screen
@REM ******************

CLS
ECHO.
ECHO ^+---------------------------------------------------------------------------^+
ECHO ^|                                                                           ^|
ECHO ^| SFCADMIN Utility - Authorised Users only                                  ^|
ECHO ^|                                                                           ^|
ECHO ^| To avoid having to enter values every time, the following environment     ^|
ECHO ^| variables should be set up:                                               ^|
ECHO ^|                                                                           ^|
ECHO ^| sfcliveapp         - the location of the root of your local copy of the   ^|
ECHO ^|                      SopraSteria-SFC Git repository                       ^|
ECHO ^| sfcdbscripts       - the location of the root of your local copy of the   ^|
ECHO ^|                      SFC-DB Git repository                                ^|
ECHO ^| sfcofflineapp      - the location of the root of your local copy of the   ^|
ECHO ^|                      sfcoffline app                                       ^|
ECHO ^| sfcemergencyapp    - the location of the root of your local copy of the   ^|
ECHO ^|                      emergency (fixed text) version of the sfcoffline app ^|
ECHO ^| sfcdevops          - the location of the root of your local copy of the   ^|
ECHO ^|                      SFC-Devops Git repository                            ^|
ECHO ^| sfccerts           - the location of the folder where you have aved the   ^|
ECHO ^|                      Dev and Staging database SSL certificates            ^|
ECHO ^| sfcuserid          - your GovPaaS Cloudfoundry registered User ID (email) ^|
ECHO ^| sfcprodsecretid    - AWS Access Key ID for Prod                           ^|
ECHO ^| sfcprodsecretkey   - AWS Access Key for Prod                              ^|
ECHO ^| sfcpresecretid     - AWS Access Key ID for PreProd                        ^|
ECHO ^| sfcpresecretkey    - AWS Access Keyfor PreProd                            ^|
ECHO ^| sfcstagesecretid   - AWS Access Key ID for Staging                        ^|
ECHO ^| sfcstagesecretkey  - AWS Access Key for Staging                           ^|
ECHO ^|                                                                           ^|
ECHO ^+---------------------------------------------------------------------------^+

@REM ********************************************************************************************
@REM Default test version to true, but if global edit done to remove "Note running" echo in front
@REM of commands then below will get set to false so warning will be shown on each screen
@REM ********************************************************************************************

SET testversion=true
SET testversion=false>nul

IF "!testversion!"=="true" GOTO SKIP_LIVE_WARNING

ECHO.
ECHO !redbackground!WARNING: CLOUD FOUNDRY COMMANDS ACTIVE - THIS IS NOT A TEST VERSION!clearbackground!

:SKIP_LIVE_WARNING

@REM ************************************************************************************************
:ASK_LIVE_APP
@REM ************************************************************************************************

ECHO.

IF "!sfcliveapp!"=="" (
    SET /P sfcliveapp=Enter root location of local copy of live application: 
	ECHO.
)
SET areyousure=N
SET /P areyousure=Location of local copy of live application is !sfcliveapp! - please confirm^? ^(Y/N/Q^): 

IF "!areyousure!" NEQ "Y" (

    IF "!areyousure!"=="Q" (
	    GOTO MENU_QUIT
	)
	
	SET sfcliveapp=
	GOTO  ASK_LIVE_APP
	
)

@REM ************************************************************************************************
:ASK_DB_SCRIPTS
@REM ************************************************************************************************

IF "!sfcdbscripts!"=="" (
    SET /P sfcdbscripts=Enter root location of local copy of database scripts repository: 
	ECHO.
)
SET areyousure=N
SET /P areyousure=Location of local copy of database scripts repository is !sfcdbscripts! - please confirm^? ^(Y/N/Q^): 

IF "!areyousure!" NEQ "Y" (

    IF "!areyousure!"=="Q" (
	    GOTO MENU_QUIT
	)
	
	SET sfcdbscripts=
	GOTO  ASK_LIVE_APP
	
)

@REM ************************************************************************************************
:ASK_OFFLINE_APP
@REM ************************************************************************************************

IF "!sfcofflineapp!"=="" (
    SET /P sfcofflineapp=Enter root location of local copy of offline application: 
	ECHO.
)
SET areyousure=N
SET /P areyousure=Location of local copy of offline application is !sfcofflineapp! - please confirm^? ^(Y/N/Q^): 

IF "!areyousure!" NEQ "Y" (

    IF "!areyousure!"=="Q" (
	    GOTO MENU_QUIT
	)
	
	SET sfcofflineapp=
	GOTO  ASK_OFFLINE_APP
)


@REM ************************************************************************************************
:ASK_EMERGENCY_APP
@REM ************************************************************************************************

IF "!sfcemergencyapp!"=="" (
    SET /P sfcemergencyapp=Enter root location of local copy of emergency offline application: 
	ECHO.
)
SET areyousure=N
SET /P areyousure=Location of local copy of emergency offline application is !sfcemergencyapp!- please confirm^? ^(Y/N/Q^): 

IF "!areyousure!" NEQ "Y" (

    IF "!areyousure!"=="Q" (
	    GOTO MENU_QUIT
	)
	
	SET sfcemergencyapp=
	GOTO  ASK_EMERGENCY_APP
)

@REM ************************************************************************************************
:ASK_DEVOPS
@REM ************************************************************************************************

IF "!sfcdevops!"=="" (
    SET /P sfcdevops=Enter root location of local copy of DevOps folder: 
	ECHO.
)
SET areyousure=N
SET /P areyousure=Location of local copy of DevOps folder is !sfcdevops!- please confirm^? ^(Y/N/Q^): 

IF "!areyousure!" NEQ "Y" (

    IF "!areyousure!"=="Q" (
	    GOTO MENU_QUIT
	)
	
	SET sfcdevops=
	GOTO  ASK_DEVOPS
)

@REM ************************************************************************************************
:ASK_CERTS
@REM ************************************************************************************************

IF "!sfccerts!"=="" (
    SET /P sfccerts=Enter location of certificates folder: 
	ECHO.
)
SET areyousure=N
SET /P areyousure=Location of certificates folder is !sfccerts!- please confirm^? ^(Y/N/Q^): 

IF "!areyousure!" NEQ "Y" (

    IF "!areyousure!"=="Q" (
	    GOTO MENU_QUIT
	)
	
	SET sfccerts=
	GOTO  ASK_CERTS
)

@REM ************************************************************************************************
:ASK_CLOUDFOUNDRY_ID
@REM ************************************************************************************************

IF "!sfcuserid!"=="" (
    ECHO.
    SET /P sfcuserid=Enter your Cloud Foundry Login ID: 
	ECHO.
	SET areyousure=N
	SET /P areyousure=Cloud Foundry ID entered is !sfcuserid!- please confirm correct^? ^(Y/N/Q^): 

    IF "!areyousure!" NEQ "Y" (

        IF "!areyousure!"=="Q" (
	        GOTO MENU_QUIT
	    )
	
	    SET sfcemergencyapp=
	    GOTO  ASK_CLOUDFOUNDRY_ID)
)

ECHO.

@REM *********************
@REM Login to CloudFoundry
@REM *********************

ECHO Connecting to Cloud Foundry with user ID !sfcuserid!.............
ECHO.
cf login -a https://api.cloud.service.gov.uk -u !sfcuserid!
ECHO.

ECHO Changing local directory to !sfcliveapp!
cd !sfcliveapp!
ECHO.

@REM **********************************************************************************************************
@REM Stuff we want to go into the logs is echoed/directed to the devops log. This means it won't be seen on the
@REM screen. To get around this we create a powershell task in the background which lets us tail this. However,
@REM there is a lag so we put is a 2 second pause after sending to the log where mixing echo's to the screen
@REM (which are pretty immediate) with output to the log
@REM **********************************************************************************************************

@REM *******************
@REM Set devops_log_name
@REM *******************

SET cur_yy=%DATE:~8,2%
SET cur_mm=%DATE:~3,2%
SET cur_dd=%DATE:~0,2%
SET thisday=!cur_yy!!cur_mm!!cur_dd!

@REM ********************************************************************
@REM Default to testing log which is in the gitignore for the DevOps repo
@REM ********************************************************************

SET devopslogname=%sfcdevops%\sfcadmin_%USERNAME%_!thisday!_testing.log

IF "!testversion!"=="true" GOTO SKIP_SET_DEVOPS_LOG_LIVE

SET devopslogname=%sfcdevops%\sfcadmin_%USERNAME%_!thisday!.log

:SKIP_SET_DEVOPS_LOG_LIVE

ECHO ==================================================================================================>>!devopslogname!
ECHO Starting SFCADMIN on %DATE% at %TIME%>>!devopslogname!
ECHO ---------------------------------------------->>!devopslogname!
ECHO. >>!devopslogname!

@REM *****************************************************************************
@REM Now remove delete for users - powershell will terminate if the log is deleted
@REM *****************************************************************************

ICACLS !devopslogname! /deny users:(DE)

@REM ***********************************************************************************************
@REM Use powershell in background to tail the DevOps log (so command output can be logged and shown)
@REM ***********************************************************************************************

@REM *********************************
@REM First get running powershell PIDs
@REM *********************************

ECHO Getting existing powershell instances.......
SET "sfcadminpspid="
SET "existingpspids=p"
FOR /f "TOKENS=1" %%a IN ('wmic PROCESS where "Name='powershell.exe'" get ProcessID ^| findstr [0-9]') DO (set "existingpspids=!existingpspids!%%ap")

@REM *******************************
@REM Now start background powershell
@REM *******************************

ECHO Starting powershell background log tail
ECHO.
start /b "SFCADMINPOWERSHELL" powershell -command "Get-Content !devopslogname! -tail 0 -wait"

@REM **************************************************************************
@REM Now get powershell PIDs and work out new PID using previously running PIDs
@REM **************************************************************************

FOR /f "TOKENS=1" %%a in ('wmic PROCESS where "Name='powershell.exe'" get ProcessID ^| findstr [0-9]') do (
if "!existingpspids:p%%ap=zz!"=="%existingpspids%" (set "sfcadminpspid=/PID %%a !sfcadminpspid!")
)

SET /P continue=Press enter to continue: 

@REM ************************************************************************************************
:MAIN_MENU
@REM ************************************************************************************************

CLS

ECHO Synchronising DevOps log updates with central repository at %TIME%
CALL :COMMIT_DEVOPS_LOG

SET h1=
SET h2=
SET h3=
SET h4=
SET h5=
SET h6=
SET h7=
SET h8=
SET h9=
SET h10=
SET h11=
SET h12=
SET h13=
SET h14=

CLS
ECHO Getting app status.......

@REM ***********************
@REM Determine current space
@REM ***********************

@REM **************************************
@REM Get the app info for the current space
@REM **************************************

cf apps >%TEMP%\cfappsoutput.temp

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "space.production" ^| find /v /c ""`) DO (
    SET var=%%F
)
IF "!var!"=="1" (SET currentspace=production
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "space.sandbox" ^| find /v /c ""`) DO (
    SET var=%%F
)
IF "!var!"=="1" (SET currentspace=sandbox
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "space.training" ^| find /v /c ""`) DO (
    SET var=%%F
)
IF "!var!"=="1" (SET currentspace=training
)

@REM ************************************************
@REM If production - determine which instance is live
@REM ************************************************

IF "!currentspace!"=="production" (

    SET liveactive=not set
	SET alternativeactive=unknown
	SET activemessage=^, LIVE ACTIVE: not set
	
    FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatgreen" ^| find /v /c ""`) DO (
	    SET var=%%F
    )

    IF "!var!"=="1" (
	    SET liveactive=sfcuatgreen
		SET alternativeactive=sfcuatblue
		SET activemessage=^, LIVE ACTIVE: !greenbackground!sfcuatgreen!clearbackground!
	)
	
	FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatblue" ^| find /v /c ""`) DO (
	    SET var=%%F
    )
	
    IF "!var!"=="1" (
	    SET liveactive=sfcuatblue
		SET alternativeactive=sfcuatgreen
		SET activemessage=^, LIVE ACTIVE: !bluebackground!sfcuatblue!clearbackground!
	)
	
	FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcoffline" ^| find /v /c ""`) DO (
	    SET var=%%F
    )
	
    IF "!var!"=="1" (
	    SET liveactive=sfcoffline
		SET alternativeactive=unknown
		SET activemessage=^, LIVE ACTIVE: !yellowbackground!sfcoffline!clearbackground!
	)

@REM *************************************************************
@REM Set the next and previous to be used in the Prod/Preprod Menu
@REM *************************************************************
	
	SET previousactive=!liveactive!
    SET nextactive=!alternativeactive!
	
	SET nextbackground=
	SET previousbackground=
	
	IF "!nextactive!"=="sfcuatblue" SET nextbackground=!bluebackground!
	IF "!nextactive!"=="sfcuatgreen" SET nextbackground=!greenbackground!
	IF "!previousactive!"=="sfcuatblue" SET previousbackground=!bluebackground!
	IF "!previousactive!"=="sfcuatgreen" SET previousbackground=!greenbackground!
	
    SET livebinding=unknown
    SET bindingmessage=^, LIVE BINDING: !redbackground!unknown!clearbackground!

@REM ***************************************
@REM Get the binding info for the active app
@REM ***************************************

    cf env !liveactive! >%TEMP%\cfenvoutput.temp

    FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb01" ^| find /v /c ""`) DO (
	    SET var=%%F
    )
	
    IF "!var!"=="1" (
	    SET livebinding=sfcuatdb01
		SET bindingmessage=^, LIVE BINDING: !greenbackground!sfcuatdb01!clearbackground!
	)
	
    FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb02" ^| find /v /c ""`) DO (
	    SET var=%%F
    )
	
    IF "!var!"=="1" (
	    SET livebinding=sfcuatdb02
		SET bindingmessage=^, LIVE BINDING: !redbackground!sfcuatdb02!clearbackground!
	)

)

@REM ******************
@REM Show the main menu
@REM ******************

CLS
ECHO                  !cyanbackground!SKILLS FOR CARE MAIN MENU (version !version!)!clearbackground!
ECHO                  ========================================
ECHO.
ECHO   1 ) Change Space
ECHO   2 ) PREPROD Deployment Tasks
ECHO   3 ) PROD Deployment Tasks
ECHO   4 ) PROD Emergency Tasks
ECHO   5 ) SANDBOX Tasks
ECHO   6 ) Log Capture
ECHO.
ECHO   E ) Deploy Emergency sfcoffline html page
ECHO.
ECHO   0  - exit
ECHO.
ECHO   CURRENT SPACE: !currentspace!!activemessage!!bindingmessage!

IF "!testversion!"=="true" GOTO SKIP_LIVE_WARNING_MAIN

ECHO.
ECHO   !redbackground!WARNING: CLOUD FOUNDRY COMMANDS ACTIVE - THIS IS NOT A TEST VERSION!clearbackground!

:SKIP_LIVE_WARNING_MAIN

ECHO.

SET menu_selection=99
SET camefrommainmenu=false
SET /P menu_selection=.!BS!  Enter selection: 

@REM ***********************
@REM Process the menu choice
@REM ***********************

IF !menu_selection!==1 GOTO CHANGE_SPACE
IF !menu_selection!==2 (

@REM *********************************************
@REM Preprod tasks only valid for production space
@REM *********************************************

    IF "!currentspace!" NEQ "production" (
	
        ECHO.
	    ECHO .!BS!  Option is only valid for production space
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO MAIN_MENU
    )
	
    GOTO PREPROD_MENU
)
IF !menu_selection!==3 (

@REM ******************************************
@REM Prod tasks only valid for production space
@REM ******************************************

    IF "!currentspace!" NEQ "production" (
	
        ECHO.
	    ECHO .!BS!  Option is only valid for production space
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO MAIN_MENU
    )
	
    GOTO PROD_MENU
)
IF !menu_selection!==4 (

@REM ***********************************************
@REM Emergency tasks only valid for production space
@REM ***********************************************

    IF "!currentspace!" NEQ "production" (
	
        ECHO.
	    ECHO .!BS!  Option is only valid for production space
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO MAIN_MENU
    )
	
    GOTO PROD_EMERGENCY_SPLASH
)
IF !menu_selection!==5 (

@REM ******************************************
@REM Prod tasks only valid for production space
@REM ******************************************

    IF "!currentspace!" NEQ "sandbox" (
	
        ECHO.
	    ECHO .!BS!  Option is only valid for sandbox space
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO MAIN_MENU
    )
	
    GOTO SANDBOX_MENU
)
IF !menu_selection!==6 (

@REM *******************************************
@REM Log Capture only valid for production space
@REM *******************************************

    IF "!currentspace!" NEQ "production" (
	
        ECHO.
	    ECHO .!BS!  Option is only valid for production space
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO MAIN_MENU
    )
	
    GOTO LOG_CAPTURE_MENU
)
IF "!menu_selection!"=="E" (
    ECHO ==================================================================================================>>!devopslogname!
	TIMEOUT 2>nul
    ECHO %TIME%: MAIN MENU: E selected>>!devopslogname!
	TIMEOUT 2 >nul

@REM ***********************************************************
@REM Emergency offline html page only valid for production space
@REM ***********************************************************

    SET camefrommenu=MAIN_MENU
    SET camefromspace=!currentspace!
    GOTO DEPLOY_OFFLINE_FOR_EMERGENCY
)
IF !menu_selection!==0 GOTO MENU_QUIT
GOTO MAIN_MENU

@REM ************************************************************************************************
@REM End of MAIN_MENU
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM MAIN_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:CHANGE_SPACE
@REM ************************************************************************************************

@REM *******************
@REM Clear all variables
@REM *******************

SET cloudfoundryid=
SET currentspace=
SET liveactive=
SET livebinding=
SET preprodcurrentbinding=
SET alternativeactive=
SET activemessage=
SET bindingmessage=
SET preprodbindingmessage=
SET previousactive=
SET nextactive=
SET var=
SET continue=
SET menu_selection=
SET openbrowser=
SET dbpass=
SET dbport=
SET dbhost=
SET dbuser=

ECHO.

SET requiredspace=unknown
ECHO   Select a space:
ECHO   1. production
ECHO   2. sandbox
ECHO   3. training
ECHO.

@REM **********************
@REM Allow number selection
@REM **********************

SET /P requiredspace=.!BS!  Space^> 

IF "!requiredspace!"=="1" (
    SET requiredspace=production
)

IF "!requiredspace!"=="2" (
    SET requiredspace=sandbox
)

IF "!requiredspace!"=="3" (
    SET requiredspace=training
)


IF "!requiredspace!" NEQ "production" (
    IF "!requiredspace!" NEQ "sandbox" (
	    IF "!requiredspace!" NEQ "training" (
		    ECHO.
		    ECHO .!BS!  Required space invalid
			ECHO.
			SET /P continue=.!BS!  Press enter to continue:
			GOTO MAIN_MENU
		)
	)
)

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Set space to !requiredspace! - are you sure^? ^(Y/N^): 

IF "!areyousure!" NEQ "Y" (
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO MAIN_MENU
)
			    
ECHO.
cf target -s !requiredspace!
ECHO.

SET /P continue=.!BS!  Press enter to continue:
GOTO MAIN_MENU

@REM ************************************************************************************************
@REM End of CHANGE_SPACE
@REM ************************************************************************************************

@REM *************************************************************************************************
:COMMIT_DEVOPS_LOG
@REM *************************************************************************************************

IF "!testversion!"=="true" GOTO SKIP_DEVOPS_COMMIT

ECHO.
ECHO Updating local DevOps repository...
ECHO.

@REM *************************************************
@REM Just in case sfcdevops not set - cd to TEMP first
@REM *************************************************

cd %TEMP%
cd !sfcdevops!

@REM ************************
@REM Update local DevOps repo
@REM ************************

git pull

@REM ***********************************************************
@REM Commit any outstanding DevOps logs and push to central repo
@REM ***********************************************************

ECHO.
ECHO Pushing local updates to central DevOps repository...
ECHO.

git add *.log
git commit -m "cfadmin DevOps log update on %DATE% at %TIME%"
git push

ECHO.
TIMEOUT 2>nul
cd !sfcliveapp!

:SKIP_DEVOPS_COMMIT

EXIT /b 0

@REM *************************************************************************************************
@REM End of COMMIT_DEVOPS_LOG
@REM *************************************************************************************************

@REM ************************************************************************************************
@REM End of MAIN_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:PREPROD_MENU
@REM ************************************************************************************************

@REM ******************
@REM POWERSHELL command
@REM ******************

SET scriptsdir=!sfcdbscripts!\UAT
SET pwshcmd=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog ; $OpenFileDialog.initialDirectory = $Env:scriptsdir ; $OpenFileDialog.ShowDialog()|out-null; $OpenFileDialog.FileName}"

CLS

ECHO Getting app status.......

@REM **************************************
@REM get the app info for the current space
@REM **************************************

cf apps >%TEMP%\cfappsoutput.temp

@REM ********************************
@REM Determine which instance is live
@REM ********************************

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatgreen" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET liveactive=sfcuatgreen
	SET alternativeactive=sfcuatblue
	SET preprodactivemessage=^, PREPROD: !bluebackground!sfcuatblue!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatblue" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
    SET liveactive=sfcuatblue
	SET alternativeactive=sfcuatgreen
	SET preprodactivemessage=^, PREPROD: !greenbackground!sfcuatgreen!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcoffline" ^| find /v /c ""`) DO (
	SET var=%%F
)

IF "!var!"=="1" (
	SET liveactive=sfcoffline
	SET preprodactivemessage=^, PREPROD: unknown
)

@REM **********************************************
@REM Next and previous were determined in Main Menu
@REM **********************************************

@REM **********************************************************************************
@REM If still unknown then came in with current not set or set to offline - need to ask
@REM **********************************************************************************

IF "!nextactive!"=="unknown" (
	
    ECHO.

	SET /P selectactive=PREPROD not known - enter the current PREPROD application: sfcuatblue or sfcuatgreen:  
	IF "!selectactive!" NEQ "sfcuatblue" (
	    IF "!selectactive!" NEQ "sfcuatgreen" (
		    ECHO.
			ECHO   Required application invalid
		    ECHO.
		    SET /P continue=.!BS!  Press enter to continue: 
		    GOTO MAIN_MENU))
				
	SET nextactive=!selectactive!
		
	IF "!nextactive!"=="sfcuatblue" (
	    SET previousactive=sfcuatgreen
		SET preprodactivemessage=^, PREPROD: !bluebackground!sfcuatblue!clearbackground!
	)
		
	IF "!nextactive!"=="sfcuatgreen" (
	    SET previousactive=sfcuatblue
		SET preprodactivemessage=^, PREPROD: !greenbackground!sfcuatgreen!clearbackground!
		)
)

SET extraspace=
IF "!nextactive!"=="sfcuatblue" SET extraspace= 

SET preprodcurrentbinding=unknown
SET preprodbindingmessage=^, PREPROD BINDING: !redbackground!unknown!clearbackground!

@REM *****************************************
@REM get the binding info for the non-live app
@REM *****************************************

cf env !nextactive! >%TEMP%\cfenvoutput.temp

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb01" ^| find /v /c ""`) DO (
    SET var=%%F
)
	
IF "!var!"=="1" (
    SET preprodcurrentbinding=sfcuatdb01
	SET preprodbindingmessage=^, PREPROD BINDING: !redbackground!sfcuatdb01!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb02" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET preprodcurrentbinding=sfcuatdb02
	SET preprodbindingmessage=^, PREPROD BINDING: !greenbackground!sfcuatdb02!clearbackground!
)

@REM *********************
@REM Show the PreProd menu
@REM *********************

CLS
ECHO                  !cyanbackground!SKILLS FOR CARE PREPROD MENU (version !version!)!clearbackground!
ECHO                  ===========================================
ECHO.
ECHO   !h1!1 !clearbackground!) Do npm install and run build
ECHO   !h2!2 !clearbackground!) Update !nextbackground!!nextactive!!clearbackground! database binding
ECHO   !h3!3 !clearbackground!) Restage !nextbackground!!nextactive!!clearbackground! application
ECHO   !h4!4 !clearbackground!) Set variables for !nextbackground!!nextactive!!clearbackground!
ECHO   !h5!5 !clearbackground!) Update manifest.bluegreen.yml for !nextbackground!!nextactive!!clearbackground! application
ECHO   !h6!6 !clearbackground!) Push application
ECHO   !h7!7 !clearbackground!) Create Draft Release
ECHO.
ECHO   A  - Run options 1-7 (above)
ECHO   P  - Run options 2-6 (above) - Post Prod deployment to bring !nextbackground!!nextactive!!clearbackground! up to same version as !previousbackground!!previousactive!!clearbackground!
ECHO.
ECHO   0  - Exit
ECHO.
ECHO   CURRENT SPACE: !currentspace!!preprodactivemessage!!preprodbindingmessage!

IF "!testversion!"=="true" GOTO SKIP_LIVE_WARNING_PREPROD

ECHO.
ECHO   !redbackground!WARNING: CLOUD FOUNDRY COMMANDS ACTIVE - THIS IS NOT A TEST VERSION!clearbackground!

:SKIP_LIVE_WARNING_PREPROD

ECHO.

SET menu_selection=99
SET pwasselected=N
SET /P menu_selection=.!BS!  Enter selection: 

@REM ***********************
@REM Process the menu choice
@REM ***********************

IF !menu_selection! NEQ 0 (
    ECHO ==================================================================================================>>!devopslogname!
    TIMEOUT 2>nul)

IF !menu_selection!==1 (
    ECHO %TIME%: PREPROD MENU: 1 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO NPM_INSTALL_AND_RUN_BUILD
)
IF !menu_selection!==2 (
    ECHO %TIME%: PREPROD MENU: 2 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO UPDATE_PREPROD_DATABASE_BINDING_FOR_TEST
)
IF !menu_selection!==3 (
    ECHO %TIME%: PREPROD MENU: 3 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO RESTAGE_PREPROD_FOR_TEST
)
IF !menu_selection!==4 (
    ECHO %TIME%: PREPROD MENU: 4 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO SET_VARIABLES_PREPROD
)
IF !menu_selection!==5 (
    ECHO %TIME%: PREPROD MENU: 5 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO UPDATE_MANIFEST
)
IF !menu_selection!==6 (
    ECHO %TIME%: PREPROD MENU: 6 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO PUSH_APPLICATION
)
IF !menu_selection!==7 (
    ECHO %TIME%: PREPROD MENU: 7 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO CREATE_DRAFT_RELEASE
)
IF "!menu_selection!"=="A" (

    SET h1=
    SET h2=
    SET h3=
    SET h4=
    SET h5=
    SET h6=
	SET h7=
	
	ECHO %TIME%: PREPROD MENU: A selected to run all options....>>!devopslogname!
	TIMEOUT 2 >nul

    GOTO NPM_INSTALL_AND_RUN_BUILD

)

IF "!menu_selection!"=="P" (

    SET h1=
    SET h2=
    SET h3=
    SET h4=
    SET h5=
    SET h6=
	
	ECHO %TIME%: PREPROD MENU: P selected to run options 2-6 to bring !nextactive! up to live....>>!devopslogname!
	TIMEOUT 2 >nul

@REM ******************************************************************
@REM Set the option to "A" to automate but skip npm stuff if not needed
@REM ******************************************************************

    SET menu_selection=A

    ECHO.
    SET /p buildonhere=.!BS!  Was this machine used to build the last release pushed to live and is that still available^? ^(Y/N^): 

	IF "!buildonhere!" NEQ "Y" (
	    ECHO.
	    SET /p confirm=.!BS!  Do you want to do npm install and run build^? ^(Y/N^): 
		ECHO.
		IF "!confirm!"=="Y" (
		    ECHO %TIME%: Machine not used to build last release - reverting to all options>>!devopslogname!
			TIMEOUT 2 >nul
			GOTO NPM_INSTALL_AND_RUN_BUILD
		)
		ECHO %TIME%: Machine not used to build last release - abandoned due to user choice>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
		GOTO PREPROD_MENU)

    SET pwasselected=Y
	GOTO UPDATE_PREPROD_DATABASE_BINDING_FOR_TEST
)
IF "!menu_selection!"=="E" (

    ECHO %TIME%: PREPROD MENU: E selected>>!devopslogname!
	TIMEOUT 2 >nul

@REM ***********************************************************
@REM Emergency offline html page only valid for production space
@REM ***********************************************************

    SET camefrommenu=PREPROD_MENU
    SET camefromspace=!currentspace!
    GOTO DEPLOY_OFFLINE_FOR_EMERGENCY
)

IF !menu_selection!==0 GOTO MAIN_MENU
TIMEOUT 2 >nul
CLS
GOTO PREPROD_MENU

@REM ************************************************************************************************
@REM End of PREPROD_MENU
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM PREPROD_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:NPM_INSTALL_AND_RUN_BUILD
@REM ************************************************************************************************

SET h1=!redbackground!

ECHO.
ECHO ----------------------------------------->>!devopslogname!
ECHO %TIME%: Do npm install and run build>>!devopslogname!
ECHO ----------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   Checking GIT status.......

@REM **********************************************
@REM Check if current branch is live and up to date
@REM **********************************************

@REM ***************************************
@REM get the git info for the current branch
@REM ***************************************

git status >%TEMP%\gitstatusout.temp

ECHO.
ECHO GIT status:>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
TYPE %TEMP%\gitstatusout.temp>>!devopslogname!
TIMEOUT 2 >nul

SET currentrepo=notlive
SET currentrepouptodate=notuptodate
SET workingtreeclean=notclean

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "origin/live" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepo=live
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "up.to.date.with" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepouptodate=uptodate
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "nothing.to.commit..working.tree.clean" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET workingtreeclean=clean
)

IF "!currentrepo!" NEQ "live" (
	ECHO.
	ECHO   **************************************************************************
    ECHO   ******!redbackground! Current Branch is not live - please resolve before deploying !clearbackground!******
    ECHO   **************************************************************************
	ECHO.
	ECHO %TIME%: npm install and run build abandoned - current Branch is not live>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO PREPROD_MENU)
	
IF "!currentrepouptodate!" NEQ "uptodate" (
    ECHO.
	ECHO   ********************************************************************************
    ECHO   ******!redbackground! Current Branch is not up to date - please resolve before deploying !clearbackground!******
    ECHO   ********************************************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: npm install and run build abandoned - current Branch is not up to date>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO PREPROD_MENU
    )
	ECHO %TIME%: npm install and run build proceeding but current Branch is not up to date>>!devopslogname!
	TIMEOUT 2 >nul
)
	
IF "!workingtreeclean!" == "notclean" (
    ECHO.
	ECHO   *************************************************
    ECHO   ******!yellowbackground! WARNING - working tree is not clean !clearbackground!******
    ECHO   *************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: npm install and run build abandoned - current Branch is not clean>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO PREPROD_MENU
    )
	ECHO %TIME%: npm install and run build proceeding but current Branch is not clean>>!devopslogname!
	TIMEOUT 2 >nul
)

ECHO.
ECHO   This option will run the following:

ECHO.
ECHO   npm install
ECHO   npm run build

ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Run npm install and build - are you sure^? ^(Y/N^): 
ECHO.
		
IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: npm install and run build abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO PREPROD_MENU)

call npm install>>!devopslogname! 2>&1
call npm run build>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: npm install and run build completed>>!devopslogname!
TIMEOUT 2 >nul

SET h1=!greenbackground!

IF "!menu_selection!"=="A" GOTO UPDATE_PREPROD_DATABASE_BINDING_FOR_TEST

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO PREPROD_MENU

@REM ************************************************************************************************
@REM End of NPM_INSTALL_AND_RUN_BUILD
@REM ************************************************************************************************

@REM ************************************************************************************************
:UPDATE_PREPROD_DATABASE_BINDING_FOR_TEST
@REM ************************************************************************************************

SET h2=!redbackground!

ECHO.
ECHO ------------------------------------------------------------------>>!devopslogname!
ECHO %TIME%: Update database binding for !nextactive!!extraspace! to sfcuatdb02>>!devopslogname!
ECHO ------------------------------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

IF "!preprodcurrentbinding!"=="sfcuatdb02" (
	ECHO %TIME%: Current binding for !nextactive! already sfcuatdb02>>!devopslogname!
	TIMEOUT 2 >nul
	SET h2=!greenbackground!
	
    IF "!menu_selection!"=="A" (
	    SET h3=!yellowbackground!
		GOTO SET_VARIABLES_PREPROD
		)
	
	ECHO.
	SET /P continue=.!BS!  Press enter to continue: 
    GOTO PREPROD_MENU
    
)
	
ECHO   This option will run the following:
ECHO.
	
IF "!preprodcurrentbinding!"=="sfcuatdb01" (
    ECHO   cf unbind-service !nextactive! sfcuatdb01
)
ECHO   cf bind-service !nextactive! sfcuatdb02
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Bind sfcuatdb02 to !nextactive! - are you sure^? ^(Y/N^): 
ECHO.
		
IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Update database binding for !nextactive! to sfcuatdb02 abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO PREPROD_MENU)

IF "!preprodcurrentbinding!"=="sfcuatdb01" (
    cf unbind-service !nextactive! sfcuatdb01>>!devopslogname! 2>&1
)
cf bind-service !nextactive! sfcuatdb02>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO %TIME%: Update database binding for !nextactive! to sfcuatdb02 completed>>!devopslogname!
TIMEOUT 2 >nul

SET h2=!greenbackground!

IF "!menu_selection!"=="A" GOTO RESTAGE_PREPROD_FOR_TEST

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO PREPROD_MENU

@REM ************************************************************************************************
@REM End of UPDATE_PREPROD_DATABASE_BINDING_FOR_TEST
@REM ************************************************************************************************

@REM ************************************************************************************************
:RESTAGE_PREPROD_FOR_TEST
@REM ************************************************************************************************

SET h3=!redbackground!

ECHO.
ECHO -------------------------------------------->>!devopslogname!
ECHO %TIME%: Restage application !extraspace!!nextactive!>>!devopslogname!
ECHO -------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.
ECHO   cf restage !nextactive!
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Restage !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Restage application !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PREPROD_MENU
)

cf restage !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Restage application !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h3=!greenbackground!

IF "!menu_selection!"=="A" GOTO SET_VARIABLES_PREPROD

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PREPROD_MENU

@REM ************************************************************************************************
@REM End of RESTAGE_PREPROD_FOR_TEST
@REM ************************************************************************************************

@REM ************************************************************************************************
:SET_VARIABLES_PREPROD
@REM ************************************************************************************************

SET h4=!redbackground!

ECHO.
ECHO ------------------------------------------>>!devopslogname!
ECHO %TIME%: Set variables for !extraspace!!nextactive!>>!devopslogname!
ECHO ------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul

IF "!sfcpresecretid!"=="" (
    ECHO.
	SET /P sfcpresecretid=.!BS!  Enter AWS Secret ID for PreProd: 
	SET areyousure=N
	SET /P areyousure=.!BS!  AWS Secret ID entered is !sfcpresecretid! - please confirm correct^? ^(Y/N^): 
	IF "!areyousure!" NEQ "Y" (
	    ECHO.
        ECHO %TIME%: Set variables for !nextactive! abandoned - Incorrect AWS Secret ID>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
		GOTO PREPROD_MENU
	)
)

IF "!sfcpresecretkey!"=="" (
    ECHO.
	SET /P sfcpresecretkey=.!BS!  Enter AWS Secret Key for PreProd: 
	SET areyousure=N
	SET /P areyousure=.!BS!  AWS Secret Key entered is !sfcpresecretkey! - please confirm correct^? ^(Y/N^): 
	IF "!areyousure!" NEQ "Y" (
	    ECHO.
        ECHO %TIME%: Set variables for !nextactive! abandoned - Incorrect AWS Secret Key>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
		GOTO PREPROD_MENU
	)
)
	
ECHO.
ECHO   This option will update Secrets Manager and run the following:
ECHO.

ECHO   cf set-env !nextactive! AWS_ACCESS_KEY_ID !sfcpresecretid!
ECHO   cf set-env !nextactive! AWS_SECRET_ACCESS_KEY !sfcpresecretkey!
ECHO   cf set-env !nextactive! DB_NAME ^<dbname^>
ECHO   cf set-env !nextactive! DB_USER ^<dbuser^>
ECHO   cf set-env !nextactive! NODE_ENV preproduction
ECHO   cf set-env !nextactive! SERVER__NAME sfcuat
ECHO   cf set-env !nextactive! DB_POOL 450

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Set variables for !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Set variables for !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PREPROD_MENU
)

ECHO %TIME%: Updating AWS Secrets for PREPROD/API>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
ECHO   ********************************************************************************
ECHO   ******!redbackground! Please update AWS variable for PREPROD/API via AWS Secrets Manager !clearbackground!******
ECHO   ********************************************************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open AWS Secrets Manager ^(will open in a new window^)^? (Y/N): 

IF "!openbrowser!"=="Y" (
    start https://eu-west-1.console.aws.amazon.com/secretsmanager/home?region=eu-west-1#/secret?name=preprod%%2Fapi
)

ECHO.
ECHO   Update the following:
ECHO.

@REM **********************************************
@REM Variables will have changed due to the restage
@REM **********************************************

cf env !nextactive! >%TEMP%\cfenvoutput.temp

@REM ************
@REM SHOW DB_HOST
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "host" %TEMP%\cfenvoutput.temp`) DO (
    SET dbhost=%%F
	ECHO !dbhost:~1,-2!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_HOST=!dbhost:~1,-2!
)

@REM ************
@REM SHOW DB_NAME
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "name" %TEMP%\cfenvoutput.temp ^|findstr "rdsbroker"`) DO (
    SET dbname=%%F
	ECHO !dbname:~1,-2!|clip
	SET areyousure=N
    SET /P areyousure=.!BS!  DB_NAME=!dbname:~1,-2!
    SET dbname=!dbname:~1,-2!
)

@REM ***********
@REM SET DB_USER
@REM ***********

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "username" %TEMP%\cfenvoutput.temp`) DO (
    SET dbuser=%%F
	ECHO !dbuser:~1,-1!|clip
	SET areyousure=N
    SET /P areyousure=.!BS!  DB_USER=!dbuser:~1,-1!
	SET dbuser=!dbuser:~1,-1!
)

@REM ************
@REM SHOW DB_PASS
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "password.:" %TEMP%\cfenvoutput.temp`) DO (
    SET dbpass=%%F
	ECHO !dbpass:~1,-2!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_PASS=!dbpass:~1,-2!
)

@REM ************
@REM SHOW DB_PORT
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "port.:" %TEMP%\cfenvoutput.temp`) DO (
    SET dbport=%%F
	ECHO !dbport:~0,-1!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_PORT=!dbport:~0,-1!
)

ECHO.
ECHO %TIME%: Updating cf variables for !extraspace!!nextactive!>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
cf set-env !nextactive! AWS_ACCESS_KEY_ID !sfcpresecretid!
cf set-env !nextactive! AWS_SECRET_ACCESS_KEY !sfcpresecretkey!
cf set-env !nextactive! DB_NAME !dbname!
cf set-env !nextactive! DB_USER !dbuser!
cf set-env !nextactive! NODE_ENV preproduction
cf set-env !nextactive! SERVER__NAME sfcuat
cf set-env !nextactive! DB_POOL 450

ECHO.
ECHO %TIME%: Set variables for !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h4=!greenbackground!

IF "!menu_selection!"=="A" GOTO UPDATE_MANIFEST

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO PREPROD_MENU

@REM ************************************************************************************************
@REM End of SET_VARIABLES_PREPROD
@REM ************************************************************************************************

@REM ************************************************************************************************
:UPDATE_MANIFEST
@REM ************************************************************************************************

SET h5=!redbackground!

ECHO.
ECHO ----------------------------------------------------------->>!devopslogname!
ECHO %TIME%: Update manifest.bluegreen.yml with !extraspace!!nextactive!>>!devopslogname!
ECHO ----------------------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul

ECHO.
ECHO   Checking GIT status.......

@REM **********************************************
@REM Check if current branch is live and up to date
@REM **********************************************

@REM ***************************************
@REM get the git info for the current branch
@REM ***************************************

git status >%TEMP%\gitstatusout.temp

ECHO.
ECHO GIT status:>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
TYPE %TEMP%\gitstatusout.temp>>!devopslogname!
TIMEOUT 2 >nul

SET currentrepo=notlive
SET currentrepouptodate=notuptodate
SET workingtreeclean=notclean

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "origin/live" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepo=live
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "up.to.date.with" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepouptodate=uptodate
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "nothing.to.commit..working.tree.clean" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET workingtreeclean=clean
)

IF "!currentrepo!" NEQ "live" (
	ECHO.
	ECHO   *************************************************************************
    ECHO   ******!redbackground! Current Branch is not live - please resolve before updating !clearbackground!******
    ECHO   *************************************************************************
	ECHO.
    ECHO %TIME%: Update manifest.bluegreen.yml with !nextactive! abandoned - current Branch is not live>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO PREPROD_MENU)
	
IF "!currentrepouptodate!" NEQ "uptodate" (
    ECHO.
	ECHO   *******************************************************************************
    ECHO   ******!redbackground! Current Branch is not up to date - please resolve before updating !clearbackground!******
    ECHO   *******************************************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: Update manifest.bluegreen.yml with !nextactive! abandoned - current Branch is not up to date>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO PREPROD_MENU
    )
	ECHO %TIME%: Update manifest.bluegreen.yml with !nextactive! proceeding but current Branch is not up to date>>!devopslogname!
    TIMEOUT 2 >nul
)
	
IF "!workingtreeclean!" == "notclean" (
    ECHO.
	ECHO   *************************************************
    ECHO   ******!yellowbackground! WARNING - working tree is not clean !clearbackground!******
    ECHO   *************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: Update manifest.bluegreen.yml with !nextactive! abandoned - current Branch is not clean>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO PREPROD_MENU
    )
	ECHO %TIME%: Update manifest.bluegreen.yml with !nextactive! proceeding but current Branch is not clean>>!devopslogname!
	TIMEOUT 2 >nul
)

SET mnpwshcmd=powershell -noprofile -command "(Get-Content 'manifest.bluegreen.yml') | foreach {$_ -replace 'name: .+$', 'name: %nextactive%'} | Set-Content 'manifest.bluegreen.yml'"

ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Update manifest.bluegreen.yml with !nextactive!^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Update manifest.bluegreen.yml with !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PREPROD_MENU
)

@REM ***************
@REM Update manifest
@REM ***************

!mnpwshcmd!

SET areyousure=N
SET /P areyousure=.!BS!  Check manifest.bluegreen.yml ^(should show !nextactive! - opens in a new window^)^? ^(Y/N^): 
ECHO.

IF "!areyousure!"=="Y" notepad manifest.bluegreen.yml

@REM ECHO   *****************************************************************

ECHO %TIME%: Update manifest.bluegreen.yml with !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h5=!greenbackground!

IF "!menu_selection!"=="A" GOTO PUSH_APPLICATION

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PREPROD_MENU

@REM ************************************************************************************************
@REM End of UPDATE_MANIFEST
@REM ************************************************************************************************

@REM ************************************************************************************************
:PUSH_APPLICATION
@REM ************************************************************************************************

SET h6=!redbackground!

ECHO.
ECHO -------------------------------------------->>!devopslogname!
ECHO %TIME%: Push application to !extraspace!!nextactive!>>!devopslogname!
ECHO -------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   Checking GIT status.......

@REM **********************************************
@REM Check if current branch is live and up to date
@REM **********************************************

@REM ***************************************
@REM get the git info for the current branch
@REM ***************************************

git status >%TEMP%\gitstatusout.temp

ECHO.
ECHO GIT status:>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
TYPE %TEMP%\gitstatusout.temp>>!devopslogname!
TIMEOUT 2 >nul

SET currentrepo=notlive
SET currentrepouptodate=notuptodate
SET workingtreeclean=notclean

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "origin/live" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepo=live
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "up.to.date.with" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepouptodate=uptodate
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "nothing.to.commit..working.tree.clean" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET workingtreeclean=clean
)

IF "!currentrepo!" NEQ "live" (
	ECHO.
	ECHO   *************************************************************************
    ECHO   ******!redbackground! Current Branch is not live - please resolve before updating !clearbackground!******
    ECHO   *************************************************************************
	ECHO.
    ECHO %TIME%: Push application to !nextactive! abandoned - current branch is not live>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO PREPROD_MENU)
	
IF "!currentrepouptodate!" NEQ "uptodate" (
    ECHO.
	ECHO   *******************************************************************************
    ECHO   ******!redbackground! Current Branch is not up to date - please resolve before updating !clearbackground!******
    ECHO   *******************************************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: Push application to !nextactive! abandoned abandoned - current Branch is not up to date>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO PREPROD_MENU
    )
	ECHO %TIME%: Push application to !nextactive! proceeding but current Branch is not up to date>>!devopslogname!
	TIMEOUT 2 >nul
)
	
IF "!workingtreeclean!" == "notclean" (
    ECHO.
	ECHO   *************************************************
    ECHO   ******!yellowbackground! WARNING - working tree is not clean !clearbackground!******
    ECHO   *************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: Push application to !nextactive! abandoned - current Branch is not clean>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO PREPROD_MENU
    )
	ECHO %TIME%: Push application to !nextactive! proceeding but current Branch is not clean>>!devopslogname!
	TIMEOUT 2 >nul
)

ECHO.
SET manifestpointsto=notvalid

FOR /F "tokens=* USEBACKQ" %%F IN (`type manifest.bluegreen.yml ^|findstr "name:" ^|findstr "sfcuatgreen" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET manifestpointsto=sfcuatgreen
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type manifest.bluegreen.yml ^|findstr "name:" ^|findstr "sfcuatblue" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET manifestpointsto=sfcuatblue
)

IF "!manifestpointsto!"=="notvalid" (

    ECHO %TIME%: Push application to !nextactive! not allowed: manifest.bluegreeen.yml DOES NOT point to a valid app instance>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	ECHO   ******************************************************************************************************************
	ECHO   ******!redbackground! cf push not allowed: manifest.bluegreeen.yml DOES NOT point to a valid app instance - please correct !clearbackground!******
	ECHO   ******************************************************************************************************************
	ECHO.
	SET /P continue=.!BS!  Press enter to continue: 
    GOTO PREPROD_MENU
)

IF "!manifestpointsto!"=="!liveactive!" (

    SET extraspace=
	SET prevextraspace=
    IF "!liveactive!"=="sfcuatblue" SET extraspace= 
	IF "!previousactive!"=="sfcuatblue" SET prevextraspace= 
	
	ECHO %TIME%: Push application to !nextactive! not allowed: manifest.bluegreeen.yml is pointing to LIVE ^(!liveactive!^)>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	ECHO   *************************************************************************************************************
	ECHO   ******!redbackground! cf push not allowed: manifest.bluegreeen.yml is pointing to LIVE ^(!liveactive!^) - please correct !extraspace!!clearbackground!******
	ECHO   *************************************************************************************************************
	ECHO.
	SET /P continue=.!BS!  Press enter to continue: 
    GOTO PREPROD_MENU
)

ECHO   This option will run the following:
ECHO.

ECHO   cf push -f manifest.bluegreen.yml
ECHO.

ECHO Latest commit:>>!devopslogname!
ECHO. >>!devopslogname!
git log -n 1 --graph>>!devopslogname!
ECHO. >>!devopslogname!
TIMEOUT 2 >nul

SET areyousure=N
SET /P areyousure=.!BS!  Push application - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Push application to !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PREPROD_MENU
)

ECHO %TIME%: Checking if database patches to be applied to sfcuatdb02>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Are there database patches to deploy^? ^(Y/N^): 
ECHO.
IF "!areyousure!"=="Y" (
    cd !sfcdbscripts!\UAT
	git status >%TEMP%\gitstatusout.temp
    ECHO Database script status:
    ECHO.
    TYPE %TEMP%\gitstatusout.temp
	ECHO.
	
	SET dbscriptsuptodate=notuptodate
	FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "up.to.date.with" ^| find /v /c ""`) DO (
    SET var=%%F
	)
	
	IF "!var!"=="1" (
	SET dbscriptsuptodate=uptodate
	)
	
	IF "!dbscriptsuptodate!"=="notuptodate" (
		ECHO   *************************************************
		ECHO   ******!yellowbackground! WARNING - DB scripts not up-to-date !clearbackground!******
		ECHO   *************************************************
		ECHO.
	    SET areyousure=N
	    SET /P areyousure=.!BS!  Please pull latest scripts from Git Hub - press enter to continue:
		ECHO.
		)
		
REM ************************************************************************************************
:RUN_DB_SCRIPT_PREPROD
REM ************************************************************************************************

	ECHO   Select database script...
	ECHO.
	SET scriptname=
	
@REM ****************************************************************
@REM Execute powershell command and get result in scriptname variable
@REM ****************************************************************

    FOR /f "delims=" %%I IN ('%pwshcmd%') DO SET scriptname=%%I
	
	IF "!scriptname!"=="" (
	    ECHO   ********************************
		ECHO   ******!yellowbackground! No script selected !clearbackground!******
		ECHO   ********************************
		ECHO.
	)
	IF "!scriptname!" NEQ "" (
	    ECHO Script selected ^(below^): !scriptname!
		ECHO ----------------------------------------------------------------------------------------------!redbackground!
		type !scriptname!
		ECHO.
		ECHO !clearbackground!----------------------------------------------------------------------------------------------
		ECHO.
		SET areyousure=N
		SET /P areyousure=.!BS!  Run !scriptname! - are you sure^? ^(Y/N^): 
		ECHO.
		IF "!areyousure!"=="Y" (
		    ECHO %TIME%: Running database script !scriptname!>>!devopslogname!
			TIMEOUT 2 >nul
			ECHO.
			ECHO ---------------------------------------------------------->>!devopslogname!
			ECHO Script: !scriptname!>>!devopslogname!
			ECHO ---------------------------------------------------------->>!devopslogname!
			type !scriptname!>>!devopslogname!
			ECHO. >>!devopslogname!
			TIMEOUT 2 >nul
			ECHO ---------------------------------------------------------->>!devopslogname!
			ECHO Script output>>!devopslogname!
			ECHO ---------------------------------------------------------->>!devopslogname!
			cf conduit sfcuatdb02 --app-name sfcadmin_sfcuatdb02 -- psql < !scriptname!>>!devopslogname! 2>&1
			ECHO ---------------------------------------------------------->>!devopslogname!
			TIMEOUT 2 >nul
			ECHO.
			ECHO %TIME%: Completed !scriptname!>>!devopslogname!
			TIMEOUT 2 >nul
			ECHO.
		)
	)
	SET runmore=N
	SET /P runmore=.!BS!  Run another script^? ^(Y/N^): 
	ECHO.
	IF "!runmore!"=="Y" GOTO RUN_DB_SCRIPT_PREPROD
	cd !sfcliveapp!
	ECHO %TIME%: Database patches applied to sfcuatdb02>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
)

cf push -f manifest.bluegreen.yml>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   ******************************************************************************
ECHO   ******!redbackground! Please smoketest and notify client that the app is ready to test !clearbackground!******
ECHO   ******************************************************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open !nextactive! app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://!nextactive!.cloudapps.digital/
)

ECHO %TIME%: Push application to !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET h6=!greenbackground!

IF "!menu_selection!"=="A" (
	IF "!pwasselected!"=="Y" (
	    SET completedmessage=Options 2-6 completed
		ECHO %TIME%: PREPROD MENU: !completedmessage!>>!devopslogname!
	    TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
	    GOTO PREPROD_MENU
	)
	GOTO CREATE_DRAFT_RELEASE
)

SET /P continue=.!BS!  Press enter to continue:
GOTO PREPROD_MENU

@REM ************************************************************************************************
@REM End of PUSH_APPLICATION
@REM ************************************************************************************************

@REM ************************************************************************************************
:CREATE_DRAFT_RELEASE
@REM ************************************************************************************************

SET h7=!redbackground!

ECHO.
ECHO ------------------------------------------->>!devopslogname!
ECHO %TIME%: Create Draft Release on Github>>!devopslogname!
ECHO ------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul

ECHO.
SET releaseversion=
SET /P releaseversion=.!BS!  Enter release version - ^<sprint^>.^<week^>[_hotfix^<n^>] ^(e.g. 1.1 or 1.1_hotfix1^): 
ECHO.

ECHO   This option will create release v1_!releaseversion! against the live code branch on Github 
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Create release v1_!releaseversion! against the live code branch on Github (opens in a new window - Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Publish Release to Github abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PREPROD_MENU
)

START https://github.com/NMDSdevopsServiceAdm/SopraSteria-SFC/releases/new/

ECHO v1_!releaseversion!|clip
SET areyousure=N
SET /p areyousure=.!BS!  Release Tag: v1_!releaseversion!
SET areyousure=N
ECHO live|clip
SET /p areyousure=.!BS!  Select !greenbackground!LIVE!clearbackground! code branch
ECHO SKILLSFORCARE Version 1 Sprint !releaseversion!|clip
SET areyousure=N
SET /p areyousure=.!BS!  Release Title: SKILLSFORCARE Version 1 Sprint !releaseversion!
ECHO Please see the attached release note for details|clip
SET areyousure=N
SET /p areyousure=.!BS!  Release Description: Please see the attached release note for details
ECHO   Drag and drop the release note into the Release Description in Github and then click on the Github Save draft button
TIMEOUT 3 >nul
start file://!sfcdevops!\Release-Documents
ECHO.

ECHO %TIME%: Publish Release !releaseversion! completed>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET h7=!greenbackground!

IF "!menu_selection!"=="A" (

    SET completedmessage=Options 1-7 completed
	ECHO %TIME%: PREPROD MENU: !completedmessage!>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
)

SET /P continue=.!BS!  Press enter to continue:
GOTO PREPROD_MENU

@REM ************************************************************************************************
@REM End of CREATE_DRAFT_RELEASE
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM End of PREPROD_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:PROD_MENU
@REM ************************************************************************************************

@REM ******************
@REM POWERSHELL command
@REM ******************

SET scriptsdir=!sfcdbscripts!\UAT
SET pwshcmd=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog ; $OpenFileDialog.initialDirectory = $Env:scriptsdir ; $OpenFileDialog.ShowDialog()|out-null; $OpenFileDialog.FileName}"

CLS

ECHO Getting app status.......

@REM **************************************
@REM get the app info for the current space
@REM **************************************

cf apps >%TEMP%\cfappsoutput.temp

@REM ********************************
@REM Determine which instance is live
@REM ********************************

SET liveactive=not set
SET activemessage=^, LIVE ACTIVE: !redbackground!not set!clearbackground!

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatgreen" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET liveactive=sfcuatgreen
	SET alternativeactive=sfcuatblue
	SET activemessage=^, LIVE ACTIVE: !greenbackground!sfcuatgreen!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatblue" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
    SET liveactive=sfcuatblue
	SET alternativeactive=sfcuatgreen
	SET activemessage=^, LIVE ACTIVE: !bluebackground!sfcuatblue!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcoffline" ^| find /v /c ""`) DO (
	SET var=%%F
)

IF "!var!"=="1" (
	SET liveactive=sfcoffline
	SET activemessage=^, LIVE ACTIVE: !yellowbackground!sfcoffline!clearbackground!
)

@REM **********************************************
@REM Next and previous were determined in Main Menu
@REM **********************************************

@REM **********************************************************************************
@REM If still unknown then came in with current not set or set to offline - need to ask
@REM **********************************************************************************

IF "!nextactive!"=="unknown" (
	
    ECHO.
	SET /P selectactive=PREPROD not known - enter the application going live: sfcuatblue or sfcuatgreen: 
	IF "!selectactive!" NEQ "sfcuatblue" (
	    IF "!selectactive!" NEQ "sfcuatgreen" (
		    ECHO.
			ECHO   Required application invalid
		    ECHO.
		    SET /P continue=.!BS!  Press enter to continue: 
		    GOTO MAIN_MENU))
				
	SET nextactive=!selectactive!
		
	IF "!nextactive!"=="sfcuatblue" (
	    SET previousactive=sfcuatgreen
		SET nextbackground=!bluebackground!
		SET previousbackground=!greenbackground!
	)
		
	IF "!nextactive!"=="sfcuatgreen" (
	    SET previousactive=sfcuatblue
		SET nextbackground=!greenbackground!
		SET previousbackground=!bluebackground!
	)
)

SET extraspace=
IF "!nextactive!"=="sfcuatblue" SET extraspace= 

SET livebinding=unknown
SET bindingmessage=^, LIVE BINDING: !redbackground!unknown!clearbackground!

@REM ***************************************
@REM get the binding info for the active app
@REM ***************************************

cf env !previousactive! >%TEMP%\cfenvoutput.temp

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb01" ^| find /v /c ""`) DO (
    SET var=%%F
)
	
IF "!var!"=="1" (
    SET livebinding=sfcuatdb01
	SET bindingmessage=^, LIVE BINDING: !greenbackground!sfcuatdb01!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb02" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET livebinding=sfcuatdb02
	SET bindingmessage=^, LIVE BINDING: !redbackground!sfcuatdb02!clearbackground!
)

IF "!liveactive!"=="sfcoffline" SET bindingmessage=^, LIVE BINDING: !yellowbackground!not applicable!clearbackground!

SET preprodcurrentbinding=unknown
SET preprodbindingmessage=PREPROD BINDING: !redbackground!unknown!clearbackground!

@REM *****************************************
@REM get the binding info for the non-live app
@REM *****************************************

cf env !nextactive! >%TEMP%\cfenvoutput.temp

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb01" ^| find /v /c ""`) DO (
    SET var=%%F
)
	
IF "!var!"=="1" (
    SET preprodcurrentbinding=sfcuatdb01
	SET preprodbindingmessage=PREPROD BINDING: !greenbackground!sfcuatdb01!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb02" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET preprodcurrentbinding=sfcuatdb02
	SET preprodbindingmessage=PREPROD BINDING: !redbackground!sfcuatdb02!clearbackground!
)

@REM ******************
@REM Show the Prod menu
@REM ******************

CLS
ECHO                  !cyanbackground!SKILLS FOR CARE PROD MENU (version !version!)!clearbackground!
ECHO                  ========================================
ECHO.
ECHO   Step1 - Pre-deployment Preparation
ECHO.
ECHO   !h1!1 !clearbackground!) Update !nextbackground!!nextactive!!clearbackground! database binding
ECHO   !h2!2 !clearbackground!) Restage !nextbackground!!nextactive!!clearbackground! application ^(i^)
ECHO   !h3!3 !clearbackground!) Set variables for !nextbackground!!nextactive!!clearbackground!
ECHO   !h4!4 !clearbackground!) Restage !nextbackground!!nextactive!!clearbackground! application ^(ii^)
ECHO   !h5!5 !clearbackground!) Stop !nextbackground!!nextactive!!clearbackground!
ECHO.
ECHO   S1 - Run options 1-5 (above)
ECHO.
ECHO   !preprodbindingmessage!
ECHO.
ECHO   Step2 - Deployment
ECHO.
ECHO   !h6!6 !clearbackground!) Update sfcoffline html page - date and time
ECHO   !h7!7 !clearbackground!) Check active users via Google Analytics
ECHO   !h8!8 !clearbackground!) Push sfcoffline application
ECHO   !h9!9 !clearbackground!) Switch LIVE Route to sfcoffline
ECHO   !h10!10!clearbackground!) Stop !previousbackground!!previousactive!!clearbackground! and start !nextbackground!!nextactive!!clearbackground!
ECHO   !h11!11!clearbackground!) Switch LIVE Route to !nextbackground!!nextactive!!clearbackground!
ECHO   !h12!12!clearbackground!) Stop Offline
ECHO   !h13!13!clearbackground!) Remove URL
ECHO   !h14!14!clearbackground!) Publish Release
ECHO.
ECHO   S2 - Run options 6-14 (above)
ECHO.
ECHO   0  - Exit
ECHO.
ECHO   CURRENT SPACE: !currentspace!!activemessage!!bindingmessage!

IF "!testversion!"=="true" GOTO SKIP_LIVE_WARNING_PROD

ECHO.
ECHO   !redbackground!WARNING: CLOUD FOUNDRY COMMANDS ACTIVE - THIS IS NOT A TEST VERSION!clearbackground!

:SKIP_LIVE_WARNING_PROD

ECHO.

SET menu_selection=99
SET /P menu_selection=.!BS!  Enter selection: 

@REM ***********************
@REM Process the menu choice
@REM ***********************

IF !menu_selection! NEQ 0 (
    ECHO ==================================================================================================>>!devopslogname!
    TIMEOUT 2>nul)

IF !menu_selection!==1 (
    ECHO %TIME%: PROD MENU: 1 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO UPDATE_PREPROD_DATABASE_BINDING_FOR_LIVE
)
IF !menu_selection!==2 (
    ECHO %TIME%: PROD MENU: 2 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO RESTAGE_PREPROD_FOR_LIVE_I
)
IF !menu_selection!==3 (
    ECHO %TIME%: PROD MENU: 3 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO SET_VARIABLES_PROD
)
IF !menu_selection!==4 (
    ECHO %TIME%: PROD MENU: 4 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO RESTAGE_PREPROD_FOR_LIVE_II
)
IF !menu_selection!==5 (
    ECHO %TIME%: PROD MENU: 5 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO STOP_PREPROD
)
IF !menu_selection!==6 (
    ECHO %TIME%: PROD MENU: 6 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO UPDATE_OFFLINE_DATETIME
)
IF !menu_selection!==7 (
    ECHO %TIME%: PROD MENU: 7 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO CHECK_ANALYTICS
)
IF !menu_selection!==8 (
    ECHO %TIME%: PROD MENU: 8 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO PUSH_OFFLINE_APPLICATION
)
IF !menu_selection!==9 (
    ECHO %TIME%: PROD MENU: 9 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO SWITCH_LIVE_ROUTE_TO_OFFLINE
)
IF !menu_selection!==10 (
    ECHO %TIME%: PROD MENU: 10 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO STOP_LIVE
)
IF !menu_selection!==11 (
    ECHO %TIME%: PROD MENU: 11 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO SWITCH_ROUTE_TO_LIVE
)
IF !menu_selection!==12 (
    ECHO %TIME%: PROD MENU: 12 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO STOP_OFFLINE
)
IF !menu_selection!==13 (
    ECHO %TIME%: PROD MENU: 13 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO REMOVE_URL
)
IF !menu_selection!==14 (
    ECHO %TIME%: PROD MENU: 14 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO PUBLISH_RELEASE
)
IF "!menu_selection!"=="S1" (

    SET h1=
    SET h2=
    SET h3=
    SET h4=
    SET h5=
	
    ECHO %TIME%: PROD MENU: S1 selected to run options 1-5....>>!devopslogname!
	TIMEOUT 2 >nul

    GOTO UPDATE_PREPROD_DATABASE_BINDING_FOR_LIVE

)
IF "!menu_selection!"=="S2" (

    SET h6=
    SET h7=
    SET h8=
    SET h9=
    SET h10=
    SET h11=
	SET h12=
	SET h13=
	SET h14=
	
	ECHO %TIME%: PROD MENU: S2 selected to run options 6-14....>>!devopslogname!
	TIMEOUT 2 >nul

    GOTO UPDATE_OFFLINE_DATETIME

)
IF "!menu_selection!"=="E" (

    ECHO %TIME%: PROD MENU: E selected>>!devopslogname!
	TIMEOUT 2 >nul

@REM ***********************************************************
@REM Emergency offline html page only valid for production space
@REM ***********************************************************

    SET camefrommenu=PROD_MENU
    SET camefromspace=!currentspace!
    GOTO DEPLOY_OFFLINE_FOR_EMERGENCY
)

IF !menu_selection!==0 GOTO MAIN_MENU
TIMEOUT 2 >nul
CLS
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of PROD_MENU
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM PROD_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:UPDATE_PREPROD_DATABASE_BINDING_FOR_LIVE
@REM ************************************************************************************************

SET h1=!redbackground!

ECHO.
ECHO ------------------------------------------------------------------>>!devopslogname!
ECHO %TIME%: Update database binding for !extraspace!!nextactive! to sfcuatdb01>>!devopslogname!
ECHO ------------------------------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET areyousure=N
SET /p areyousure=.!BS!  Has the Release been deployed to !nextactive! and signed-off for LIVE deployment^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Update database binding for !nextactive! to sfcuatdb01 abandoned - either Release not deployed to !nextactive! or not signed off>>!devopslogname!
    TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO PROD_MENU)

IF "!preprodcurrentbinding!"=="sfcuatdb01" (
    ECHO   Current binding already sfcuatdb01
	ECHO %TIME%: Current binding for !nextactive! already sfcuatdb01>>!devopslogname!
	TIMEOUT 2 >nul
	SET h1=!greenbackground!
	ECHO.
	
	IF "!menu_selection!"=="S1" (
	    SET h2=!yellowbackground!
		GOTO SET_VARIABLES_PROD
		)
	
	SET /P continue=.!BS!  Press enter to continue: 
    GOTO PROD_MENU
    
)
	
ECHO   This option will run the following:
ECHO.
	
IF "!preprodcurrentbinding!"=="sfcuatdb02" (
    ECHO   cf unbind-service !nextactive! sfcuatdb02
)
ECHO   cf bind-service !nextactive! sfcuatdb01
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Bind sfcuatdb01 to !nextactive! - are you sure^? ^(Y/N^): 
ECHO.
		
IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Update database for !nextactive! to sfcuatdb01 abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO PROD_MENU)

IF "!preprodcurrentbinding!"=="sfcuatdb02" (
    cf unbind-service !nextactive! sfcuatdb02>>!devopslogname! 2>&1
)
cf bind-service !nextactive! sfcuatdb01>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Update database binding for !nextactive! to sfcuatdb01 completed>>!devopslogname!
TIMEOUT 2 >nul

SET h1=!greenbackground!

IF "!menu_selection!"=="S1" GOTO RESTAGE_PREPROD_FOR_LIVE_I

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of UPDATE_PREPROD_DATABASE_BINDING_FOT_LIVE
@REM ************************************************************************************************

@REM ************************************************************************************************
:RESTAGE_PREPROD_FOR_LIVE_I
@REM ************************************************************************************************

SET h2=!redbackground!

ECHO.
ECHO Restage application
ECHO -------------------------------------------->>!devopslogname!
ECHO %TIME%: Restage application !extraspace!!nextactive!>>!devopslogname!
ECHO -------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul

ECHO.
ECHO   This option will run the following:
ECHO.
ECHO   cf restage !nextactive!
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Restage !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Restage application !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cf restage !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Restage application !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h2=!greenbackground!

IF "!menu_selection!"=="S1" GOTO SET_VARIABLES_PROD

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of RESTAGE_PREPROD_FOR_LIVE_I
@REM ************************************************************************************************

@REM ************************************************************************************************
:SET_VARIABLES_PROD
@REM ************************************************************************************************

SET h3=!redbackground!

ECHO.
ECHO ------------------------------------------>>!devopslogname!
ECHO %TIME%: Set variables for !extraspace!!nextactive!>>!devopslogname!
ECHO ------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul

IF "!sfcprodsecretid!"=="" (
    ECHO.
	SET /P sfcprodsecretid=.!BS!  Enter AWS Secret ID for Prod: 
	SET areyousure=N
	SET /P areyousure=.!BS!  AWS Secret ID entered is !sfcprodsecretid! - please confirm correct^? ^(Y/N^): 
	IF "!areyousure!" NEQ "Y" (
	    ECHO.
        ECHO %TIME%: Set variables for !nextactive! abandoned - Incorrect AWS Secret ID>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
		GOTO PROD_MENU
	)
)

IF "!sfcprodsecretkey!"=="" (
    ECHO.
	SET /P sfcprodsecretkey=.!BS!  Enter AWS Secret Key for Prod: 
	SET areyousure=N
	SET /P areyousure=.!BS!  AWS Secret Key entered is !sfcprodsecretkey! - please confirm correct^? ^(Y/N^): 
	IF "!areyousure!" NEQ "Y" (
	    ECHO.
        ECHO %TIME%: Set variables for !nextactive! abandoned - Incorrect AWS Secret Key>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
		GOTO PROD_MENU
	)
)

ECHO.
ECHO   This option will update Secrets Manager and run the following:
ECHO.

ECHO   cf set-env !nextactive! AWS_ACCESS_KEY_ID !sfcprodsecretid!
ECHO   cf set-env !nextactive! AWS_SECRET_ACCESS_KEY !sfcprodsecretkey!
ECHO   cf set-env !nextactive! DB_NAME ^<dbname^>
ECHO   cf set-env !nextactive! DB_USER ^<dbuser^>
ECHO   cf set-env !nextactive! NODE_ENV production
ECHO   cf set-env !nextactive! SERVER__NAME sfcuat
ECHO   cf set-env !nextactive! DB_POOL 450

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Set variables - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Set variables for !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

ECHO %TIME%: Updating AWS Secrets for PROD/API>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
ECHO   *****************************************************************************
ECHO   ******!redbackground! Please update AWS variable for PROD/API via AWS Secrets Manager !clearbackground!******
ECHO   *****************************************************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open AWS Secrets Manager ^(will open in a new window^)^? (Y/N): 

IF "!openbrowser!"=="Y" (
    start https://eu-west-1.console.aws.amazon.com/secretsmanager/home?region=eu-west-1#/secret?name=prod%%2Fapi
)

ECHO.
ECHO   Update the following:
ECHO.

@REM **********************************************
@REM Variables will have changed due to the restage
@REM **********************************************

cf env !nextactive! >%TEMP%\cfenvoutput.temp

@REM ************
@REM SHOW DB_HOST
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "host" %TEMP%\cfenvoutput.temp`) DO (
    SET dbhost=%%F
	ECHO !dbhost:~1,-2!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_HOST=!dbhost:~1,-2!
)

@REM ************
@REM SHOW DB_NAME
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "name" %TEMP%\cfenvoutput.temp ^|findstr "rdsbroker"`) DO (
    SET dbname=%%F
	ECHO !dbname:~1,-2!|clip
	SET areyousure=N
    SET /P areyousure=.!BS!  DB_NAME=!dbname:~1,-2!
	SET dbname=!dbname:~1,-2!
)

@REM ***********
@REM SET DB_USER
@REM ***********

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "username" %TEMP%\cfenvoutput.temp`) DO (
    SET dbuser=%%F
	ECHO !dbuser:~1,-1!|clip
	SET areyousure=N
    SET /P areyousure=.!BS!  DB_USER=!dbuser:~1,-1!
	SET dbuser=!dbuser:~1,-1!
)

@REM ************
@REM SHOW DB_PASS
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "password.:" %TEMP%\cfenvoutput.temp`) DO (
    SET dbpass=%%F
	ECHO !dbpass:~1,-2!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_PASS=!dbpass:~1,-2!
)

@REM ************
@REM SHOW DB_PORT
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "port.:" %TEMP%\cfenvoutput.temp`) DO (
    SET dbport=%%F
	ECHO !dbport:~0,-1!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_PORT=!dbport:~0,-1!
)

ECHO.
ECHO %TIME%: Updating cf variables for !extraspace!!nextactive!>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
cf set-env !nextactive! AWS_ACCESS_KEY_ID !sfcprodsecretid!
cf set-env !nextactive! AWS_SECRET_ACCESS_KEY !sfcprodsecretkey!
cf set-env !nextactive! DB_NAME !dbname!
cf set-env !nextactive! DB_USER !dbuser!
cf set-env !nextactive! NODE_ENV production
cf set-env !nextactive! SERVER__NAME sfcuat
cf set-env !nextactive! DB_POOL 450
ECHO.

ECHO %TIME%: Set variables for !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h3=!greenbackground!

IF "!menu_selection!"=="S1" GOTO RESTAGE_PREPROD_FOR_LIVE_II

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of SET_VARIABLES_PROD
@REM ************************************************************************************************

@REM ************************************************************************************************
:RESTAGE_PREPROD_FOR_LIVE_II
@REM ************************************************************************************************

SET h4=!redbackground!

ECHO.
ECHO -------------------------------------------->>!devopslogname!
ECHO %TIME%: Restage application !extraspace!!nextactive!>>!devopslogname!
ECHO -------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.
ECHO   cf restage !nextactive!

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Restage !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Restage application !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cf restage !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.
ECHO   **********************************************
ECHO   ******!redbackground! Please smoketest !nextactive!!extraspace! app !clearbackground!******
ECHO   **********************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open !nextactive! app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://!nextactive!.cloudapps.digital/
)

ECHO %TIME%: Restage application !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h4=!greenbackground!

IF "!menu_selection!"=="S1" GOTO STOP_PREPROD

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of RESTAGE_PREPROD_FOR_LIVE_II
@REM ************************************************************************************************

@REM ************************************************************************************************
:STOP_PREPROD
@REM ************************************************************************************************

SET h5=!redbackground!

ECHO.
ECHO ----------------------------------------->>!devopslogname!
ECHO %TIME%: Stop application !extraspace!!nextactive!>>!devopslogname!
ECHO ----------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.

ECHO   cf stop !nextactive!

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Stop !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Stop application !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cf stop !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Stop application !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET h5=!greenbackground!

IF "!menu_selection!"=="S1" (

    SET completedmessage=Options 1-5 completed
	ECHO %TIME%: PROD MENU: !completedmessage!>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
)

SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of STOP_PREPROD
@REM ************************************************************************************************

@REM ************************************************************************************************
:UPDATE_OFFLINE_DATETIME
@REM ************************************************************************************************

SET h6=!redbackground!

ECHO.
ECHO -------------------------------------------------------->>!devopslogname!
ECHO %TIME%: Update sfcoffline html page - date and time>>!devopslogname!
ECHO -------------------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Update offline index.html ^(opens in a new window^)^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Update sfcoffline html page - date and time abandoned - user choice>>!devopslogname!
    TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cd !sfcofflineapp!
notepad index.html
cd !sfcliveapp!

ECHO %TIME%: Update sfcoffline html page - date and time completed>>!devopslogname!
TIMEOUT 2 >nul

SET h6=!greenbackground!

IF "!menu_selection!"=="S2" GOTO CHECK_ANALYTICS

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of UPDATE_OFFLINE_DATETIME
@REM ************************************************************************************************

@REM ************************************************************************************************
:CHECK_ANALYTICS
@REM ************************************************************************************************

SET h7=!redbackground!

ECHO.
ECHO ---------------------------------------------------->>!devopslogname!
ECHO %TIME%: Check current users on Google Analytics>>!devopslogname!
ECHO ---------------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul

ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Check current users via Google Analytics ^(opens in a new window - Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Check current users on Google Analytics abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

START https://analytics.google.com/analytics/web/#/realtime/rt-overview/a132324399w198886877p193437447/

ECHO %TIME%: Check current users on Google Analytics completed>>!devopslogname!
TIMEOUT 2 >nul

SET h7=!greenbackground!

IF "!menu_selection!"=="S2" GOTO PUSH_OFFLINE_APPLICATION

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of CHECK_ANALYTICS
@REM ************************************************************************************************

@REM ************************************************************************************************
:PUSH_OFFLINE_APPLICATION
@REM ************************************************************************************************

SET h8=!redbackground!

ECHO.

ECHO ------------------------------------->>!devopslogname!
ECHO %TIME%: Push offline application>>!devopslogname!
ECHO ------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.

ECHO   cf push -f manifest.yml

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Push sfcoffline application - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Push sfcoffline application abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cd !sfcofflineapp!
cf push -f manifest.yml>>!devopslogname! 2>&1
TIMEOUT 2 >nul
cd !sfcliveapp!

ECHO.
ECHO   *********************************************
ECHO   ******!redbackground! Please smoketest sfcoffline app !clearbackground!******
ECHO   *********************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open LIVE app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://sfcoffline.cloudapps.digital/
)

ECHO %TIME%: Push offline application completed>>!devopslogname!
TIMEOUT 2 >nul

SET h8=!greenbackground!

IF "!menu_selection!"=="S2" GOTO SWITCH_LIVE_ROUTE_TO_OFFLINE

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of PUSH_OFFLINE_APPLICATION
@REM ************************************************************************************************

@REM ************************************************************************************************
:SWITCH_LIVE_ROUTE_TO_OFFLINE
@REM ************************************************************************************************

SET h9=!redbackground!

ECHO.
ECHO ----------------------------------------------------->>!devopslogname!
ECHO %TIME%: Switch route from !prevextraspace!!previousactive! to offline>>!devopslogname!
ECHO ----------------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will now run the following:
ECHO.

ECHO   cf map-route sfcoffline cloudapps.digital -n sfcuat
ECHO   cf map-route sfcoffline skillsforcare.org.uk -n asc-wds
ECHO   cf unmap-route !previousactive! cloudapps.digital -n sfcuat
ECHO   cf unmap-route !previousactive! skillsforcare.org.uk -n asc-wds

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Switch Route from !previousactive! to sfcoffline - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Switch route from !previousactive! to offline abandoned - user choice>>!devopslogname!
    TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cf map-route sfcoffline cloudapps.digital -n sfcuat>>!devopslogname! 2>&1
cf map-route sfcoffline skillsforcare.org.uk -n asc-wds>>!devopslogname! 2>&1
cf unmap-route !previousactive! cloudapps.digital -n sfcuat>>!devopslogname! 2>&1
cf unmap-route !previousactive! skillsforcare.org.uk -n asc-wds>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   ****************************************************
ECHO   ******!redbackground! Please smoketest LIVE ^(sfcoffline) app !clearbackground!******
ECHO   ****************************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open LIVE app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://asc-wds.skillsforcare.org.uk/
)

ECHO %TIME%: Switch route from !previousactive! to offline completed>>!devopslogname!
TIMEOUT 2 >nul

SET h9=!greenbackground!

IF "!menu_selection!"=="S2" GOTO STOP_LIVE

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of SWITCH_LIVE_ROUTE_TO_OFFLINE
@REM ************************************************************************************************

@REM ************************************************************************************************
:STOP_LIVE
@REM ************************************************************************************************

SET h10=!redbackground!

ECHO.
ECHO --------------------------------------------------->>!devopslogname!
ECHO %TIME%: Stop !prevextraspace!!previousactive! and start !extraspace!!nextactive!>>!devopslogname!
ECHO --------------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul

ECHO.
ECHO   This option will run the following:
ECHO.

ECHO   cf stop !previousactive!
ECHO   -- patch database if required --
ECHO   cf start !nextactive!

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Stop !previousactive! and start !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Stop !previousactive! and start !nextactive! abandoned - user choice>>!devopslogname!
    TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cf stop !previousactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Checking if database patches to be applied to sfcuatdb01>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Are there database patches to deploy^? ^(Y/N^): 
ECHO.
IF "!areyousure!"=="Y" (
    cd !sfcdbscripts!\UAT
	git status >%TEMP%\gitstatusout.temp
    ECHO Database script status:
    ECHO.
    TYPE %TEMP%\gitstatusout.temp
	ECHO.
	
	SET dbscriptsuptodate=notuptodate
	FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "up.to.date.with" ^| find /v /c ""`) DO (
    SET var=%%F
	)
	
	IF "!var!"=="1" (
	SET dbscriptsuptodate=uptodate
	)
	
	IF "!dbscriptsuptodate!"=="notuptodate" (
		ECHO   *************************************************
		ECHO   ******!yellowbackground! WARNING - DB scripts not up-to-date !clearbackground!******
		ECHO   *************************************************
		ECHO.
	    SET areyousure=N
	    SET /P areyousure=.!BS!  Please pull latest scripts from Git Hub - press enter to continue:
		ECHO.
		)

REM ************************************************************************************************
:RUN_DB_SCRIPT_PROD
REM ************************************************************************************************

	ECHO   Select database script...
	ECHO.
	SET scriptname=
	
@REM ****************************************************************
@REM Execute powershell command and get result in scriptname variable
@REM ****************************************************************

    FOR /f "delims=" %%I IN ('%pwshcmd%') DO SET scriptname=%%I
	
	IF "!scriptname!"=="" (
	    ECHO   ********************************
		ECHO   ******!yellowbackground! No script selected !clearbackground!******
		ECHO   ********************************
		ECHO.
	)
	IF "!scriptname!" NEQ "" (
	    ECHO Script selected ^(below^): !scriptname!
		ECHO ----------------------------------------------------------------------------------------------!redbackground!
		type !scriptname!
		ECHO.
		ECHO !clearbackground!----------------------------------------------------------------------------------------------
		ECHO.
		SET areyousure=N
		SET /P areyousure=.!BS!  Run !scriptname! - are you sure^? ^(Y/N^): 
		ECHO.
		IF "!areyousure!"=="Y" (
		    ECHO %TIME%: Running database script !scriptname!>>!devopslogname!
			TIMEOUT 2 >nul
			ECHO.
			ECHO ---------------------------------------------------------->>!devopslogname!
			ECHO Script: !scriptname!>>!devopslogname!
			ECHO ---------------------------------------------------------->>!devopslogname!
			type !scriptname!>>!devopslogname!
			ECHO. >>!devopslogname!
			TIMEOUT 2 >nul
			ECHO ---------------------------------------------------------->>!devopslogname!
			ECHO Script output>>!devopslogname!
			ECHO ---------------------------------------------------------->>!devopslogname!
			cf conduit sfcuatdb01 --app-name sfcadmin_sfcuatdb01 -- psql < !scriptname!>>!devopslogname! 2>&1
			ECHO ---------------------------------------------------------->>!devopslogname!
			TIMEOUT 2 >nul
			ECHO.
			ECHO %TIME%: Completed !scriptname!>>!devopslogname!
			TIMEOUT 2 >nul
			ECHO.
		)
	)
	SET runmore=N
	SET /P runmore=.!BS!  Run another script^? ^(Y/N^): 
	ECHO.
	IF "!runmore!"=="Y" GOTO RUN_DB_SCRIPT_PROD
	cd !sfcliveapp!
	ECHO %TIME%: Database patches applied to sfcuatdb01>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
)

cf start !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   **********************************************
ECHO   ******!redbackground! Please smoketest !nextactive!!extraspace! app !clearbackground!******
ECHO   **********************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open !nextactive! app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://!nextactive!.cloudapps.digital/
)

ECHO %TIME%: Stop !previousactive! and start !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h10=!greenbackground!

IF "!menu_selection!"=="S2" GOTO SWITCH_ROUTE_TO_LIVE

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of STOP_LIVE
@REM ************************************************************************************************

@REM ************************************************************************************************
:SWITCH_ROUTE_TO_LIVE
@REM ************************************************************************************************

SET h11=!redbackground!

ECHO.
ECHO -------------------------------------------------------->>!devopslogname!
ECHO %TIME%: Switch Route from sfcoffline to !extraspace!!nextactive!>>!devopslogname!
ECHO -------------------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul

ECHO.
ECHO   This option will run the following:
ECHO.

ECHO   cf map-route !nextactive! cloudapps.digital -n sfcuat
ECHO   cf map-route !nextactive! skillsforcare.org.uk -n asc-wds
ECHO   cf unmap-route sfcoffline cloudapps.digital -n sfcuat
ECHO   cf unmap-route sfcoffline skillsforcare.org.uk -n asc-wds

ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Switch Route from sfcoffline to !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Switch Route from sfcoffline to !nextactive! abandoned - user choice>>!devopslogname!
    TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cf map-route !nextactive! cloudapps.digital -n sfcuat>>!devopslogname! 2>&1
cf map-route !nextactive! skillsforcare.org.uk -n asc-wds>>!devopslogname! 2>&1
cf unmap-route sfcoffline cloudapps.digital -n sfcuat>>!devopslogname! 2>&1
cf unmap-route sfcoffline skillsforcare.org.uk -n asc-wds>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   ***************************************
ECHO   ******!redbackground! Please smoketest LIVE app !clearbackground!******
ECHO   ***************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open LIVE app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://asc-wds.skillsforcare.org.uk/
)

ECHO %TIME%: Switch Route from sfcoffline to !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h11=!greenbackground!

IF "!menu_selection!"=="S2" GOTO STOP_OFFLINE

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of SWITCH_ROUTE_TO_LIVE
@REM ************************************************************************************************

@REM ************************************************************************************************
:STOP_OFFLINE
@REM ************************************************************************************************

SET h12=!redbackground!

ECHO.
ECHO ---------------------------->>!devopslogname!
ECHO %TIME%: Stop sfcoffline>>!devopslogname!
ECHO ---------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.

ECHO   cf stop sfcoffline

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Stop sfcoffline - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Stop sfcoffline abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cf stop sfcoffline>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Stop sfcoffline completed>>!devopslogname!
TIMEOUT 2 >nul

SET h12=!greenbackground!

IF "!menu_selection!"=="S2" GOTO REMOVE_URL

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of STOP_OFFLINE
@REM ************************************************************************************************

@REM ************************************************************************************************
:REMOVE_URL
@REM ************************************************************************************************

SET h13=!redbackground!

ECHO.
ECHO ------------------------------------------------------------>>!devopslogname!
ECHO %TIME%: Remove Route cloudapps.digital from !extraspace!!nextactive!>>!devopslogname!
ECHO ------------------------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul

ECHO.

IF "!previousactive!" NEQ "sfcuatblue" (
    IF "!previousactive!" NEQ "sfcuatgreen" (
		ECHO %TIME%: Remove Route cloudapps.digital - sfcuatblue/sfcuatgreen not active!nextactive!>>!devopslogname!#
	    TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
    	GOTO PROD_MENU
	)
)

ECHO   This option will run the following:
ECHO.

ECHO   cf unmap-route !nextactive! cloudapps.digital -n !nextactive!	

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Remove Route cloudapps.digital from !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Remove Route cloudapps.digital from !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

cf unmap-route !nextactive! cloudapps.digital -n !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Remove Route cloudapps.digital from !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h13=!greenbackground!

IF "!menu_selection!"=="S2" GOTO PUBLISH_RELEASE

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of REMOVE_URL
@REM ************************************************************************************************

@REM ************************************************************************************************
:PUBLISH_RELEASE
@REM ************************************************************************************************

SET h14=!redbackground!

ECHO.
ECHO -------------------------------------->>!devopslogname!
ECHO %TIME%: Publish Release to Github>>!devopslogname!
ECHO -------------------------------------->>!devopslogname!
TIMEOUT 2 >nul

ECHO.
ECHO   This option will allow the user to publish a previously created draft release on Github 
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Publish release on Github (opens in a new window - Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Publish Release to Github abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_MENU
)

ECHO   Select the release in Github and click on Edit. Then click on the Github !greenbackground! Publish release !clearbackground! button
TIMEOUT 3 >nul

START https://github.com/NMDSdevopsServiceAdm/SopraSteria-SFC/releases

ECHO.

ECHO %TIME%: Publish Release completed>>!devopslogname!
TIMEOUT 2 >nul

SET h14=!greenbackground!

IF "!menu_selection!"=="S2" (
	ECHO.
	SET completedmessage=Options 6-14 completed
	ECHO %TIME%: PROD MENU: !completedmessage!>>!devopslogname!
	TIMEOUT 2 >nul
)

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_MENU

@REM ************************************************************************************************
@REM End of PUBLISH_RELEASE
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM End of PROD_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:PROD_EMERGENCY_SPLASH
@REM ************************************************************************************************

CLS
ECHO.

ECHO *******************************************************************
ECHO ******!yellowbackground! WARNING - Rollback not possible if the latest version !clearbackground!******
ECHO ******!yellowbackground! of the app has been deployed to PreProd               !clearbackground!******
ECHO *******************************************************************
ECHO.
SET /P confirm=Please confirm previous version of app still deployed to !nextactive! ^(Y/N^): 

IF "!confirm!"=="N" (
    ECHO.
	ECHO ****************************************************************
    ECHO ******!redbackground! Rollback will only be possible by regenerating the !clearbackground!******
    ECHO ******!redbackground! previous release from GIT and applying as a        !clearbackground!******
    ECHO ******!redbackground! PreProd release                                    !clearbackground!******
	ECHO ****************************************************************
    ECHO.
	SET /P continue=Press enter to continue: 
	GOTO MAIN_MENU	
)

ECHO.

@REM ************************************************************************************************
@REM End of PROD_EMERGENCY_SPLASH
@REM ************************************************************************************************

@REM ************************************************************************************************
:PROD_EMERGENCY_MENU
@REM ************************************************************************************************

CLS
ECHO Getting app status.......

@REM **************************************
@REM get the app info for the current space
@REM **************************************

cf apps >%TEMP%\cfappsoutput.temp

@REM ********************************
@REM Determine which instance is live
@REM ********************************

SET liveactive=not set
SET activemessage=^, LIVE ACTIVE: !redbackground!not set!clearbackground!

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatgreen" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET liveactive=sfcuatgreen
	SET alternativeactive=sfcuatblue
	SET activemessage=^, LIVE ACTIVE: !greenbackground!sfcuatgreen!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatblue" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
    SET liveactive=sfcuatblue
	SET alternativeactive=sfcuatgreen
	SET activemessage=^, LIVE ACTIVE: !bluebackground!sfcuatblue!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcoffline" ^| find /v /c ""`) DO (
	SET var=%%F
)

IF "!var!"=="1" (
	SET liveactive=sfcoffline
	SET activemessage=^, LIVE ACTIVE: !yellowbackground!sfcoffline!clearbackground!
)

@REM **********************************************
@REM Next and previous were determined in Main Menu
@REM **********************************************

@REM **********************************************************************************
@REM If still unknown then came in with current not set or set to offline - need to ask
@REM **********************************************************************************

IF "!nextactive!"=="unknown" (
	
    ECHO.
	SET /P selectactive=PREPROD not known - enter the application which is being rolled-back to: sfcuatblue or sfcuatgreen: 
	IF "!selectactive!" NEQ "sfcuatblue" (
	    IF "!selectactive!" NEQ "sfcuatgreen" (
		    ECHO.
			ECHO   Required application invalid
		    ECHO.
		    SET /P continue=.!BS!  Press enter to continue: 
		    GOTO MAIN_MENU))
				
	SET nextactive=!selectactive!
		
	IF "!nextactive!"=="sfcuatblue" (
	    SET previousactive=sfcuatgreen
		SET nextbackground=!bluebackground!
		SET previousbackground=!greenbackground!
	)
		
	IF "!nextactive!"=="sfcuatgreen" (
	    SET previousactive=sfcuatblue
		SET nextbackground=!greenbackground!
		SET previousbackground=!bluebackground!
	)
)

SET extraspace=
IF "!nextactive!"=="sfcuatblue" SET extraspace= 

SET livebinding=unknown
SET bindingmessage=^, BINDING: !redbackground!unknown!clearbackground!

@REM *******************************************************
@REM get the binding info for the app being rolled back from
@REM *******************************************************

cf env !previousactive! >%TEMP%\cfenvoutput.temp

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb01" ^| find /v /c ""`) DO (
    SET var=%%F
)
	
IF "!var!"=="1" (
    SET livebinding=sfcuatdb01
	SET bindingmessage=^, BINDING: !greenbackground!sfcuatdb01!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb02" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET livebinding=sfcuatdb02
	SET bindingmessage=^, BINDING: !redbackground!sfcuatdb02!clearbackground!
)

SET preprodcurrentbinding=unknown
SET preprodbindingmessage=^, TARGET BINDING: !redbackground!unknown!clearbackground!

@REM *****************************************************
@REM get the binding info for the app being rolled back to
@REM *****************************************************

cf env !nextactive! >%TEMP%\cfenvoutput.temp

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb01" ^| find /v /c ""`) DO (
    SET var=%%F
)
	
IF "!var!"=="1" (
    SET preprodcurrentbinding=sfcuatdb01
	SET preprodbindingmessage=^, TARGET BINDING: !greenbackground!sfcuatdb01!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb02" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET preprodcurrentbinding=sfcuatdb02
	SET preprodbindingmessage=^, TARGET BINDING: !redbackground!sfcuatdb02!clearbackground!
)

@REM ****************************
@REM Show the Prod Emergency menu
@REM ****************************

CLS
ECHO                  !cyanbackground!SKILLS FOR CARE PROD EMERGENCY MENU (version !version!)!clearbackground!
ECHO                  ==================================================
ECHO.
ECHO   !h1!1 !clearbackground!) Deploy Emergency sfcoffline html page
ECHO   !h2!2 !clearbackground!) Update !nextbackground!!nextactive!!clearbackground! database binding
ECHO   !h3!3 !clearbackground!) Restage !nextbackground!!nextactive!!clearbackground! application ^(i^)
ECHO   !h4!4 !clearbackground!) Set variables for !nextbackground!!nextactive!!clearbackground!
ECHO   !h5!5 !clearbackground!) Restage !nextbackground!!nextactive!!clearbackground! application ^(ii^)
ECHO   !h6!6 !clearbackground!) Start !nextbackground!!nextactive!!clearbackground!
ECHO   !h7!7 !clearbackground!) Switch LIVE Route to !nextbackground!!nextactive!!clearbackground!
ECHO   !h8!8 !clearbackground!) Stop Offline
ECHO   !h9!9 !clearbackground!) Remove URL
ECHO.
ECHO   R - Run options 1-9 (above)
ECHO.
ECHO   0  - Exit
ECHO.
ECHO   CURRENT SPACE: !currentspace!!activemessage!!bindingmessage!
ECHO.
ECHO   ROLLBACK TARGET: !nextbackground!!nextactive!!clearbackground!!preprodbindingmessage!

IF "!testversion!"=="true" GOTO SKIP_LIVE_WARNING_EMERGENCY

ECHO.
ECHO   !redbackground!WARNING: CLOUD FOUNDRY COMMANDS ACTIVE - THIS IS NOT A TEST VERSION!clearbackground!

:SKIP_LIVE_WARNING_EMERGENCY

ECHO.

SET menu_selection=99
SET /P menu_selection=.!BS!  Enter selection: 

@REM ***********************
@REM Process the menu choice
@REM ***********************

IF !menu_selection! NEQ 0 (
    ECHO ==================================================================================================>>!devopslogname!
    TIMEOUT 2>nul)

IF !menu_selection!==1 (
    ECHO %TIME%: EMERGENCY MENU: 1 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO DEPLOY_OFFLINE_FOR_EMERGENCY
)
IF !menu_selection!==2 (
    ECHO %TIME%: EMERGENCY MENU: 2 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO UPDATE_PREPROD_DATABASE_BINDING_FOR_ROLLBACK
)
IF !menu_selection!==3 (
    ECHO %TIME%: EMERGENCY MENU: 3 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO RESTAGE_PREPROD_FOR_ROLLBACK_I
)
IF !menu_selection!==4 (
    ECHO %TIME%: EMERGENCY MENU: 4 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO SET_VARIABLES_ROLLBACK
)
IF !menu_selection!==5 (
    ECHO %TIME%: EMERGENCY MENU: 5 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO RESTAGE_PREPROD_FOR_ROLLBACK_II
)
IF !menu_selection!==6 (
    ECHO %TIME%: EMERGENCY MENU: 6 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO START_LIVE_FOR_ROLLBACK
)
IF !menu_selection!==7 (
    ECHO %TIME%: EMERGENCY MENU: 7 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO SWITCH_ROUTE_TO_LIVE_FOR_ROLLBACK
)
IF !menu_selection!==8 (
    ECHO %TIME%: EMERGENCY MENU: 8 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO STOP_OFFLINE_FOR_ROLLBACK
)
IF !menu_selection!==9 (
    ECHO %TIME%: EMERGENCY MENU: 9 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO REMOVE_URL_FOR_ROLLBACK
)
IF "!menu_selection!"=="R" (

    SET h1=
    SET h2=
    SET h3=
    SET h4=
    SET h5=
    SET h6=
    SET h7=
    SET h8=
    SET h9=
		
	ECHO %TIME%: EMERGENCY MENU: R selected to run all options for Rollback....>>!devopslogname!
	TIMEOUT 2 >nul

    GOTO DEPLOY_OFFLINE_FOR_EMERGENCY

)
IF "!menu_selection!"=="E" (

ECHO %TIME%: EMERGENCY MENU: E selected>>!devopslogname!
TIMEOUT 2 >nul

@REM ***********************************************************
@REM Emergency offline html page only valid for production space
@REM ***********************************************************

SET camefrommenu=PROD_EMERGENCY_MENU
SET camefromspace=!currentspace!
GOTO DEPLOY_OFFLINE_FOR_EMERGENCY
)

IF !menu_selection!==0 GOTO MAIN_MENU
TIMEOUT 2 >nul
CLS
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of PROD_EMERGENCY_MENU
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM PROD_EMERGENCY_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:DEPLOY_OFFLINE_FOR_EMERGENCY
@REM ************************************************************************************************

IF "!menu_selection!" NEQ "E" SET h1=!redbackground!

IF "!currentspace!" NEQ "production" (
    ECHO. 
	ECHO   Changing space to production
	ECHO.
	cf target -s production)

ECHO.
ECHO ------------------------------------------------->>!devopslogname!
ECHO %TIME%: Deploy offline emergency application>>!devopslogname!
ECHO ------------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.

ECHO   cf push -f manifest.yml
ECHO   cf map-route sfcoffline cloudapps.digital -n sfcuat
ECHO   cf map-route sfcoffline skillsforcare.org.uk -n asc-wds
ECHO   cf unmap-route !previousactive! cloudapps.digital -n sfcuat
ECHO   cf unmap-route !previousactive! skillsforcare.org.uk -n asc-wds
ECHO   cf stop !previousactive!

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Deploy emergency sfcoffline application - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Deploy emergency sfcoffline application abandoned - user choice>>!devopslogname!
    TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue: 
	IF "!menu_selection!"=="E" (
	    IF "!camefromspace!" NEQ "production" (
		    ECHO.
		    ECHO   Changing space to !camefromspace!
			ECHO.
		    cf target -s !camefromspace!
		    ECHO.
		)
	    GOTO !camefrommenu!
	)
	GOTO PROD_EMERGENCY_MENU
)

cd !sfcemergencyapp!>>!devopslogname! 2>&1
cf push -f manifest.yml>>!devopslogname! 2>&1
cd !sfcliveapp!>>!devopslogname! 2>&1
cf map-route sfcoffline cloudapps.digital -n sfcuat>>!devopslogname! 2>&1
cf map-route sfcoffline skillsforcare.org.uk -n asc-wds>>!devopslogname! 2>&1
cf unmap-route !previousactive! cloudapps.digital -n sfcuat>>!devopslogname! 2>&1
cf unmap-route !previousactive! skillsforcare.org.uk -n asc-wds>>!devopslogname! 2>&1
cf stop !previousactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   ****************************************************
ECHO   ******!redbackground! Please smoketest LIVE ^(sfcoffline) app !clearbackground!******
ECHO   ****************************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open LIVE app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://asc-wds.skillsforcare.org.uk/
)

ECHO %TIME%: Deploy offline emergency application completed>>!devopslogname!
TIMEOUT 2 >nul

IF "!menu_selection!"=="E" (
    IF "!camefromspace!" NEQ "production" (
		ECHO.
		ECHO   Changing space to !camefromspace!
		ECHO.
		cf target -s !camefromspace!
		ECHO.
	)
    GOTO !camefrommenu!
)

SET h1=!greenbackground!

IF "!menu_selection!"=="R" GOTO UPDATE_PREPROD_DATABASE_BINDING_FOR_ROLLBACK

ECHO.
SET /P continue=.!BS!  Press enter to continue: 

GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of STOP_LIVE_FOR_ROLLBACK
@REM ************************************************************************************************

@REM ************************************************************************************************
:UPDATE_PREPROD_DATABASE_BINDING_FOR_ROLLBACK
@REM ************************************************************************************************

SET h2=!redbackground!

ECHO.
ECHO ------------------------------------------------------------------>>!devopslogname!
ECHO %TIME%: Update database binding for !extraspace!!nextactive! to sfcuatdb01>>!devopslogname!
ECHO ------------------------------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

IF "!preprodcurrentbinding!"=="sfcuatdb01" (
    ECHO   Current binding already sfcuatdb01
	ECHO %TIME%: Current binding already sfcuatdb01>>!devopslogname!
	TIMEOUT 2 >nul
	SET h2=!greenbackground!
	ECHO.
	
	IF "!menu_selection!"=="R" (
	    SET h3=!yellowbackground!
		SET h4=!yellowbackground!
		SET h5=!yellowbackground!
	    ECHO %TIME%: Skipping options 3-5>>!devopslogname!
		TIMEOUT 2 >nul
		GOTO START_LIVE_FOR_ROLLBACK
		)
	
	SET /P continue=.!BS!  Press enter to continue: 
    GOTO PROD_EMERGENCY_MENU
    
)
	
ECHO   This option will run the following:
ECHO.
	
IF "!preprodcurrentbinding!"=="sfcuatdb02" (
    ECHO   cf unbind-service !nextactive! sfcuatdb02
)
ECHO   cf bind-service !nextactive! sfcuatdb01
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Bind sfcuatdb01 to !nextactive! - are you sure^? ^(Y/N^): 
ECHO.
		
IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Update database binding for !nextactive! to sfcuatdb01 abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO PROD_EMERGENCY_MENU)

IF "!preprodcurrentbinding!"=="sfcuatdb02" (
    cf unbind-service !nextactive! sfcuatdb02>>!devopslogname! 2>&1
)
cf bind-service !nextactive! sfcuatdb01>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Update database binding for !nextactive! to sfcuatdb01 completed>>!devopslogname!
TIMEOUT 2 >nul

SET h2=!greenbackground!

IF "!menu_selection!"=="R" GOTO RESTAGE_PREPROD_FOR_ROLLBACK_I

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of UPDATE_PREPROD_DATABASE_BINDING_FOR_ROLLBACK
@REM ************************************************************************************************

@REM ************************************************************************************************
:RESTAGE_PREPROD_FOR_ROLLBACK_I
@REM ************************************************************************************************

SET h3=!redbackground!

ECHO.
ECHO -------------------------------------------->>!devopslogname!
ECHO %TIME%: Restage application !extraspace!!nextactive!>>!devopslogname!
ECHO -------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.
ECHO   cf restage !nextactive!
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Restage !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Restage application !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_EMERGENCY_MENU
)

cf restage !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO %TIME%: Restage application !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h3=!greenbackground!

IF "!menu_selection!"=="R" GOTO SET_VARIABLES_ROLLBACK

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of RESTAGE_PREPROD_FOR_ROLLBACK_I
@REM ************************************************************************************************

@REM ************************************************************************************************
:SET_VARIABLES_ROLLBACK
@REM ************************************************************************************************

SET h4=!redbackground!

ECHO.
ECHO ------------------------------------------>>!devopslogname!
ECHO %TIME%: Set variables for !extraspace!!nextactive!>>!devopslogname!
ECHO ------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul

IF "!sfcprodsecretid!"=="" (
    ECHO.
	SET /P sfcprodsecretid=.!BS!  Enter AWS Secret ID for Prod: 
	SET areyousure=N
	SET /P areyousure=.!BS!  AWS Secret ID entered is !sfcprodsecretid! - please confirm correct^? ^(Y/N^): 
	IF "!areyousure!" NEQ "Y" (
	    ECHO.
        ECHO %TIME%: Set variables for !nextactive! abandoned - Incorrect AWS Secret ID>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
		GOTO PROD_EMERGENCY_MENU
	)
)

IF "!sfcprodsecretkey!"=="" (
    ECHO.
	SET /P sfcprodsecretkey=.!BS!  Enter AWS Secret Key for Prod: 
	SET areyousure=N
	SET /P areyousure=.!BS!  AWS Secret Key entered is !sfcprodsecretkey! - please confirm correct^? ^(Y/N^): 
	IF "!areyousure!" NEQ "Y" (
	    ECHO.
        ECHO %TIME%: Set variables for !nextactive! abandoned - Incorrect AWS Secret Key>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
		GOTO PROD_EMERGENCY_MENU
	)
)

ECHO.
ECHO   This option will update Secrets Manager and run the following:
ECHO.
ECHO   cf set-env !nextactive! AWS_ACCESS_KEY_ID !sfcprodsecretid!
ECHO   cf set-env !nextactive! AWS_SECRET_ACCESS_KEY !sfcprodsecretkey!
ECHO   cf set-env !nextactive! DB_NAME ^<dbname^>
ECHO   cf set-env !nextactive! DB_USER ^<dbuser^>
ECHO   cf set-env !nextactive! NODE_ENV production
ECHO   cf set-env !nextactive! SERVER__NAME sfcuat
ECHO   cf set-env !nextactive! DB_POOL 450

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Set variables for !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Set variables for !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_EMERGENCY_MENU
)

ECHO %TIME%: Updating AWS Secrets for PROD/API>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
ECHO   *****************************************************************************
ECHO   ******!redbackground! Please update AWS variable for PROD/API via AWS Secrets Manager !clearbackground!******
ECHO   *****************************************************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open AWS Secrets Manager ^(will open in a new window^)^? (Y/N): 

IF "!openbrowser!"=="Y" (
    start https://eu-west-1.console.aws.amazon.com/secretsmanager/home?region=eu-west-1#/secret?name=prod%%2Fapi
)

ECHO.
ECHO   Update the following:
ECHO.

@REM **********************************************
@REM Variables will have changed due to the restage
@REM **********************************************

cf env !nextactive! >%TEMP%\cfenvoutput.temp

@REM ************
@REM SHOW DB_HOST
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "host" %TEMP%\cfenvoutput.temp`) DO (
    SET dbhost=%%F
	ECHO !dbhost:~1,-2!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_HOST=!dbhost:~1,-2!
)

@REM ************
@REM SHOW DB_NAME
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "name" %TEMP%\cfenvoutput.temp ^|findstr "rdsbroker"`) DO (
    SET dbname=%%F
	ECHO !dbname:~1,-2!|clip
	SET areyousure=N
    SET /P areyousure=.!BS!  DB_NAME=!dbname:~1,-2!
	SET dbname=!dbname:~1,-2!
)

@REM ***********
@REM SET DB_USER
@REM ***********

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "username" %TEMP%\cfenvoutput.temp`) DO (
    SET dbuser=%%F
	ECHO !dbuser:~1,-1!|clip
	SET areyousure=N
    SET /P areyousure=.!BS!  DB_USER=!dbuser:~1,-1!
	SET dbuser=!dbuser:~1,-1!
)

@REM ************
@REM SHOW DB_PASS
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "password.:" %TEMP%\cfenvoutput.temp`) DO (
    SET dbpass=%%F
	ECHO !dbpass:~1,-2!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_PASS=!dbpass:~1,-2!
)

@REM ************
@REM SHOW DB_PORT
@REM ************

FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "port.:" %TEMP%\cfenvoutput.temp`) DO (
    SET dbport=%%F
	ECHO !dbport:~0,-1!|clip
	SET areyousure=N
    SET /p areyousure=.!BS!  DB_PORT=!dbport:~0,-1!
)

ECHO.
ECHO %TIME%: Updating cf variables for !extraspace!!nextactive!>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
cf set-env !nextactive! AWS_ACCESS_KEY_ID !sfcprodsecretid!
cf set-env !nextactive! AWS_SECRET_ACCESS_KEY !sfcprodsecretkey!
cf set-env !nextactive! DB_NAME !dbname!
cf set-env !nextactive! DB_USER !dbuser!
cf set-env !nextactive! NODE_ENV production
cf set-env !nextactive! SERVER__NAME sfcuat
cf set-env !nextactive! DB_POOL 450
ECHO.

ECHO %TIME%: Set variables for !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h4=!greenbackground!

IF "!menu_selection!"=="R" GOTO RESTAGE_PREPROD_FOR_ROLLBACK_II

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of SET_VARIABLES_ROLLBACK
@REM ************************************************************************************************

@REM ************************************************************************************************
:RESTAGE_PREPROD_FOR_ROLLBACK_II
@REM ************************************************************************************************

SET h5=!redbackground!

ECHO.
ECHO -------------------------------------------->>!devopslogname!
ECHO %TIME%: Restage application !extraspace!!nextactive!>>!devopslogname!
ECHO -------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.
ECHO   cf restage !nextactive!

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Restage !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Restage application !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_EMERGENCY_MENU
)

cf restage !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   **********************************************
ECHO   ******!redbackground! Please smoketest !nextactive!!extraspace! app !clearbackground!******
ECHO   **********************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open !nextactive! app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://!nextactive!.cloudapps.digital/
)

ECHO %TIME%: Restage application !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h5=!greenbackground!

IF "!menu_selection!"=="R" GOTO START_LIVE_FOR_ROLLBACK

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of RESTAGE_PREPROD_FOR_ROLLBACK_II
@REM ************************************************************************************************

@REM ************************************************************************************************
:START_LIVE_FOR_ROLLBACK
@REM ************************************************************************************************

SET h6=!redbackground!

ECHO.
ECHO ------------------------------------------>>!devopslogname!
ECHO %TIME%: Start application !extraspace!!nextactive!>>!devopslogname!
ECHO ------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.

ECHO   cf start !nextactive!

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Start !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Start application !nextactive! abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_EMERGENCY_MENU
)

cf start !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   **********************************************
ECHO   ******!redbackground! Please smoketest !nextactive!!extraspace! app !clearbackground!******
ECHO   **********************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open !nextactive! app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://!nextactive!.cloudapps.digital/
)

ECHO %TIME%: Start application !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h6=!greenbackground!

IF "!menu_selection!"=="R" GOTO SWITCH_ROUTE_TO_LIVE_FOR_ROLLBACK

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of START_LIVE_FOR_ROLLBACK
@REM ************************************************************************************************

@REM ************************************************************************************************
:SWITCH_ROUTE_TO_LIVE_FOR_ROLLBACK
@REM ************************************************************************************************

SET h7=!redbackground!

ECHO.
ECHO -------------------------------------------------------->>!devopslogname!
ECHO %TIME%: Switch route from sfcoffline to !extraspace!!nextactive!>>!devopslogname!
ECHO -------------------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.

ECHO   cf map-route !nextactive! cloudapps.digital -n sfcuat
ECHO   cf map-route !nextactive! skillsforcare.org.uk -n asc-wds
ECHO   cf unmap-route sfcoffline cloudapps.digital -n sfcuat
ECHO   cf unmap-route sfcoffline skillsforcare.org.uk -n asc-wds

ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Switch Route from sfcoffline to !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Switch Route from sfcoffline to !nextactive! abandoned - user choice>>!devopslogname!
    TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_EMERGENCY_MENU
)

cf map-route !nextactive! cloudapps.digital -n sfcuat>>!devopslogname! 2>&1
cf map-route !nextactive! skillsforcare.org.uk -n asc-wds>>!devopslogname! 2>&1
cf unmap-route sfcoffline cloudapps.digital -n sfcuat>>!devopslogname! 2>&1
cf unmap-route sfcoffline skillsforcare.org.uk -n asc-wds>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   ***************************************
ECHO   ******!redbackground! Please smoketest LIVE app !clearbackground!******
ECHO   ***************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open LIVE app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://asc-wds.skillsforcare.org.uk/
)

ECHO %TIME%: Switch Route from sfcoffline to !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul

SET h7=!greenbackground!

IF "!menu_selection!"=="R" GOTO STOP_OFFLINE_FOR_ROLLBACK

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of SWITCH_ROUTE_TO_LIVE
@REM ************************************************************************************************

@REM ************************************************************************************************
:STOP_OFFLINE_FOR_ROLLBACK
@REM ************************************************************************************************

SET h8=!redbackground!

ECHO.
ECHO ------------------------->>!devopslogname!
ECHO %TIME%: Stop offline>>!devopslogname!
ECHO ------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   This option will run the following:
ECHO.

ECHO   cf stop sfcoffline

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Stop sfcoffline - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Stop offline abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_EMERGENCY_MENU
)

cf stop sfcoffline>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO %TIME%: Stop offline completed>>!devopslogname!
TIMEOUT 2 >nul

SET h8=!greenbackground!

IF "!menu_selection!"=="R" GOTO REMOVE_URL_FOR_ROLLBACK

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of STOP_OFFLINE_FOR_ROLLBACK
@REM ************************************************************************************************

@REM ************************************************************************************************
:REMOVE_URL_FOR_ROLLBACK
@REM ************************************************************************************************

SET h9=!redbackground!

ECHO.
ECHO ------------------------------------------------------------>>!devopslogname!
ECHO %TIME%: Remove Route cloudapps.digital from !extraspace!!nextactive!>>!devopslogname!
ECHO ------------------------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

IF "!previousactive!" NEQ "sfcuatblue" (
    IF "!previousactive!" NEQ "sfcuatgreen" (
	
	    ECHO %TIME% sfcuatblue/sfcuatgreen not active>>!devopslogname!
        TIMEOUT 2 >nul
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
    	GOTO PROD_EMERGENCY_MENU
	)
)

ECHO   This option will run the following:
ECHO.

ECHO   cf unmap-route !nextactive! cloudapps.digital -n !nextactive!	

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Remove Route cloudapps.digital from !nextactive! - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Remove Route cloudapps.digital from !nextactive! abandoned - user choice>>!devopslogname!
    TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO PROD_EMERGENCY_MENU
)

cf unmap-route !nextactive! cloudapps.digital -n !nextactive!>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: Remove Route cloudapps.digital from !nextactive! completed>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET h9=!greenbackground!

IF "!menu_selection!"=="R" (
    SET completedmessage=Options 1-9 completed
	ECHO %TIME%: EMERGENCY MENU: !completedmessage!>>!devopslogname!
	TIMEOUT 2 >nul
)

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO PROD_EMERGENCY_MENU

@REM ************************************************************************************************
@REM End of REMOVE_URL_FOR_ROLLBACK
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM End of PROD_EMERGENCY_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:SANDBOX_MENU
@REM ************************************************************************************************

@REM ******************
@REM POWERSHELL command
@REM ******************

SET pwshcmd=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog ; $OpenFileDialog.initialDirectory = $Env:sfccerts ; $OpenFileDialog.ShowDialog()|out-null; $OpenFileDialog.FileName}"

CLS

@REM *********************
@REM Show the Sandbox menu
@REM *********************

ECHO.
ECHO                  !cyanbackground!SKILLS FOR CARE SANDBOX MENU (version !version!)!clearbackground!
ECHO                  ===========================================
ECHO.
ECHO   !h1!1 !clearbackground!) Do npm install and run build
ECHO   !h2!2 !clearbackground!) Set variables for !magentabackground!sfcanalysis!clearbackground!
ECHO   !h3!3 !clearbackground!) Update configs for !magentabackground!sfcanalysis!clearbackground! application
ECHO   !h4!4 !clearbackground!) Push application to !magentabackground!sfcanalysis!clearbackground!
ECHO   !h5!5 !clearbackground!) Update Dev Certs
ECHO   !h6!6 !clearbackground!) Update Staging Certs
ECHO.
ECHO   A  - Run options 1-4 (above) to deploy to sfcanalysis
ECHO.
ECHO   0  - Exit
ECHO.
ECHO   CURRENT SPACE: !currentspace!

IF "!testversion!"=="true" GOTO SKIP_LIVE_WARNING_SANDBOX

ECHO.
ECHO   !redbackground!WARNING: CLOUD FOUNDRY COMMANDS ACTIVE - THIS IS NOT A TEST VERSION!clearbackground!

:SKIP_LIVE_WARNING_SANDBOX

ECHO.

SET menu_selection=99
SET /P menu_selection=.!BS!  Enter selection: 

@REM ***********************
@REM Process the menu choice
@REM ***********************

IF !menu_selection! NEQ 0 (
    ECHO ==================================================================================================>>!devopslogname!
    TIMEOUT 2>nul)
	
IF !menu_selection!==1 (
    ECHO %TIME%: SANDBOX MENU: 1 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO NPM_INSTALL_AND_RUN_BUILD_ANALYSIS
)
IF !menu_selection!==2 (
    ECHO %TIME%: SANDBOX MENU: 2 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO SET_VARIABLES_ANALYSIS
)
IF !menu_selection!==3 (
    ECHO %TIME%: SANDBOX MENU: 3 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO UPDATE_CONFIGS_ANALYSIS
)
IF !menu_selection!==4 (
    ECHO %TIME%: SANDBOX MENU: 4 selected....>>!devopslogname!
	TIMEOUT 2 >nul
	GOTO PUSH_APPLICATION_ANALYSIS
)
IF !menu_selection!==5 (
    ECHO %TIME%: SANDBOX MENU: 5 selected....>>!devopslogname!
	TIMEOUT 2 >nul
    SET h5=!greenbackground!
    ECHO.
    ECHO ----------------------------->>!devopslogname!
	ECHO %TIME%: Update Dev Certs>>!devopslogname!
    ECHO ----------------------------->>!devopslogname!
	TIMEOUT 2 >nul
	
    ECHO.
    ECHO   *************************************************************************
    ECHO   ******!redbackground! Please update Cert variable for DEV via AWS Secrets Manager !clearbackground!******
    ECHO   *************************************************************************
    ECHO.

    SET openbrowser=
	SET /P openbrowser=.!BS!  Open AWS Secrets Manager ^(will open in a new window^)^? ^(Y/N^): 

    IF "!openbrowser!"=="Y" (
         start https://eu-west-1.console.aws.amazon.com/secretsmanager/home?region=eu-west-1#/secret?name=dev%%2Fapi
    )
	GOTO UPDATE_CERTS
)
IF !menu_selection!==6 (
    ECHO %TIME%: SANDBOX MENU: 6 selected....>>!devopslogname!
	TIMEOUT 2 >nul
    SET h6=!greenbackground!
    ECHO.
	ECHO -------------------------------->>!devopslogname!
	ECHO %TIME%: Update Staging Certs>>!devopslogname!
	ECHO -------------------------------->>!devopslogname!
	TIMEOUT 2 >nul
    ECHO.
    ECHO   *****************************************************************************
    ECHO   ******!redbackground! Please update Cert variable for STAGING via AWS Secrets Manager !clearbackground!******
    ECHO   *****************************************************************************
    ECHO.

    SET openbrowser=
	SET /P openbrowser=.!BS!  Open AWS Secrets Manager ^(will open in a new window^)^? ^(Y/N^): 

    IF "!openbrowser!"=="Y" (
         start https://eu-west-1.console.aws.amazon.com/secretsmanager/home?region=eu-west-1#/secret?name=staging%%2Fapi
    )
	GOTO UPDATE_CERTS
)
IF "!menu_selection!"=="A" (

    SET h1=
    SET h2=
    SET h3=
    SET h4=
	
	ECHO %TIME%: SANDBOX MENU: A selected to run options 1-4 for deployment to sfcanalysis>>!devopslogname!
	TIMEOUT 2 >nul

    GOTO NPM_INSTALL_AND_RUN_BUILD_ANALYSIS

)
IF "!menu_selection!"=="E" (

ECHO %TIME%: SANDBOX MENU: E selected>>!devopslogname!
TIMEOUT 2 >nul

@REM ***********************************************************
@REM Emergency offline html page only valid for production space
@REM ***********************************************************

SET camefrommenu=SANDBOX_MENU
SET camefromspace=!currentspace!
GOTO DEPLOY_OFFLINE_FOR_EMERGENCY
)

IF !menu_selection!==0 GOTO MAIN_MENU
TIMEOUT 2 >nul
CLS
GOTO SANDBOX_MENU

@REM ************************************************************************************************
@REM End of SANDBOX_MENU
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM SANDBOX_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:NPM_INSTALL_AND_RUN_BUILD_ANALYSIS
@REM ************************************************************************************************

SET h1=!redbackground!

ECHO.
ECHO ----------------------------------------->>!devopslogname!
ECHO %TIME%: Do npm install and run build>>!devopslogname!
ECHO ----------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   Checking GIT status.......

@REM **********************************************
@REM Check if current branch is test and up to date
@REM **********************************************

@REM ***************************************
@REM get the git info for the current branch
@REM ***************************************

git status >%TEMP%\gitstatusout.temp

ECHO.
ECHO GIT status:>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
TYPE %TEMP%\gitstatusout.temp>>!devopslogname!
TIMEOUT 2 >nul

SET currentrepo=nottest
SET currentrepouptodate=notuptodate
SET workingtreeclean=notclean

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "origin/test" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepo=test
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "up.to.date.with" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepouptodate=uptodate
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "nothing.to.commit..working.tree.clean" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET workingtreeclean=clean
)

IF "!currentrepo!" NEQ "test" (
	ECHO.
	ECHO   **************************************************************************
    ECHO   ******!redbackground! Current Branch is not test - please resolve before deploying !clearbackground!******
    ECHO   **************************************************************************
	ECHO.
	ECHO %TIME%: npm install and run build abandoned - current Branch is not test>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO SANDBOX_MENU)
	
IF "!currentrepouptodate!" NEQ "uptodate" (
    ECHO.
	ECHO   ********************************************************************************
    ECHO   ******!redbackground! Current Branch is not up to date - please resolve before deploying !clearbackground!******
    ECHO   ********************************************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: npm install and run build abandoned - current Branch is not up to date>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO SANDBOX_MENU
    )
	ECHO %TIME%: npm install and run build proceeding but current Branch is not up to date>>!devopslogname!
	TIMEOUT 2 >nul
)
	
IF "!workingtreeclean!" == "notclean" (
    ECHO.
	ECHO   *************************************************
    ECHO   ******!yellowbackground! WARNING - working tree is not clean !clearbackground!******
    ECHO   *************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: npm install and run build abandoned - current Branch is not clean>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO SANDBOX_MENU
    )
	ECHO %TIME%: npm install and run build proceeding but current Branch is not clean>>!devopslogname!
	TIMEOUT 2 >nul
)

ECHO.
ECHO   This option will run the following:

ECHO.
ECHO   npm install
ECHO   npm run build

ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Run npm install and build - are you sure^? ^(Y/N^): 
ECHO.
		
IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: npm install and run build abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO SANDBOX_MENU)

call npm install>>!devopslogname! 2>&1
call npm run build>>!devopslogname! 2>&1
TIMEOUT 2 >nul
ECHO.

ECHO %TIME%: npm install and run build completed>>!devopslogname!
TIMEOUT 2 >nul

SET h1=!greenbackground!

IF "!menu_selection!"=="A" GOTO SET_VARIABLES_ANALYSIS

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO SANDBOX_MENU

@REM ************************************************************************************************
@REM End of NPM_INSTALL_AND_RUN_BUILD
@REM ************************************************************************************************

@REM ************************************************************************************************
:SET_VARIABLES_ANALYSIS
@REM ************************************************************************************************

SET h2=!redbackground!

ECHO.
ECHO ------------------------------------------>>!devopslogname!
ECHO %TIME%: Set variables for sfcanalysis>>!devopslogname!
ECHO ------------------------------------------>>!devopslogname!
TIMEOUT 2 >nul

IF "!sfcstagesecretid!"=="" (
    ECHO.
	SET /P sfcstagesecretid=.!BS!  Enter AWS Secret ID for Staging: 
	SET areyousure=N
	SET /P areyousure=.!BS!  AWS Secret ID entered is !sfcstagesecretid! - please confirm correct^? ^(Y/N^): 
	IF "!areyousure!" NEQ "Y" (
	    ECHO.
        ECHO %TIME%: Set variables for !nextactive! abandoned - Incorrect AWS Secret ID>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
		GOTO SANDBOX_MENU
	)
)

IF "!sfcstagesecretkey!"=="" (
    ECHO.
	SET /P sfcstagesecretkey=.!BS!  Enter AWS Secret Key for Staging: 
	SET areyousure=N
	SET /P areyousure=.!BS!  AWS Secret Key entered is !sfcstagesecretkey! - please confirm correct^? ^(Y/N^): 
	IF "!areyousure!" NEQ "Y" (
	    ECHO.
        ECHO %TIME%: Set variables for !nextactive! abandoned - Incorrect AWS Secret Key>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
		SET /P continue=.!BS!  Press enter to continue:
		GOTO PREPROD_MENU
	)
)

ECHO.
ECHO   This option will run the following:
ECHO.

ECHO   cf set-env sfcanalysis AWS_ACCESS_KEY_ID !sfcstagesecretid!
ECHO   cf set-env sfcanalysis AWS_SECRET_ACCESS_KEY !sfcstagesecretkey!
ECHO   cf set-env sfcanalysis NODE_ENV test

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Set variables for sfcanalysis - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Set variables for sfcanalysis abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO SANDBOX_MENU
)

ECHO %TIME%: Updating cf variables for sfcanalysis>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
cf set-env sfcanalysis AWS_ACCESS_KEY_ID !sfcstagesecretid!
cf set-env sfcanalysis AWS_SECRET_ACCESS_KEY !sfcstagesecretkey!
cf set-env sfcanalysis NODE_ENV test

ECHO.
ECHO %TIME%: Set variables for sfcanalysis completed>>!devopslogname!
TIMEOUT 2 >nul

SET h2=!greenbackground!

IF "!menu_selection!"=="A" GOTO UPDATE_CONFIGS_ANALYSIS

ECHO.
SET /P continue=.!BS!  Press enter to continue: 
GOTO SANDBOX_MENU

@REM ************************************************************************************************
@REM End of SET_VARIABLES_PREPROD
@REM ************************************************************************************************

@REM ************************************************************************************************
:UPDATE_CONFIGS_ANALYSIS
@REM ************************************************************************************************

SET h3=!redbackground!

ECHO.
ECHO ------------------------------------------->>!devopslogname!
ECHO %TIME%: Update configs for sfcanalysis>>!devopslogname!
ECHO ------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul

ECHO.
ECHO   Checking GIT status.......

@REM **********************************************
@REM Check if current branch is live and up to date
@REM **********************************************

@REM ***************************************
@REM get the git info for the current branch
@REM ***************************************

git status >%TEMP%\gitstatusout.temp

ECHO.
ECHO GIT status:>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
TYPE %TEMP%\gitstatusout.temp>>!devopslogname!
TIMEOUT 2 >nul

SET currentrepo=nottest
SET currentrepouptodate=notuptodate
SET workingtreeclean=notclean

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "origin/test" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepo=test
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "up.to.date.with" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepouptodate=uptodate
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "nothing.to.commit..working.tree.clean" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET workingtreeclean=clean
)

IF "!currentrepo!" NEQ "test" (
	ECHO.
	ECHO   *************************************************************************
    ECHO   ******!redbackground! Current Branch is not test - please resolve before updating !clearbackground!******
    ECHO   *************************************************************************
	ECHO.
    ECHO %TIME%: Update configs for sfcanalysis abandoned - current Branch is not test>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO SANDBOX_MENU)
	
IF "!currentrepouptodate!" NEQ "uptodate" (
    ECHO.
	ECHO   *******************************************************************************
    ECHO   ******!redbackground! Current Branch is not up to date - please resolve before updating !clearbackground!******
    ECHO   *******************************************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: Update configs for sfcanalysis abandoned - current Branch is not up to date>>!devopslogname!
	    TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO SANDBOX_MENU
    )
	ECHO %TIME%: Update configs for sfcanalysis proceeding but current Branch is not up to date>>!devopslogname!
    TIMEOUT 2 >nul
)
	
IF "!workingtreeclean!" == "notclean" (
    ECHO.
	ECHO   *************************************************
    ECHO   ******!yellowbackground! WARNING - working tree is not clean !clearbackground!******
    ECHO   *************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: Update configs for sfcanalysis abandoned - current Branch is not clean>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO SANDBOX_MENU
    )
	ECHO %TIME%: Update configs for sfcanalysis proceeding but current Branch is not clean>>!devopslogname!
	TIMEOUT 2 >nul
)

SET mnpwshcmd=powershell -noprofile -command "(Get-Content 'manifest.test.yml') | foreach {$_ -replace 'name: .+$', 'name: sfcanalysis'} | Set-Content 'manifest.test.yml'"
SET ymlpwshcmd=powershell -noprofile -command "(Get-Content 'server\config\test.yaml') | foreach {$_ -replace 'database: .+$', 'database: sfcafrdb'} | Set-Content 'server\config\test.yaml'"

ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Update manifest.test.yml with sfcanalysis^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Update configs for sfcanalysis abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO SANDBOX_MENU
)

@REM ***************
@REM Update manifest
@REM ***************

!mnpwshcmd!

SET areyousure=N
SET /P areyousure=.!BS!  Check manifest.test.yml ^(should show sfcanalysis - opens in a new window^)^? ^(Y/N^): 
ECHO.

IF "!areyousure!"=="Y" notepad manifest.test.yml

@REM ECHO   *****************************************************************

ECHO %TIME%: Update manifest.test.yml with sfcanalysis completed>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Update server\config\test.yaml with sfcafrdb^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Update configs for sfcanalysis abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO SANDBOX_MENU
)

@REM ****************
@REM Update test.yaml
@REM ****************

!ymlpwshcmd!

SET areyousure=N
SET /P areyousure=.!BS!  Check server\config\test.yaml ^(should show sfcafrdb database - opens in a new window^)^? ^(Y/N^): 
ECHO.

IF "!areyousure!"=="Y" notepad server\config\test.yaml

@REM ECHO   *****************************************************************

ECHO %TIME%: Update configs for sfcanalysis completed>>!devopslogname!
TIMEOUT 2 >nul

SET h3=!greenbackground!

IF "!menu_selection!"=="A" GOTO PUSH_APPLICATION_ANALYSIS

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO SANDBOX_MENU

@REM ************************************************************************************************
@REM End of UPDATE_MANIFEST
@REM ************************************************************************************************

@REM ************************************************************************************************
:PUSH_APPLICATION_ANALYSIS
@REM ************************************************************************************************

SET h4=!redbackground!

ECHO.
ECHO -------------------------------------------->>!devopslogname!
ECHO %TIME%: Push application to sfcanalysis>>!devopslogname!
ECHO -------------------------------------------->>!devopslogname!
TIMEOUT 2 >nul
ECHO.

ECHO   Checking GIT status.......

@REM **********************************************
@REM Check if current branch is test and up to date
@REM **********************************************

@REM ***************************************
@REM get the git info for the current branch
@REM ***************************************

git status >%TEMP%\gitstatusout.temp

ECHO.
ECHO GIT status:>>!devopslogname!
TIMEOUT 2 >nul
ECHO.
TYPE %TEMP%\gitstatusout.temp>>!devopslogname!
TIMEOUT 2 >nul

SET currentrepo=nottest
SET currentrepouptodate=notuptodate
SET workingtreeclean=notclean

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "origin/test" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepo=test
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "up.to.date.with" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET currentrepouptodate=uptodate
)

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\gitstatusout.temp ^|findstr "nothing.to.commit..working.tree.clean" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET workingtreeclean=clean
)

IF "!currentrepo!" NEQ "test" (
	ECHO.
	ECHO   *************************************************************************
    ECHO   ******!redbackground! Current Branch is not test - please resolve before updating !clearbackground!******
    ECHO   *************************************************************************
	ECHO.
    ECHO %TIME%: Push application to sfcanalysis abandoned - current branch is not test>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
    SET /P continue=.!BS!  Press enter to continue: 
    GOTO SANDBOX_MENU)
	
IF "!currentrepouptodate!" NEQ "uptodate" (
    ECHO.
	ECHO   *******************************************************************************
    ECHO   ******!redbackground! Current Branch is not up to date - please resolve before updating !clearbackground!******
    ECHO   *******************************************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: Push application to sfcanalysis abandoned abandoned - current Branch is not up to date>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO SANDBOX_MENU
    )
	ECHO %TIME%: Push application to sfcanalysis proceeding but current Branch is not up to date>>!devopslogname!
	TIMEOUT 2 >nul
)
	
IF "!workingtreeclean!" == "notclean" (
    ECHO.
	ECHO   *************************************************
    ECHO   ******!yellowbackground! WARNING - working tree is not clean !clearbackground!******
    ECHO   *************************************************
	ECHO.
	SET areyousure=N
	SET /P areyousure=.!BS!  Ignore and continue^? ^(Y/N^): 
	ECHO.
    IF "!areyousure!" NEQ "Y" (
        ECHO %TIME%: Push application to sfcanalysis abandoned - current Branch is not clean>>!devopslogname!
		TIMEOUT 2 >nul
		ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
	    GOTO SANDBOX_MENU
    )
	ECHO %TIME%: Push application to sfcanalysis proceeding but current Branch is not clean>>!devopslogname!
	TIMEOUT 2 >nul
)

ECHO.
SET manifestpointsto=notvalid

FOR /F "tokens=* USEBACKQ" %%F IN (`type manifest.test.yml ^|findstr "name:" ^|findstr "sfcanalysis" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET manifestpointsto=sfcanalysis
)

IF "!manifestpointsto!"=="notvalid" (

    ECHO %TIME%: Push application to sfcanalysis not allowed: manifest.test.yml DOES NOT point to a the sfcanalysis app instance>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	ECHO   ****************************************************************************************************************
	ECHO   ******!redbackground! cf push not allowed: manifest.test.yml DOES NOT point to sfcanalysis app instance - please correct !clearbackground!******
	ECHO   ****************************************************************************************************************
	ECHO.
	SET /P continue=.!BS!  Press enter to continue: 
    GOTO SANDBOX_MENU
)

ECHO   This option will run the following:
ECHO.

ECHO   cf push -f manifest.test.yml
ECHO.

ECHO Latest commit:>>!devopslogname!
ECHO. >>!devopslogname!
git log -n 1 --graph>>!devopslogname!
ECHO. >>!devopslogname!
TIMEOUT 2 >nul

SET areyousure=N
SET /P areyousure=.!BS!  Push application - are you sure^? ^(Y/N^): 
ECHO.

IF "!areyousure!" NEQ "Y" (
    ECHO %TIME%: Push application to sfcanalysis abandoned - user choice>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO SANDBOX_MENU
)

ECHO %TIME%: Checking if database patches to be applied>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET areyousure=N
SET /P areyousure=.!BS!  Are there database patches to deploy^? ^(Y/N^): 
ECHO.
IF "!areyousure!"=="Y" (
	SET /P continue=.!BS!  Please ASK DBA to deploy patches to Staging database ^(Press enter to continue^): 
	ECHO.
	ECHO %TIME%: Database patches applied to Staging>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
)

cf push -f manifest.test.yml>>!devopslogname! 2>&1
TIMEOUT 2 >nul

ECHO.
ECHO   ******************************************************************************
ECHO   ******!redbackground! Please smoketest and notify client that the app is ready to test !clearbackground!******
ECHO   ******************************************************************************
ECHO.

SET openbrowser=
SET /P openbrowser=.!BS!  Open sfcanalysis app in browser ^(will open in a new window^)^? (Y/N): 
ECHO.

IF "!openbrowser!"=="Y" (
    START https://sfcanalysis.cloudapps.digital/
)

ECHO %TIME%: Push application to sfcanalysis completed>>!devopslogname!
TIMEOUT 2 >nul
ECHO.

SET h4=!greenbackground!

IF "!menu_selection!"=="A" (

    SET completedmessage=Options 1-4 completed
	ECHO %TIME%: SANDBOX MENU: !completedmessage!>>!devopslogname!
	TIMEOUT 2 >nul
	ECHO.
)

SET /P continue=.!BS!  Press enter to continue:
GOTO SANDBOX_MENU

@REM ************************************************************************************************
@REM End of PUSH_APPLICATION_ANALYSIS
@REM ************************************************************************************************

@REM ************************************************************************************************
:UPDATE_CERTS
@REM ************************************************************************************************

SET file_name=
ECHO.
SET updaterootcert=
SET /p updaterootcert=.!BS!  Update DB Root CRT^? ^(Y/N^): 

IF "!updaterootcert!"=="Y" (
    ECHO.
	ECHO   Select File...

@REM ***************************************************************
@REM Execute powershell command and get result in file_name variable
@REM ***************************************************************

    FOR /f "delims=" %%I IN ('%pwshcmd%') DO SET file_name=%%I

    ECHO.
    ECHO   File selected: !file_name!
	ECHO.
	SET certout=
	FOR /F "tokens=*" %%F IN (!file_name!) DO (
        SET linein=%%F
        SET certout=!certout!!linein!\n
	)
	
@REM *************
@REM remove spaces
@REM *************

	SET certout=!certout: =!
    SET certout=!certout:BEGINCERTIFICATE=BEGIN CERTIFICATE!
    SET certout=!certout:ENDCERTIFICATE=END CERTIFICATE!
	ECHO. !certout:~0,-2! 
	ECHO !certout:~0,-2!|clip
	ECHO.
    ECHO   Root cert formatted and copied to clipboard. Please paste into Secrets Manager: DB_ROOT_CRT
)

SET file_name=
ECHO.
SET updateuserkey=
SET /p updateuserkey=.!BS!  Update DB App User Key^? (Y/N): 

IF "!updateuserkey!"=="Y" (
    ECHO.
	ECHO   Select File...

@REM ***************************************************************
@REM Execute powershell command and get result in file_name variable
@REM ***************************************************************

    FOR /f "delims=" %%I in ('%pwshcmd%') DO SET file_name=%%I

    ECHO.
    ECHO   File selected: !file_name!
	ECHO.
	SET certout=
	FOR /F "tokens=*" %%F IN (!file_name!) DO (
        SET linein=%%F
		SET certout=!certout!!linein!\n
	)
	
@REM *************
@REM remove spaces
@REM *************

	SET certout=!certout: =!
    SET certout=!certout:BEGINRSAPRIVATEKEY=BEGIN RSA PRIVATE KEY!
    SET certout=!certout:ENDRSAPRIVATEKEY=END RSA PRIVATE KEY!
	ECHO. !certout:~0,-2! 
	ECHO !certout:~0,-2!|clip
	ECHO.
    ECHO   User key formatted and copied to clipboard. Please paste into Secrets Manager: DB_APP_USER_KEY
)

SET file_name=
ECHO.
SET updateusercert=
SET /p updateusercert=.!BS!  Update DB App User CRT^? (Y/N): 

IF "!updateusercert!"=="Y" (

    ECHO.
	ECHO   Select File...

@REM ***************************************************************
@REM Execute powershell command and get result in file_name variable
@REM ***************************************************************

    for /f "delims=" %%F IN ('%pwshcmd%') DO SET file_name=%%F

    ECHO.
    ECHO   File selected: !file_name!
	ECHO.
	SET certout=
	FOR /F "tokens=*" %%F IN (!file_name!) DO (
        SET linein=%%F
	    SET certout=!certout!!linein!\n

	)
	
@REM *************
@REM remove spaces
@REM *************

	SET certout=!certout: =!
    SET certout=!certout:BEGINCERTIFICATE=BEGIN CERTIFICATE!
    SET certout=!certout:ENDCERTIFICATE=END CERTIFICATE!
	ECHO. !certout:~0,-2! 
	ECHO !certout:~0,-2!|clip
	ECHO.
    ECHO   User cert formatted and copied to clipboard. Please paste into Secrets Manager: DB_APP_USER_CRT
)

ECHO.
ECHO %TIME%: Update Certs completed>>!devopslogname!
TIMEOUT 2 >nul

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO SANDBOX_MENU

@REM ************************************************************************************************
@REM End of UPDATE_CERTS
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM End of SANDBOX_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:LOG_CAPTURE_MENU
@REM ************************************************************************************************

CLS
ECHO Getting app status.......

@REM **************************************
@REM get the app info for the current space
@REM **************************************

cf apps >%TEMP%\cfappsoutput.temp

@REM ********************************
@REM Determine which instance is live
@REM ********************************

SET liveactive=not set
SET activemessage=^, LIVE ACTIVE: !redbackground!not set!clearbackground!

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatgreen" ^| find /v /c ""`) DO (
    SET var=%%F
)

IF "!var!"=="1" (
	SET liveactive=sfcuatgreen
	SET alternativeactive=sfcuatblue
	SET activemessage=^, LIVE ACTIVE: !greenbackground!sfcuatgreen!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcuatblue" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
    SET liveactive=sfcuatblue
	SET alternativeactive=sfcuatgreen
	SET activemessage=^, LIVE ACTIVE: !bluebackground!sfcuatblue!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfappsoutput.temp ^|findstr "skillsforcare.org.uk" ^|findstr "sfcoffline" ^| find /v /c ""`) DO (
	SET var=%%F
)

IF "!var!"=="1" (
	SET liveactive=sfcoffline
	SET activemessage=^, LIVE ACTIVE: !yellowbackground!sfcoffline!clearbackground!
)

SET livebinding=unknown
SET bindingmessage=^, LIVE BINDING: !redbackground!unknown!clearbackground!

@REM ***************************************
@REM get the binding info for the active app
@REM ***************************************

cf env !liveactive! >%TEMP%\cfenvoutput.temp

FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb01" ^| find /v /c ""`) DO (
    SET var=%%F
)
	
IF "!var!"=="1" (
    SET livebinding=sfcuatdb01
	SET bindingmessage=^, LIVE BINDING: !greenbackground!sfcuatdb01!clearbackground!
)
	
FOR /F "tokens=* USEBACKQ" %%F IN (`type %TEMP%\cfenvoutput.temp ^|findstr "instance_name" ^|findstr "sfcuatdb02" ^| find /v /c ""`) DO (
	SET var=%%F
)
	
IF "!var!"=="1" (
	SET livebinding=sfcuatdb02
	SET bindingmessage=^, LIVE BINDING: !redbackground!sfcuatdb02!clearbackground!
)

@REM *************************************
@REM Determine if log captures are running
@REM *************************************

tasklist >%TEMP%\tasklist.temp

SET bluepid=none
FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "bluecapture.exe" %TEMP%\tasklist.temp`) DO (
    SET bluepid=%%F
)

SET bluelogsrunning=true
IF "!bluepid!"=="none" SET bluelogsrunning=false

SET bluelogcapturemessage=LOG CAPTURE is !greenbackground!RUNNING!clearbackground!
IF "!bluelogsrunning!"=="false" SET bluelogcapturemessage=LOG CAPTURE is !redbackground!NOT RUNNING!clearbackground!

SET greenpid=none
FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "greencapture.exe" %TEMP%\tasklist.temp`) DO (
    SET greenpid=%%F
)

SET greenlogsrunning=true
IF "!greenpid!"=="none" SET greenlogsrunning=false

SET greenlogcapturemessage=LOG CAPTURE is !greenbackground!RUNNING!clearbackground!
IF "!greenlogsrunning!"=="false" SET greenlogcapturemessage=LOG CAPTURE is !redbackground!NOT RUNNING!clearbackground!

@REM **************************
@REM Work out current log_names
@REM **************************

SET cur_yy=%DATE:~8,2%
SET cur_mm=%DATE:~3,2%
SET cur_dd=%DATE:~0,2%
SET cur_hh=%TIME:~0,2%
SET cur_min=%TIME:~3,2%
SET thisday=!cur_yy!!cur_mm!!cur_dd!
@REM hisday=!cur_yy!!cur_mm!!cur_dd!!cur_hh!
SET bluelogname=%TEMP%\sfcuatblue_!thisday!.log
SET greenlogname=%TEMP%\sfcuatgreen_!thisday!.log

@REM ******************************
@REM Get log sizes and set messages
@REM ******************************

SET bluelog=none
SET greenlog=none

SET size=0
IF EXIST "!bluelogname!" (
    CALL :FILESIZE "!bluelogname!"
	SET bluelog=!bluelogname!
	)
SET bluelogmessage=, LOG: !bluelog! SIZE: !size! bytes

SET size=0
IF EXIST "!greenlogname!" (
    CALL :FILESIZE "!greenlogname!"
	SET greenlog=!greenlogname!
	)
SET greenlogmessage=, LOG: !greenlog! SIZE: !size! bytes

@REM *************************
@REM Show the Log Capture menu
@REM *************************

CLS
ECHO                  !cyanbackground!SKILLS FOR LOG CAPTURE MENU (version !version!)!clearbackground!
ECHO                  ==========================================
ECHO.
ECHO   !h1!1 !clearbackground!) Start !bluebackground!sfcuatblue!clearbackground! Log Capture
ECHO   !h2!2 !clearbackground!) Stop !bluebackground!sfcuatblue!clearbackground! Log Capture
ECHO   !h3!3 !clearbackground!) Start !greenbackground!sfcuatgreen!clearbackground! Log Capture
ECHO   !h4!4 !clearbackground!) Stop !greenbackground!sfcuatgreen!clearbackground! Log Capture
ECHO.
ECHO   0  - Exit
ECHO.
ECHO   CURRENT SPACE: !currentspace!!activemessage!!bindingmessage!
ECHO.
ECHO   !bluebackground!sfcuatblue!clearbackground! !bluelogcapturemessage!!bluelogmessage!
ECHO.
ECHO   !greenbackground!sfcuatgreen!clearbackground! !greenlogcapturemessage!!greenlogmessage!
ECHO.
ECHO   Logs can be located under %TEMP%

IF "!testversion!"=="true" GOTO SKIP_LIVE_WARNING_LOG

ECHO.
ECHO   !redbackground!WARNING: CLOUD FOUNDRY COMMANDS ACTIVE - THIS IS NOT A TEST VERSION!clearbackground!

:SKIP_LIVE_WARNING_LOG

ECHO.

SET menu_selection=99
SET /P menu_selection=.!BS!  Enter selection: 

@REM ***********************
@REM Process the menu choice
@REM ***********************

IF !menu_selection!==1 GOTO START_BLUE_LOG_CAPTURE
IF !menu_selection!==2 GOTO STOP_BLUE_LOG_CAPTURE
IF !menu_selection!==3 GOTO START_GREEN_LOG_CAPTURE
IF !menu_selection!==4 GOTO STOP_GREEN_LOG_CAPTURE
IF "!menu_selection!"=="E" (

ECHO ==================================================================================================>>!devopslogname!
ECHO %TIME%: LOG CAPTURE MENU: E selected>>!devopslogname!
TIMEOUT 2 >nul

@REM ***********************************************************
@REM Emergency offline html page only valid for production space
@REM ***********************************************************

SET camefrommenu=lOG_CAPTURE_MENU
SET camefromspace=!currentspace!
GOTO DEPLOY_OFFLINE_FOR_EMERGENCY
)

IF !menu_selection!==0 GOTO MAIN_MENU
TIMEOUT 2 >nul
CLS
GOTO LOG_CAPTURE_MENU

@REM ************************************************************************************************
@REM End of LOG_CAPTURE_MENU
@REM ************************************************************************************************

@REM ************************************************************************************************
@REM Start of LOG_CAPTURE_MENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:START_BLUE_LOG_CAPTURE
@REM ************************************************************************************************

@REM *************************************
@REM Check if log capture is still running
@REM *************************************

@REM ***********************************************************************************
@REM Get the PID for the running capture using tasklist (running a named copy of cf.exe)
@REM ***********************************************************************************

TASKLIST >%TEMP%\tasklist.temp

SET bluepid=none
FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "bluecapture.exe" %TEMP%\tasklist.temp`) DO (
    SET bluepid=%%F
)

SET bluelogsrunning=true
IF "!bluepid!"=="none" SET bluelogsrunning=false

IF "!bluelogsrunning!"=="true" (
        ECHO.
	    ECHO .!BS!  sfcuatblue Log Capture already running
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
    	GOTO LOG_CAPTURE_MENU
)

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Start Log Capture for sfcuatblue - are you sure^? ^(Y/N^): 

IF "!areyousure!" NEQ "Y" (
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO LOG_CAPTURE_MENU
)

@REM *****************************************************************************************************
@REM Copy the cf.exe program so that we can see the sfcuatblue log capture in the task list when we run it
@REM *****************************************************************************************************

COPY /Y "C:\Program Files\Cloud Foundry\cf.exe" %TEMP%\bluecapture.exe >nul 2>&1
ECHO.
ECHO   Starting sfcuatblue Log CAPTURE

@REM ***************************************************
@REM Create the script to run the sfcuatblue log capture
@REM ***************************************************

ECHO Setlocal EnableDelayedExpansion>%TEMP%\bluelogcapture.bat
ECHO SET cur_yy=%%DATE:~8,2%%>>%TEMP%\bluelogcapture.bat
ECHO SET cur_mm=%%DATE:~3,2%%>>%TEMP%\bluelogcapture.bat
ECHO SET cur_dd=%%DATE:~0,2%%>>%TEMP%\bluelogcapture.bat
ECHO SET cur_hh=%%TIME:~0,2%%>>%TEMP%\bluelogcapture.bat
ECHO SET cur_min=%%TIME:~3,2%%>>%TEMP%\bluelogcapture.bat
ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!>>%TEMP%\bluelogcapture.bat
@REM ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!^^!cur_hh^^!>>%TEMP%\bluelogcapture.bat
ECHO %%TEMP%%\bluecapture.exe logs sfcuatblue ^>^>%%TEMP%%\sfcuatblue_^^!thisday^^!.log>>%TEMP%\bluelogcapture.bat
ECHO exit >>%TEMP%\bluelogcapture.bat

@REM ***********************************************************************************
@REM Create the script to run the sfcuatblue log capture control (to manage log rolling)
@REM ***********************************************************************************

ECHO echo off>%TEMP%\bluelogcontrol.bat
ECHO Setlocal EnableDelayedExpansion>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_yy=%%DATE:~8,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_mm=%%DATE:~3,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_dd=%%DATE:~0,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_hh=%%TIME:~0,2%%>>%TEMP%\bluelogcapture.bat
ECHO SET cur_min=%%TIME:~3,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!>>%TEMP%\bluelogcontrol.bat
@REM ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!^^!cur_hh^^!>>%TEMP%\bluelogcontrol.bat
ECHO SET lastday=^^!thisday^^!>>%TEMP%\bluelogcontrol.bat
ECHO :LOOP>>%TEMP%\bluelogcontrol.bat
ECHO TASKLIST ^>%%TEMP%%\bluecontrollist.temp>>%TEMP%\bluelogcontrol.bat
ECHO SET bluepid=none>>%TEMP%\bluelogcontrol.bat
ECHO FOR /F "tokens=2 USEBACKQ" %%%%F IN (`findstr "bluecapture.exe" %%TEMP%%\bluecontrollist.temp`) DO SET bluepid=%%%%F>>%TEMP%\bluelogcontrol.bat
ECHO ECHO sfcuatblue Log Capture PID=^^!bluepid^^!>>%TEMP%\bluelogcontrol.bat
ECHO IF "^!bluepid^!"=="none" GOTO CONTROL_EXIT>>%TEMP%\bluelogcontrol.bat
ECHO IF "^!thisday^!" NEQ "^!lastday^!" (>>%TEMP%\bluelogcontrol.bat
ECHO cf target -s production>>%TEMP%\bluelogcontrol.bat
ECHO START /MIN %%TEMP%%^\bluelogcapture.bat sfcuatblue>>%TEMP%\bluelogcontrol.bat
ECHO TIMEOUT 2 ^>nul>>%TEMP%\bluelogcontrol.bat
ECHO TASKKILL /PID ^^!bluepid^^! /F)>>%TEMP%\bluelogcontrol.bat
ECHO SET lastday=^^!thisday^^!>>%TEMP%\bluelogcontrol.bat
ECHO TIMEOUT 10 ^>nul>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_yy=%%DATE:~8,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_mm=%%DATE:~3,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_dd=%%DATE:~0,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_hh=%%TIME:~0,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET cur_min=%%TIME:~3,2%%>>%TEMP%\bluelogcontrol.bat
ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!>>%TEMP%\bluelogcontrol.bat
@REM ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!^^!cur_hh^^!>>%TEMP%\bluelogcontrol.bat
ECHO GOTO LOOP>>%TEMP%\bluelogcontrol.bat
ECHO :CONTROL_EXIT>>%TEMP%\bluelogcontrol.bat
ECHO EXIT>>%TEMP%\bluelogcontrol.bat

START /MIN %TEMP%\bluelogcapture.bat sfcuatblue
TIMEOUT 1 >nul
START /MIN %TEMP%\bluelogcontrol.bat

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO LOG_CAPTURE_MENU

@REM ************************************************************************************************
@REM End of START_BLUE_LOG_CAPTURE
@REM ************************************************************************************************

@REM ************************************************************************************************
:STOP_BLUE_LOG_CAPTURE
@REM ************************************************************************************************

@REM *************************************
@REM Check if log capture is still running
@REM *************************************

@REM ***********************************************************************************
@REM Get the PID for the running capture using tasklist (running a named copy of cf.exe)
@REM ***********************************************************************************

TASKLIST >%TEMP%\tasklist.temp

SET bluepid=none
FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "bluecapture.exe" %TEMP%\tasklist.temp`) DO (
    SET bluepid=%%F
)

SET bluelogsrunning=true
IF "!bluepid!"=="none" SET bluelogsrunning=false

IF "!bluelogsrunning!"=="false" (
        ECHO.
	    ECHO .!BS!  sfcuatblueLog Capture NOT running
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
    	GOTO LOG_CAPTURE_MENU
)

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Stop Log Capture for sfcuatblue - are you sure^? ^(Y/N^): 

IF "!areyousure!" NEQ "Y" (
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO LOG_CAPTURE_MENU
)


ECHO.
ECHO Killing running sfcuatblue LOG CAPTURE task...
TASKKILL /PID !bluepid! /F

@REM *****************************************************************************************************************
@REM Now wait to give time for both the log capture and control tasks to terminate before deleting the generated files
@REM *****************************************************************************************************************

ECHO Stopping control task...
TIMEOUT 15 >nul
DEL %TEMP%\bluecapture.exe /f >nul 2>&1
DEL %TEMP%\bluelogcapture.bat /f >nul 2>&1
DEL %TEMP%\bluelogcontrol.bat /f >nul 2>&1

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO LOG_CAPTURE_MENU

@REM ************************************************************************************************
@REM End of STOP_BLUE_LOG_CAPTURE
@REM ************************************************************************************************

@REM ************************************************************************************************
:START_GREEN_LOG_CAPTURE
@REM ************************************************************************************************

@REM *************************************
@REM Check if log capture is still running
@REM *************************************

@REM ***********************************************************************************
@REM Get the PID for the running capture using tasklist (running a named copy of cf.exe)
@REM ***********************************************************************************

TASKLIST >%TEMP%\tasklist.temp

SET greenpid=none
FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "greencapture.exe" %TEMP%\tasklist.temp`) DO (
    SET greenpid=%%F
)

SET greenlogsrunning=true
IF "!greenpid!"=="none" SET greenlogsrunning=false

IF "!greenlogsrunning!"=="true" (
        ECHO.
	    ECHO .!BS!  sfcuatgreen Log Capture already running
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
    	GOTO LOG_CAPTURE_MENU
)

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Start Log Capture for sfcuatgreen - are you sure^? ^(Y/N^): 

IF "!areyousure!" NEQ "Y" (
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO LOG_CAPTURE_MENU
)

@REM ******************************************************************************************************
@REM Copy the cf.exe program so that we can see the sfcuatgreen log capture in the task list when we run it
@REM ******************************************************************************************************

COPY /Y "C:\Program Files\Cloud Foundry\cf.exe" %TEMP%\greencapture.exe >nul 2>&1
ECHO.
ECHO   Starting sfcuatgreen Log CAPTURE

@REM ****************************************************
@REM Create the script to run the sfcuatgreen log capture
@REM ****************************************************

ECHO Setlocal EnableDelayedExpansion>%TEMP%\greenlogcapture.bat
ECHO SET cur_yy=%%DATE:~8,2%%>>%TEMP%\greenlogcapture.bat
ECHO SET cur_mm=%%DATE:~3,2%%>>%TEMP%\greenlogcapture.bat
ECHO SET cur_dd=%%DATE:~0,2%%>>%TEMP%\greenlogcapture.bat
ECHO SET cur_hh=%%TIME:~0,2%%>>%TEMP%\greenlogcapture.bat
ECHO SET cur_min=%%TIME:~3,2%%>>%TEMP%\greenlogcapture.bat
ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!>>%TEMP%\greenlogcapture.bat
@REM ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!^^!cur_hh^^!>>%TEMP%\greenlogcapture.bat
ECHO %%TEMP%%\greencapture.exe logs sfcuatgreen ^>^>%%TEMP%%\sfcuatgreen_^^!thisday^^!.log>>%TEMP%\greenlogcapture.bat
ECHO exit >>%TEMP%\greenlogcapture.bat

@REM ************************************************************************************
@REM Create the script to run the sfcuatgreen log capture control (to manage log rolling)
@REM ************************************************************************************

ECHO echo off>%TEMP%\greenlogcontrol.bat
ECHO Setlocal EnableDelayedExpansion>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_yy=%%DATE:~8,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_mm=%%DATE:~3,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_dd=%%DATE:~0,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_hh=%%TIME:~0,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_min=%%TIME:~3,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!>>%TEMP%\greenlogcontrol.bat
@REM ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!^^!cur_hh^^!>>%TEMP%\greenlogcontrol.bat
ECHO SET lastday=^^!thisday^^!>>%TEMP%\greenlogcontrol.bat
ECHO :LOOP>>%TEMP%\greenlogcontrol.bat
ECHO TASKLIST ^>%%TEMP%%\greencontrollist.temp>>%TEMP%\greenlogcontrol.bat
ECHO SET greenpid=none>>%TEMP%\greenlogcontrol.bat
ECHO FOR /F "tokens=2 USEBACKQ" %%%%F IN (`findstr "greencapture.exe" %%TEMP%%\greencontrollist.temp`) DO SET greenpid=%%%%F>>%TEMP%\greenlogcontrol.bat
ECHO ECHO sfcuatgreen Log Capture PID=^^!greenpid^^!>>%TEMP%\greenlogcontrol.bat
ECHO IF "^!greenpid^!"=="none" GOTO CONTROL_EXIT>>%TEMP%\greenlogcontrol.bat
ECHO IF "^!thisday^!" NEQ "^!lastday^!" (>>%TEMP%\greenlogcontrol.bat
ECHO START /MIN %%TEMP%%^\greenlogcapture.bat sfcuatgreen>>%TEMP%\greenlogcontrol.bat
ECHO TIMEOUT 2 ^>nul>>%TEMP%\greenlogcontrol.bat
ECHO TASKKILL /PID ^^!greenpid^^! /F)>>%TEMP%\greenlogcontrol.bat
ECHO SET lastday=^^!thisday^^!>>%TEMP%\greenlogcontrol.bat
ECHO TIMEOUT 10 ^>nul>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_yy=%%DATE:~8,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_mm=%%DATE:~3,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_dd=%%DATE:~0,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_hh=%%TIME:~0,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET cur_min=%%TIME:~3,2%%>>%TEMP%\greenlogcontrol.bat
ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!^^>>%TEMP%\greenlogcontrol.bat
@REM ECHO SET thisday=^^!cur_yy^^!^^!cur_mm^^!^^!cur_dd^^!^^!cur_hh^^!>>%TEMP%\greenlogcontrol.bat
ECHO GOTO LOOP>>%TEMP%\greenlogcontrol.bat
ECHO :CONTROL_EXIT>>%TEMP%\greenlogcontrol.bat
ECHO EXIT>>%TEMP%\greenlogcontrol.bat

START /MIN %TEMP%\greenlogcapture.bat sfcuatgreen
TIMEOUT 1 >nul
START /MIN %TEMP%\greenlogcontrol.bat

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO LOG_CAPTURE_MENU

@REM ************************************************************************************************
@REM End of START_GREEN_LOG_CAPTURE
@REM ************************************************************************************************

@REM ************************************************************************************************
:STOP_GREEN_LOG_CAPTURE
@REM ************************************************************************************************

@REM *************************************
@REM Check if log capture is still running
@REM *************************************

@REM ***********************************************************************************
@REM Get the PID for the running capture using tasklist (running a named copy of cf.exe)
@REM ***********************************************************************************

TASKLIST >%TEMP%\tasklist.temp

SET greenpid=none
FOR /F "tokens=2 USEBACKQ" %%F IN (`findstr "greencapture.exe" %TEMP%\tasklist.temp`) DO (
    SET greenpid=%%F
)

SET greenlogsrunning=true
IF "!greenpid!"=="none" SET greenlogsrunning=false

IF "!greenlogsrunning!"=="false" (
        ECHO.
	    ECHO .!BS!  sfcuatgreenLog Capture NOT running
	    ECHO.
	    SET /P continue=.!BS!  Press enter to continue:
    	GOTO LOG_CAPTURE_MENU
)

ECHO.
SET areyousure=N
SET /P areyousure=.!BS!  Stop Log Capture for sfcuatgreen - are you sure^? ^(Y/N^): 

IF "!areyousure!" NEQ "Y" (
    ECHO.
	SET /P continue=.!BS!  Press enter to continue:
	GOTO LOG_CAPTURE_MENU
)

ECHO.
ECHO Killing running sfcuatgreen LOG CAPTURE task...
TASKKILL /PID !greenpid! /F

@REM *****************************************************************************************************************
@REM Now wait to give time for both the log capture and control tasks to terminate before deleting the generated files
@REM *****************************************************************************************************************

ECHO Stopping control task...
TIMEOUT 15 >nul
DEL %TEMP%\greencapture.exe /f >nul 2>&1
DEL %TEMP%\greenlogcapture.bat /f >nul 2>&1
DEL %TEMP%\greenlogcontrol.bat /f >nul 2>&1

ECHO.
SET /P continue=.!BS!  Press enter to continue:
GOTO LOG_CAPTURE_MENU

@REM ************************************************************************************************
@REM End of STOP_GREEN_LOG_CAPTURE
@REM ************************************************************************************************

@REM *************************************************************************************************
:FILESIZE
@REM *************************************************************************************************

@REM *************************************************************
@REM Set filesize of first argument in %size% variable, and return
@REM *************************************************************

SET size=%~z1
EXIT /b 0

@REM *************************************************************************************************
@REM End of FILESIZE
@REM *************************************************************************************************

@REM ************************************************************************************************
@REM End of LOG_CAPTUREMENU Options
@REM ************************************************************************************************

@REM ************************************************************************************************
:MENU_QUIT
@REM ************************************************************************************************

cf logout >NUL 2>&1

@REM ***************************
@REM Kill powershell log display
@REM ***************************

taskkill %sfcadminpspid% /F >NUL 2>&1

CLS
