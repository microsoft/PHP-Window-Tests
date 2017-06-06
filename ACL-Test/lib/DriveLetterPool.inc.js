/**
 * A global pool for available drive letters. Allows us to place holds on 
 * letters & get new letters without worrying about collisions. 
 * @class DriveLetterPool
 * @s
 */
var DriveLetterPool = new (Class.create({
	/**
	 * Create a hold and get the letter we're holding
	 * @param {Object|String} - an object to hold with
	 * @param {String} optional key - default DriveLetterPool._getNextAvailable()
	 * 
	 * @return {String} letter
	 */
	'createHold':	function DriveLetterPool_createHold(
						holdObject
					,	key // optional default find next available
					) {
						if( !Object.isUndefined( key ) ){
							if( !this._locks.hasOwnProperty( key ) ) {
								// the key does not exist in the pool
								Assert.Fail('LetterPool.createHold(): The drive letter you have specified is not valid.');
							}
							if( this._locks[key] || $$.fso.DriveExists( key ) ){
								Assert.Fail('LetterPool.createHold(): The drive letter you have specified is already locked or in use.');
							}
						} else {
							// get the next available key
							key = this._getNextAvailable();
						}
						
						this._locks[key]=holdObject;
						return key;
					}
	/**
	 * Release the specified hold
	 * @param {Object|String} holdObjectOrKey
	 * 
	 * @return {String} key
	 */
,	'releaseHold':	function DriveLetterPool_releaseHold(
						holdObjectOrKey
					) {
						// if a key is supplied, handle it.
						if( Object.isString(holdObjectOrKey) && holdObjectOrKey.length == 1) {
							if(!this._locks.hasOwnProperty( key ) ) {
								// the key does not exist in the pool
								Assert.Fail('LetterPool.releaseHold(): The drive letter you have specified is not valid.');
							}
							var key = holdObjectOrKey;
							if( !this._locks[key] ){
								Assert.Fail('LetterPool.releaseHold(): The drive letter you have specified is not locked.');
							}
						} else {
							var key = this._findLockByHoldObject( holdObjectOrKey );
						}
						this._locks[key]=false;
						
						return key;
					}
	/**
	 * Get an array of the current locks
	 * @return {Array}
	 */
,	'getLocks':		function DriveLetterPool_getLocks(){
						var locks = new Array();
						for(var letter in this._locks)
							if( this._locks[letter] )
								locks[locks.length]=letter;
						return locks;
					}
	/**
	 * Get the next available drive letter
	 * @return {String} Drive Letter
	 */
,	'_getNextAvailable':	
					function DriveLetterPool__getNextAvailable(){
						for(var Lk in this._locks){ 
							if( !this._locks[Lk] && !$$.fso.DriveExists( Lk ) ){
								return Lk;
							}
						}
						Assert.Fail('No Mount Points available in DriveLetterPool.');
					}
,	'_findLockByHoldObject':
					function DriveLetterPool__findLockByHoldObject(
						holdObject
					){
						for(var l in this._locks){
							if(this._locks[l]==holdObject){
								return l;
							}
						}
						Assert.Fail('The hold object specified is not holding any locks.');
					}
	/**
	 * Initialize: Build the pool
	 * @return {DriveLetterPool}
	 */
,	'initialize':	function DriveLetterPool_initialize(
					) { 
						this._locks = {};
						var letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').reverse();
						for(var Lk in letters) {
							var letter = letters[Lk];
							if( !$$.fso.DriveExists( letter + ':' ) ){
								this._locks[letter]=false;
							}
						}
						
						return this;
					}
}))();
