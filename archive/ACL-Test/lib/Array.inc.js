/**
 * Litter the Array function namespace with functions relevant to Array objects.
 * Note that we are not extenging the Array prototype, as this "breaks" for..in looping,
 * but instead adding properties to the Array object itself.
 *
 * Every function's first argument should be the array to work with. 
 * 
 * To call a function defined here, do:
 * 
 * 		Array.valueExists( arrayObject, valueToLookFor );
 */ 
Array.Extend((function(){
	/**
	 * Determine how many times an item occurs in an array.
	 */
	function valueExists( arr, val ) {
		_ensureArrayType( arr );
		var l = arr.length;
		r = 0;
		for( var i = 0; i < l; i++ ) {
			if( arr[i] === val ) { r++ };
		}
		return r;		
	};
	
	/**
	 * Return items that are in all presented arrays
	 * @param {Array} arrA
	 * @param {Array} arrB
	 * @param {Array} optional arrC
	 * ...
	 * 
	 * @return {Array}
	 */
	function compare( arrA, arrB ) {
		var args = $A( arguments )
		,	A = (args.shift()).slice(0)
		;
		while( args.length ) {
			var B = (args.shift()).slice(0)
			,	C = []
			;
			for( var k in A ) {
				var item = A[k];
				for( var i = 0; i < B.length; i++ ) {
					if( item == B[i]  
						|| ( typeof(Object.equavalencyTest)=='function' &&  Object.equavalencyTest( item, B[i] ) ) 
					) {C.push( item )}
				}
			}
			A = C;
		}
		return A.slice(0);
	};
	
	/**
	 * Return items that are unique to the first array in the list
	 * @param {Array} arrA
	 * @param {Array} arrB
	 * @param {Array} optional arrC
	 * ...
	 * 
	 * @return {Array}
	 */
	function contrast( arrA, arrB ) {
		try {
		var args = $A( arguments )
		,	A = args.shift().slice(0)
		;
		while( args.length ) {
			var B = args.shift().slice(0)
			,	C = []
			;
			theloop:for( var k in A ) {
				var item = A[k];
				for( var i = 0; i < B.length; i++ ) {
					if( item == B[i]  
						|| ( typeof(Object.equavalencyTest)=='function' &&  Object.equavalencyTest( item, B[i] ) ) 
					) { continue theloop; }
				}
				C.push( item );
			}
			A = C;
		}
		return A.slice(0);
		} catch(e) {
			Assert.Fail(e.message);
		}
	};
	
	/**
	 * Return array of unique values.
	 * @param {Array} arr
	 * 
	 * @return {Array}
	 */
	function unique( arr ) {
		_ensureArrayType( arr );
		var a = arr.slice(0)
		,	b = []
		;
		theloop:for( var i = 0; i < a.length; i++ ) {
			for( var j = 0; j < b.length; j++ ) {
				if( a[i] == b[j] ) continue theloop;
			}
			b.push( a[i] );
		}
		return b;
	};
	
	
	function _ensureArrayType( arr ){
		if( !( arr instanceof Array ) )
			Assert.Fail( 'Object is not an Array.' );
	}
	
	function count_values( arr, val ){
		var count = 0;
		if( val instanceof Array ){
			for(var i = 0; i<arr.length; i++)
				count += Array.countValues( arr, val[i] );
			return count;
		}
		for(var i=0; i<arr.length; i++){
			if( arr[i] === val ) {
				count++;
				continue;
			}
			if( typeof( arr[i] )=='string' && ( val instanceof RegExp ) ){
				if( val.test( arr[i] ) ) count++;
				continue;
			}
		}
		return count;
	}

	return {
		'valueExists' : valueExists
	,	'compare'     : compare
	,	'contrast'    : contrast
	,	'unique'      : unique
	,	'countValues' : count_values
	};
})());


