/*
 * A collection of extensions on the native String object.
 */

/**
 * A non-destructive string padder. Returns the padded
 * string but does not modify the original.
 */
String.prototype.pad = function String_pad(
	width
,	padChar // = ' '
,	direction // = String.PAD_LEFT
) {
	if( this.length > width ) { return this + ''; }
	if( typeof( padChar ) == 'undefined' ) { padChar = ' '; }
	if( typeof( direction ) == 'undefined' ) { direction = String.PAD_LEFT; }
	switch( direction ) {
		case String.PAD_LEFT:
			return '' + ( new Array( width + 1 - this.length ).join( padChar ) ) + this;
		case String.PAD_RIGHT:
			return '' + this + ( new Array( width + 1 - this.length ).join( padChar ) ) ;
		case String.PAD_BOTH:
			return ( '' + this )
					.pad( ( Math.floor( ( width - this.length ) / 2 ) + this.length ), padChar, String.PAD_RIGHT )
					.pad( width, padChar, String.PAD_LEFT );
	}
};
String.PAD_LEFT = 1;
String.PAD_RIGHT = 2;
String.PAD_BOTH = 3;

/**
 * A non-destructive string trimmer.
 * Implementation takes hints from phpjs's MIT-licensed trim function:
 *   http://phpjs.org/functions/trim:566
 */
String.prototype.trim = function String_trim(
	whitespace /*=[lots and lots of characters]*/,
	direction /*=String.TRIM_BOTH*/ 
) {
	var str = '' + this;
	whitespace = whitespace || " \n\r\t\f\x0b\xa0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000"
	direction = direction || String.TRIM_BOTH;
	
	if( direction & String.TRIM_LEFT ){
		for( i = 0; i < str.length; i++){
			if( whitespace.indexOf( str.charAt(i) ) === -1 ) {
				str = str.substring(i);
				break;
			}
		}
	}
	if( direction & String.TRIM_RIGHT ) {
		for( i = str.length; i >=0; i-- ) {
			if( whitespace.indexOf( str.charAt(i) ) === -1 ) {
				str = str.substring( 0, i+1 );
				break;
			}
		}
	}
	return ( ( whitespace.indexOf(str.charAt(0)) === -1 ) ? str : '' );
}
String.prototype.rtrim = function String_rtrim( whitespace ){
	return this.trim( whitespace, String.TRIM_RIGHT );
}
String.prototype.ltrim = function String_ltrim( whitespace ){
	return this.trim( whitespace, String.TRIM_LEFT );
}

String.TRIM_LEFT =  0x01;
String.TRIM_RIGHT = 0x10;
String.TRIM_BOTH =  0x11;

/**
 * Non-destructively quote a string for use in a RegExp.
 */
String.prototype.quoteForRegExp = function String_quoteForRegExp( ) {
    return (this + '').replace(new RegExp('[.\\\\+*?\\[\\^\\]$(){}=!<>|:\\-]', 'g'), '\\$&');
}

/**
 * Make a 
 */
String.prototype.replaceAll = function String_replaceAll( find, replacement ){
	if( Object.prototype.toString.call(find) == '[object Array]' ) {
		var temp = ''+this;
		while( find.length ) temp = temp.replaceAll( find.shift(), replacement );
		return temp;
	}
	return this.replace( new RegExp( find.quoteForRegExp(),'g'), replacement );
}

/**
 * Non-destructively unquote a properly-quoted string. If a string begins and ends with a quote character, strip it and 
 * reduce the escape level of all other escaped quotes of the same type.
 */
String.prototype.unquote = function String_unquote(){
	// just return the string if the whole thing isn't quoted.
	if( !this.charAt(0).match(/['"]/)) return ( '' + this );// not quoted
	if( this.charAt(0) != this.charAt(this.length-1) ) return ( '' + this ) // f+l don't match, can't be properly quoted
	try {
		// Due to scoping restrictions, this is the fastest way I could think of to provide the
		// quote string to the anonymous function used by RegExp's replace. Instantiate an object with the quote string
		// so that the functions inside of it know what that quote string is. Messy, but it works.
		var quoteHelper = new (function(quoteChar){
			var quoter = quoteChar;
			this.replacer = function( sub, m1, offset, s ) {
				switch( m1 ){
					case '': 
						throw new Error('Last Quote is escaped! '+offset);
					case '\\':
					case quoter: 
						return m1;
					default: 
						return sub;
				}
			};
			this.pattern = /\\(.?)/g;
		})(this.charAt(0));
		
		return (this.slice(1,-1)).replace( quoteHelper.pattern, quoteHelper.replacer);
	} catch (e) {
		return ''+this;
	}
}

String.prototype.quote = function String_quote( quote /* ='"' */) {
	quote = quote||'"';
	var quoteHelper = new (function(quoteChar){
		var quoter = quoteChar;
		this.replacer = '\\$&'
		this.pattern = new RegExp('(\\\\|'+quoter+')','g');
	})(quote)
	return quote + (this.replace(quoteHelper.pattern,quoteHelper.replacer)) + quote;
}
