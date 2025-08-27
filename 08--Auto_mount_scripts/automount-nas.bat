create the file (notepad method)

1. Right-click Desktop -> New -> Text Document
2. Rename the file to: automount-nas.bat
   (If Windows adds .txt, rename to automount-nas.bat and accept extension change)
3. Right-click automount-nas.bat -> Edit


paste this script into the file

@echo off
rem automount-nas.bat
rem Replace the placeholders below before saving:
rem   <your Pi IP>      -> IP address of your Pi (e.g. 192.168.0.113)
rem   <ShareName>       -> Samba share name (SoumyadeepNASPi)
rem   <smb_username>    -> Samba username (soumyadeep)
rem Recommended: store credentials in Windows Credential Manager first.
setlocal

set PI_IP=<your Pi IP>
set SHARE=\\%PI_IP%\<ShareName>
set DRIVE=Z:
set SMB_USER=<smb_username>

:wait_ping
ping -n 1 %PI_IP% >nul
if errorlevel 1 (
    timeout /t 10 >nul
    goto wait_ping
)

rem clear any stale mapping (ignore errors)
net use %DRIVE% /delete >nul 2>&1

rem try to map using stored credentials (Credential Manager) or prompt if not stored
net use %DRIVE% %SHARE% /user:%SMB_USER% /persistent:yes >nul 2>&1
if %ERRORLEVEL%==0 goto success

rem if mapping failed (likely no stored credentials), prompt for password (safer than embedding)
set /p SMB_PASS=Enter Samba password for %SMB_USER%: 
net use %DRIVE% %SHARE% /user:%SMB_USER% %SMB_PASS% /persistent:yes >nul 2>&1
if %ERRORLEVEL%==0 goto success

echo.
echo FAILED to map %DRIVE% to %SHARE%.
echo Check network, Samba user, or store credentials in Windows Credential Manager.
pause
exit /b 1

:success
echo %DATE% %TIME% - Mapped %DRIVE% to %SHARE% >> "%USERPROFILE%\automount-nas.log"
exit /b 0


save and close Notepad

move the file into the .ssh folder (as you requested)

- Open PowerShell (Run as your normal user, not admin) and run:

  Move-Item "$env:USERPROFILE\Desktop\automount-nas.bat" "$env:USERPROFILE\.ssh\automount-nas.bat"

- If the .ssh folder does not exist:
  New-Item -ItemType Directory -Path "$env:USERPROFILE\.ssh"
  then run the Move-Item command.


note: storing the script in .ssh is unusual but ok — script will live there. if you want it to auto-run at login, follow step 5.

make it run automatically at sign-in (recommended)

copy "$env:USERPROFILE\.ssh\automount-nas.bat" "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\automount-nas.bat"


this puts a copy in your Startup folder so Windows runs it at login.

if you prefer the script only in .ssh, you can double-click it to test manually.

test the script manually first

- Double-click: C:\Users\<YourUser>\.ssh\automount-nas.bat
- Or run from PowerShell:
  & "$env:USERPROFILE\.ssh\automount-nas.bat"
- Watch for mapping success. Check Z: in File Explorer.
- Check the log file: C:\Users\<YourUser>\automount-nas.log


secure credentials (recommended)

- Open Control Panel -> Credential Manager -> Windows Credentials -> Add a Windows credential
  - Internet or network address: \\<your Pi IP>
  - Username: <smb_username>
  - Password: <your smb password>

- With credentials stored, the script will map without prompting for the password.


optional: create scheduled task to run at system start (runs before login)

- Use Task Scheduler if you need the mapping before any user logs in.
- In Task Scheduler: Create Task -> Run whether user is logged on or not -> Trigger: At system startup or At log on -> Action: Start a program -> Program/script: C:\Windows\System32\cmd.exe -> Add arguments: /c "C:\Users\<YourUser>\.ssh\automount-nas.bat"
- If using system startup, store credentials in Credential Manager or Task Scheduler will need the user account/password.


troubleshooting quick tips

- If mapping fails: ping <your Pi IP> to confirm network.
- If prompt "The local device name is already in use": run net use Z: /delete then rerun script.
- If permission denied: check Samba user and smb.conf valid users and force user settings.
- If network not ready at login: script waits with ping loop, so leave it a minute and it should succeed.