if( unitTest = ( typeof(unitTest)!='undefined' ? unitTest : false ) ) {
	(function ArrayExtensionsUnitTest () {
		( function Array_valueExists(){
			var a = [2,3,5,5,'foo','bar','bar']
			;
			Assert.Value( ( Array.valueExists( a, 1 ) == 0 ), 		'Missing integer reports present' );
			Assert.Value( ( Array.valueExists( a, 2 ) ),	 		'Present-once integer reports missing' );
			Assert.Value( ( Array.valueExists( a, 2 ) == 1 ), 		'Present-once integer reports incorrect quantity' );
			Assert.Value( ( Array.valueExists( a, 5 ) ), 			'Present-twice integer reports missing' );
			Assert.Value( ( Array.valueExists( a, 5 ) == 2 ), 		'Present-twice string reports incorrect quantity' );
			Assert.Value( ( Array.valueExists( a, 'str' ) == 0 ),	'Missing string reports present' );
			Assert.Value( ( Array.valueExists( a, 'foo' ) ),		'Present-once string reports missing' );
			Assert.Value( ( Array.valueExists( a, 'foo' ) == 1),	'Present-once string reports incorrect quantity' );
			Assert.Value( ( Array.valueExists( a, 'bar' ) ),		'Present-twice string reports missing' );
			Assert.Value( ( Array.valueExists( a, 'bar' ) == 2),	'Present-twice string reports incorrect quantity' );
			Assert.Value( ( !Object.isFunction( a.valueExists ) ), 	'function leaked into prototype');
			
			// Slightly more complex because we need to try..catch to determine if this passes/fails.
			Assert.Value( (function(){
				try {
					Array.valueExists( 'str', 'str' );
				} catch( e ) {
					if( e.message.match(/is not an Array/i)){ return true; }
				}
				return false;
			})(),'Non-array type does not properly throw error.' );
			
		})();
		
		( function Array_compare(){
			var a = [2,3,5,5,'foo','bar','bar']
			,	b = [2,5,6,'foo']
			,	c = [3,4,5,'bar']
			,	d = [1,7]
			;
			Assert.Value( ( Array.compare( a, b ).toString() == [2,5,5,'foo'].toString() ),	
																		'Failed: 2 Arrays, some overlap with repeat' );
			Assert.Value( ( Array.compare( b, a ).toString() == [2,5,5,'foo'].toString() ),	
																		'Failed: 2 Arrays, some overlap' );
			Assert.Value( ( Array.compare( a, b, c ).toString() == [5,5].toString() ),
																		'Failed: 3 arrays, some overlap' );
			Assert.Value( ( Array.compare( a, d ).toString() == [].toString() ),
																		'Failed: 2 arrays, no overlap' );
			Assert.Value( ( Array.compare( a, c, d ).toString() == [].toString() ),
																		'Failed: 3 arrays, no overlap' );
		})();
		
		( function Array_contrast(){
			var a = [2,3,5,5,'foo','bar','bar']
			,	b = [2,5,6,'foo']
			,	c = [3,4,5,'bar']
			,	d = [1,7]
			;
			Assert.Value( ( Array.contrast( a, b ).toString() == [3,'bar','bar'].toString() ),
																		'Failed: 2 Arrays, some overlap with repeat' );
			Assert.Value( ( Array.contrast( b, a ).toString() == [6].toString() ),
																		'Failed: 2 Arrays, some overlap' );
			Assert.Value( ( Array.contrast( a, b, c ).toString() == [].toString() ),
																		'Failed: 3 arrays, all overlap' );
			Assert.Value( ( Array.contrast( a, d ).toString() == a.toString() ),
																		'Failed: 2 arrays, no overlap' );
			Assert.Value( ( Array.contrast( a, c, d ).toString() == [2,'foo'].toString() ),
																		'Failed: 3 arrays, no overlap' );
		})();
		( function Array_unique(){
			var a = [2,3,5,5,'foo','bar','bar']
			,	b = [2,5,6,'foo','foo','foo','foo']
			,	c = [3,4,5,'bar']
			,	d = []
			;
			Assert.Value( ( Array.unique( a ).toString() == [2,3,5,'foo','bar'].toString() ),
																		'Failed: a' );
			Assert.Value( ( Array.unique( b ).toString() == [2,5,6,'foo'].toString() ),			
																		'Failed: b' );
			Assert.Value( ( Array.unique( c ).toString() == [3,4,5,'bar'].toString() ),
																		'Failed: c' );
			Assert.Value( ( Array.unique( d ).toString() == d.toString() ),
																		'Failed: d' );
		})();
	})();
}