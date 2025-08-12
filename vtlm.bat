@echo off
#win 2022 Std: VDYBN-Z7WPP-V4HQT-9VMD4-VMK7H
#win 2019 Std: N69G4-B89J2-4G8F4-WWYCC-J464C
#win 2016 Std: WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
#win 2012 Std: D2N9P-3P6X9-2R39C-7RTCD-MDVJX
#win 2008 Std: TM24T-X9RMF-VWXK6-X8JQ9-BFGM2
#win 2008 R2 Std: YC6KT-GKW9T-YTKYR-T4X34-R7VHC
cscript //B "%windir%\system32\slmgr.vbs" /ipk VDYBN-Z7WPP-V4HQT-9VMD4-VMK7H
cscript //B "%windir%\system32\slmgr.vbs" /skms %1
cscript //B "%windir%\system32\slmgr.vbs" /ato
cscript //B "%windir%\system32\slmgr.vbs" /%1
