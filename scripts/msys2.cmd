@ECHO ON

REM Can't do this in  powershell without throwing an error

REM Remove catgets to avoid conflict
bash --login -c "pacman -R --noconfirm catgets libcatgets"


REM Have to run multiple times
bash --login -c "pacman -Syuu --noconfirm"
bash --login -c "pacman -Syuu --noconfirm"
bash --login -c "pacman -Syuu --noconfirm"
bash --login -c "pacman -Syuu --noconfirm"
bash --login -c "pacman -Syuu --noconfirm"

@ECHO OFF
