/**
 * Some functions, especially those that touch the filesystem, throw errors when they shouldn't. This 
 * extension to the Function prototype ensures that we give a function a fair shot at not throwing
 * an error, by calling it repeatedly with a sleep of 1/10 second in-between for up to 12 tries. 
 * 
 * Mortality Rate | Mortality Rate with 12 tries
 *            10% | 0.0000000001%
 *            25% | 0.000006%
 *            50% | 0.024%
 *            75% | 3.168%
 *            90% | 28.24%
 * 
 * Calculating the Mortality rate:
 *      n = 0 : M(n) = 0; 
 *      n > 0 : M(n) = ( ( 1 - M( n - 1 ) ) * M( 1 ) )
 * 
 * 
 * Use:
 * 		Instead of:
 * 			returnVal = functionName(arg1, arg2, arg3)
 * 		Do:
 * 			returnVal = functionName.withRetry(arg1, arg2, arg3)
 */
Function.prototype.withRetry = function( ){
	var retry = false;
	var limit = 12;
	var tries = 0;
	do {
		retry = false;
		tries++;
		try {
			var ret = this.apply( this, arguments );
		} catch (e) {
			if( tries < limit){
				WScript.Sleep(100);
				retry = true;
			} else {
				throw e;
			}
		}
	} while ( retry );
	
	return ret;
};
