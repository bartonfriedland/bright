from bright import fr_defaults
fr_params = fr_defaults()

#General Specifications
Quiet = False


#LWR Specifications                       
LWR_LibDir    =              "libs/LWR/"
LWR_BUd       =              51.0 
LWR_Batches   =              3 
LWR_P_NL      =              0.98 
                            
#LWR Storage                
LWR_SNF_Storage_Time        =  6
                            
#LWR Reprocessing                         
LWR_SE_U      =              0.999 
LWR_SE_NP     =              0.999 
LWR_SE_PU     =              0.999 
LWR_SE_AM     =              0.999 
LWR_SE_CM     =              0.999 
LWR_SE_CS     =              0.9999 
LWR_SE_SR     =              0.9999 
                            
#FR Specifications                        
fr_params.BUt = 176.6						#FR Burnup
fr_params.batches = 3						#Number of FR batches 
fr_params.pnl =  0.65		 				#FR Non-Leakage Probability
FR_LAN_FF_Cap =              0.0 * (10**-6)
                            
#FR Storage                 
FR_SNF_Storage_Time         = 3
                            
#FR Reprocessing                          
FR_SE_U       =              0.999 
FR_SE_NP      =              0.999 
FR_SE_PU      =              0.999 
FR_SE_AM      =              0.999 
FR_SE_CM      =              0.999 
FR_SE_CS      =              0.9999 
FR_SE_SR      =              0.9999 
