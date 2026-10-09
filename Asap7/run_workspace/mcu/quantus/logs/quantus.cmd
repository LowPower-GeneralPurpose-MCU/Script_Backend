#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Sat Oct 10 00:46:10 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v23.14-s088_1 (64bit) 02/28/2025 12:25 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 23.14-s088_1 NR250219-0822/23_14-UB (database version 18.20.661) {superthreading v2.20}
#@(#)CDS: AAE 23.14-s018 (64bit) 02/28/2025 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 23.14-s036_1 () Feb 22 2025 01:17:26 ( )
#@(#)CDS: SYNTECH 23.14-s010_1 () Feb 19 2025 23:56:49 ( )
#@(#)CDS: CPE v23.14-s082
#@(#)CDS: IQuantus/TQuantus 23.1.1-s336 (64bit) Mon Jan 20 22:11:00 PST 2025 (Linux 3.10.0-693.el7.x86_64)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
getVersion
getVersion
getVersion
restoreDesign ./saved/top_soc_final.enc.dat top_soc
setMultiCpuUsage -acquireLicense 1 -localCpu 1
setDistributeHost -local
setExtractRCMode -engine postRoute -effortLevel high -coupled true
extractRC
rcOut -spef /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/quantus/outputs/top_soc_quantus_rc_typ.spef -rc_corner rc_typ
rcOut -spef /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/quantus/outputs/top_soc_quantus_rc_ss.spef -rc_corner rc_ss
rcOut -spef /home/user1/Desktop/Script_Backend/Asap7/run_workspace/mcu/quantus/outputs/top_soc_quantus_rc_ff.spef -rc_corner rc_ff
