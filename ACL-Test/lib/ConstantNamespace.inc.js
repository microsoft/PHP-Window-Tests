var ConstantNamespace = Class.create({
	'registerConstant':	function( 
							constantName, 
							constantValue 
						) {
							if( !Object.isUndefined( constantValue ) ) {
								this[constantName] = parseInt( constantValue ) ;
							} else {
								if( Object.isUndefined( this.simple ) ) {
									this.simple = {};
								}
								var i = Object.keys(this.simple).length;
								this[constantName] = this.simple[constantName] = Math.pow( 2, i );
								this.ALL = ( Math.pow( 2, ( i + 1 ) ) - 1 );
							}
							return this[constantName];
						}
	/**
	 * Get the simple name of the passed bit. 
	 * NOTE: Does not do complex or non-simple (combined) constants.
	 * @TODO: Add complex support.
	 * @param {Integer}
	 * 
	 * @return {String|Boolean} string on success, false on no match
	 */
,	'getName':			function(
							bit
						) {
							for( var k in this.simple ) {
								if( this.simple[k] == bit ) {
									return k;
								}
							}
							return false;
						}
});