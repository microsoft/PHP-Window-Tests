Object.Extend((function(){
	/**
	 * Test the deep equavalency of two objects.
	 * @param {String|Number|Array|Boolean|Object}
	 * @param {String|Number|Array|Boolean|Object}
	 * 
	 * @return {Boolean}
	 */	
	function equavalencyTest( one, two ) {
		// face-value equal?
		if( one === two ) return true;
		
		// deep equal through iteration?
		if( typeof( one )=='object' && typeof( two )=='object' ) {
			if( one.constructor && one.constructor != two.constructor ) return false; // different constructors
			for( var k in one ) {
				if( equavalencyTest( one[k], two[k] ) ) continue;
				return false; // mismatch fount
			}
			for( var k in two ) {
				if( equavalencyTest( one[k], two[k] ) ) continue;
				return false; // mismatch found
			}
			// no mismatches found
			return true;
		}
		// not an object to iterate into and not face-value equal.
		return false;
	}

	return {
		'equavalencyTest':	equavalencyTest
	}
})());