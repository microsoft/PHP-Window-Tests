Object.extend( 
	Date.prototype
,	(function(){
		/**
		 * Return an ISO-8601 date string
		 * @param {Boolean} sep default false - Whether or not to separate the chunks
		 * 
		 * @return {String}
		 */
		function iso8601date( sep ) {
			return [ this.getUTCFullYear().toString().pad(4,'0')
					,(this.getUTCMonth()+1).toString().pad(2,'0')
					,this.getUTCDate().toString().pad(2,'0')
			].join( sep ? '-' : '' );
		}
		
		/**
		 * Return an ISO-8601 time string
		 * @param {Boolean} sep default false - Whether or not to separate the chunks
		 * @param {Boolean} ms default false - Whether or not to show miliseconds
		 * 
		 * @return {String}
		 */
		function iso8601time( sep, ms ){
			return [ this.getUTCHours().toString().pad(2,'0')
					,this.getUTCMinutes().toString().pad(2,'0')
					,this.getUTCSeconds().toString().pad(2,'0')
			].join(sep?':':'') + ( !ms ? '' : ( '.' + this.getUTCMilliseconds() ) )
			;
		}
		
		/**
		 * Return an ISO-8601 full date
		 * @param {Boolean} sep default false - Whether or not to separate the chunks
		 * @param {Boolean} ms default false - Whether or not to show miliseconds
		 * 
		 * @return {String}
		 */
		function iso8601( sep, ms ) {
			return [ iso8601date.call( this, sep )
					,'T'
					,iso8601time.call( this, sep, ms )
					,'Z'
					].join('');
		}
		
		return {
			iso8601:iso8601
		};
	})()
)