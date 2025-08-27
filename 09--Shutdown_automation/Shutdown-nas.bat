This is a clean, safe, one-click ShutdownNAS workflow and the exact shutdown-nas.bat to put on your Desktop. It uses SSH with an SSH key (public key auth) so it runs without prompting. Replace the placeholders and follow the steps exactly.

Important assumptions (you already did most of this earlier):

SSH key-based login is configured and working for the user you will use (test with ssh pi@<your Pi IP> and confirm no password prompt).

Sudo on the Pi allows that user to run shutdown without a password for the shutdown command (NOPASSWD for shutdown). If not, I include the check/fix below.

create the batch file on Desktop

1. Right-click on Desktop -> New -> Text Document
2. Rename the file to: shutdown-nas.bat
   (If it becomes shutdown-nas.bat.txt, remove the .txt extension.)
3. Right-click shutdown-nas.bat -> Edit


paste this exact script into the file (replace placeholders)

@echo off
rem shutdown-nas.bat
rem Replace the placeholders below before saving:
rem   <your Pi IP>  -> e.g. 192.168.0.113
rem   <ssh_user>    -> e.g. pi or your user
rem If your private key has a different name, update SSH_KEY accordingly.

set PI_IP=<your Pi IP>
set SSH_USER=<ssh_user>
set SSH_KEY="%USERPROFILE%\.ssh\id_rsa"
rem optional: uncomment if you use ed25519 name
rem set SSH_KEY="%USERPROFILE%\.ssh\id_ed25519"

echo Sending shutdown command to %SSH_USER%@%PI_IP% ...
rem try to send shutdown using key-only mode (no password prompt)
ssh -i %SSH_KEY% -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no %SSH_USER%@%PI_IP% "sudo shutdown -h now"
if %ERRORLEVEL%==0 (
    echo Shutdown command sent successfully.
    timeout /t 2 >nul
    exit /b 0
) else (
    echo Failed to send shutdown command.
    echo Possible causes:
    echo  - SSH key login not configured or wrong key path.
    echo  - sudo on the Pi requires a password for shutdown.
    echo  - Pi is unreachable (network).
    echo.
    echo Try this manual check:
    echo  1) Open PowerShell and run: ssh %SSH_USER%@%PI_IP%
    echo  2) If asked for a password, fix key-based auth first.
    echo.
    pause
    exit /b 1
)


save and close Notepad

test manually (before making Desktop pretty)

- Open PowerShell and run:
  & "%USERPROFILE%\Desktop\shutdown-nas.bat"

- Or double-click the shutdown-nas.bat on Desktop to test.
- Expect the Pi to begin shutdown; if nothing happens, use the troubleshooting hints below.


(optional) make a clickable shortcut with a nicer icon

1. Right-click shutdown-nas.bat -> Create shortcut
2. Right-click the shortcut -> Properties
   - Run: Minimized
   - Change Icon: choose a system icon or browse to a .ico file (e.g., shell32.dll has icons)
3. Move the shortcut to Desktop and delete the original .bat if you prefer using only the shortcut.


security & required pre-checks (do these BEFORE using the script)

A) Verify key-based SSH login works:
   From your PC run: ssh <ssh_user>@<your Pi IP>
   - If it asks for a password, public-key auth is not set up correctly.
   - Fix that first (see your public-key setup doc).

B) Verify sudo shutdown will not prompt for a password:
   From your PC run:
     ssh -i "%USERPROFILE%\.ssh\id_rsa" <ssh_user>@<your Pi IP> "sudo -n /sbin/shutdown -h now"
   - If it exits immediately with code 0, sudo NOPASSWD for shutdown is OK.
   - If it prints a sudo prompt or returns non-zero, add a sudoers rule on the Pi:

   On the Pi (run sudo visudo) add:
     <ssh_user> ALL=(ALL) NOPASSWD: /sbin/shutdown, /sbin/poweroff, /sbin/reboot

   Save and exit visudo. Now the shutdown command should work without prompting.


troubleshooting quick checklist

- If "Permission denied" or password prompt appears:
  - Ensure public key is in /home/<user>/.ssh/authorized_keys on Pi.
  - Ensure private key path in the .bat matches actual key name.
  - Ensure .ssh folder and authorized_keys permissions on Pi are correct:
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/authorized_keys

- If "Host key verification has changed" warning appears:
  - On the PC run: ssh-keygen -R <your Pi IP>
  - Then ssh <ssh_user>@<your Pi IP> once manually to accept the key.

- If network unreachable:
  - ping <your Pi IP>
  - confirm Pi is powered and network is up.

- If the script still fails, open PowerShell and run the ssh command inside the .bat manually to see detailed error.


tidy notes

- The script uses StrictHostKeyChecking=no to avoid the interactive host-key prompt on first run.
  If you prefer stronger security, remove that option and manually accept the host key by running:
    ssh <ssh_user>@<your Pi IP>
  once and typing "yes" to add the host key.

- Keep your private key secure. Do not share the .bat with others unless you removed the key option and it uses a loaded ssh-agent.

- If your Windows username contains spaces, using %USERPROFILE% in the script automatically handles that.
