@echo off
del %temp%\lstVol?.txt
echo list volume>%temp%\lstVol.txt
del %temp%\lstVoltv.txt
diskpart /s %temp%\lstVol.txt>>%temp%\lstVoltv.txt
del %temp%\lstVolExt.txt
For /f "tokens=2 delims= " %%A in ('Type %temp%\lstVoltv.txt ^| find /i "Boot"') do echo select volume %%A>>%temp%\lstVolExt.txt
echo extend>>%temp%\lstVolExt.txt
echo exit>>%temp%\lstVolExt.txt
diskpart /s %temp%\lstVolExt.txt
del %temp%\lstVoltv.txt
del %temp%\lstVolExt.txt
del %temp%\lstVol.txt
