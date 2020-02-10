var LOG = function( message, level ) {
	if( message === false)
		return message;
	for( var i = 0; i < config.logs.length; i++ ){
		config.logs[i].writeLine( message, level );
	}
}
// Use js.js's Function.Extend (note the capital E) to add stuff
// to Log without creating a new object like prototype.js's Object.extend()
LOG.Extend({
	'registerConstant':	function( constantName, constantValue ){
							if(typeof(constantValue)!='undefined'){
								this[constantName] = parseInt( constantValue );
							} else {
								if( !(this.simple) )
									this.simple = {};
								var i = Object.keys(this.simple).length;
								this[constantName] = this.simple[constantName] = Math.pow( 2, i );
								this.VERBOSE = ( Math.pow( 2, ( i + 1 ) ) - 1 );
							}
							return this[constantName];
						},
	'getOutputFileStream': function(){
							if( LOG._outputFileStream ) return LOG._outputFileStream;
							var logPath = config.output.file.path.Format();
							if( !$$.fso.FileExists( logPath ) ) {
								if( !$$.fso.FolderExists( logDir = $$.fso.GetParentFolderName( logPath ) ) )
									try { mkdirRecursive( logDir ); } catch (e) { Assert.Fail('Could not create log directory: {0}', logDir )}
								LOG._outputFileStream = $$.fso.CreateTextFile( logPath );
							} else {
								LOG._outputFileStream = $$.fso.OpenTextFile( logPath, 8 );
							}
							return LOG._outputFileStream;
						},
	getName: ConstantNamespace.prototype.getName,
	'closeAll': function(){
		for( var i = 0; i < config.logs.length; i++ ){
			if( config.logs[i]._isopen){
				config.logs[i]._close();
			}
		}
	},
	configure: function(key, val){
		for( var i = 0; i < config.logs.length; i++ ){
			if( Object.isFunction( config.logs[i].configure ) ){
				config.logs[i].configure( key, val );
			}
		}
	}
});
LOG.NONE = 0;
LOG.registerConstant( 'DEBUG' );
LOG.registerConstant( 'IMPORTANT' );

var LogHelper = Class.create({
	write: function( str, level ){
		if( this._iShouldWrite( level ) ){
			if(!this._isopen) this._open();
			this._write( str );
			return true;
		}
		return false;
	},
	writeLine: function( str, level ){
		return this.write( str + '\n', level );	
	},
	_iShouldWrite: function(loglevel){
		return Boolean( loglevel & this._loglevel )
	},
	_open: function(){
		this._isopen = true;	
	},
	_close: function(){
		this._isopen = false;	
	},
	initialize: function( loglevel ){
		this._loglevel = loglevel;
	}
})

LogHelper.Stream_Base = Class.create( LogHelper, {
	initialize: function( $super, stream, loglevel ){
		this._stream = stream;
		return $super( loglevel );
	},
	_write: function( str ){
		this._stream.Write( str );
	},
	_close: function( $super ){
		this._stream.Close();
		$super();
	}
});
LogHelper.Stream = Class.createLazyLoader( LogHelper.Stream_Base );

LogHelper.Console_Base = Class.create( LogHelper.Stream_Base, {
	initialize: function( $super, loglevel ){
		$super( WScript.StdOut, loglevel );
		this._open();
	},
	_close: function(){
		// block $super from getting called, as that will 
		// actually close the WScript.StdOut stream, sortof.
		// Not sure what it does since you can still use WScript.Echo(),
		// But it reports out-of-scope type errors.
	}
});
LogHelper.Console = Class.createLazyLoader( LogHelper.Console_Base );

LogHelper.File_Base = Class.create( LogHelper.Stream_Base, {
	initialize: function( $super, loglevel, filepath){
		var path = filepath.Format()
		,	parent = $$.fso.GetParentFolderName( filepath.Format() )
		;
		mkdirRecursive(parent);
		$super(
			$$.fso.CreateTextFile( filepath.Format() ),
			loglevel
		);
		this._open();
	}
});

LogHelper.File = Class.createLazyLoader( LogHelper.File_Base );

//LogHelper.Mail_Base = Class.create( LogHelper, {
LogHelper.Mail = Class.create( LogHelper, {
	initialize: function( $super, loglevel, params ){
		this._message = new Mailer.Message( params );
		return $super( loglevel );
	},
	_write: function( str ){
		this._message.body( str, true );
	},
	_close: function($super){
		(Mailer.fromConfig()).send( this._message );
		$super();
	},
	configure: function(key,val){
		this._message._configure(key,val);
	}
})
//LogHelper.Mail = Class.createLazyLoader( LogHelper.Mail_Base );
