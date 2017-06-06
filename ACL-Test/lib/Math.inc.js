/**
 * Add an interface to Math.random() that takes a range as arguments.
 * @param {Integer} boundA 
 * @param {Integer} boundB
 * 
 * @return {Integer} a random number within the specified bounds. 
 */
Math.random.fromRange = function Math_random_fromRange(
	boundA //inclusive
,	boundB //non-inclusive
) {
	var spread = Math.abs( boundA - boundB )
	,	offset = ( boundA < boundB ? boundA : boundB )
	;
	
	return parseInt( ( Math.random() ) * spread ) + offset;						
};
