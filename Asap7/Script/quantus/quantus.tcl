restoreDesign saved/Mul32_pnr.enc.dat Mul32

# Bóc t?m th?i d? Quantus ch?y mu?t, không luu l?i
deleteMetalFill -layer Pad

set qrc_tech_file "../tkvm/asap7/asap7sc7p5t_28/qrc/qrcTechFile_typ03_scaled4xV06"
update_rc_corner -name rccorner -qrc_tech $qrc_tech_file

setExtractRCMode -engine postRoute -effortLevel signoff -coupled true
setExtractRCMode -extract_rc_quantus_executable "/home/share_file/cadence/installs/DDI221/INNOVUS221/tools.lnx86/bin/qrc"
setExtractRCMode -qrcCmdType auto

extractRC
rcOut -spef ./outputs/Mul32_quan.spef -rc_corner rccorner
exit