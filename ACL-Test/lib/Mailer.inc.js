var Mailer = Class.create({
	initialize: function( args ){
		Assert.Executable('blat.exe');
		this.config = {};
		for( var k in args ) {
			this._configure( k, args[k] );
		}
	}
,	_configure: function( key, val ){
		this.config[key] = val;
	}
,	_isConfigured: function( key ){
		return this.config[key] || false;
	}
,	send: function( mailMessage ){
		var tmp
		;
		if( !( mailMessage instanceof Mailer.Message ) )
			Assert.Fail( 'Mailer::send() requires 1 argument of type Mailer_Message' );
		if( !mailMessage.ready() )
			Assert.Fail( 'MailMessage not ready: ' + mailMessage.missingRequirements() );
		
		var command = [];
		if( this._isConfigured('server') ) command.push( '-server "{0}"'.Format( this.config.server ) )
		if( this._isConfigured('port') ) command.push( '-port "{0}"'.Format( this.config.port ) )
		if( this._isConfigured('from') ) {
			command.push( '-f "{0}"'.Format( this.config.from ) )
			command.push( '-from "{0}"'.Format( this.config.from ) )
		}
		
		function escapeDoubleQuotes(str){
			return str.replace(/[\\"]/g, '\\$&');
		}
		
		for( var type in mailMessage.config.recipients ) {
			if(mailMessage.config.recipients[type].length)
				command.push( '-{0} "{1}"'.Format( type, escapeDoubleQuotes( mailMessage.config.recipients[type].join(',') ) ) )
		}
		
		command.push('-subject "{0}"'.Format( escapeDoubleQuotes( mailMessage.config.subject ) ) )
		if( mailMessage.config.body.length < 500 ){
			command.push('-body "{0}"'.Format( escapeDoubleQuotes( mailMessage.config.body ) ) );
			command.unshift('-');
		} else {
			tmp=$$.fso.GetTempName();
			var tmpS = $$.fso.CreateTextFile(tmp);
			tmpS.Write( mailMessage.config.body );
			tmpS.Close();
			
			command.unshift(tmp);
		}
		
		if( mailMessage.config.attachments.length ){
			for( var i =0; i < mailMessage.config.attachments.length; i++ ){
				command.push( '-attach "{0}"'.Format( mailMessage.config.attachments[i] ) )
			}
			command.push( '-base64' )
		}
		

		$$('blat.exe {0}'.Format(command.join(' ')));
		
		erase( tmp )
		
		return ( $ERRORLEVEL ? false : true );
	}
});
Mailer.fromConfig = (function(){
	var __mailer;
	return function(){
		var __mailer;
		if( Object.isUndefined( __mailer ) ){
			return __mailer = new Mailer( config.mail );
		}
		return __mailer;
	}
})()

Mailer.Message = Class.create({
	initialize: function(args){
		this.config = {
				recipients: {
					to: [],
					cc: [],
					bcc: []
				},
				attachments:[],
				subject:'',
				body:''
			}
		for( var k in args ) {
			this._configure( k, args[k] );
		}
	}
,	_configure: function( key, val ){
		switch( key ){
			case 'to':
			case 'cc':
			case 'bcc':
				this._addRecipients( key, val );
				break;
			case 'subject': 
				this.subject( val );
				break;
			case 'body':
				this.body( val );
				break;
			case 'attach':
			case 'attachment':
				this.attach( val );
				break;
			default:
				Assert.Fail( 'Unknown configuration key [{0}]', key );
		}
	}
,	to: function( recipients ){ this._addRecipients('to', recipients ); return this; }
,	cc: function( recipients ){ this._addRecipients('cc', recipients ); return this; }
,	bcc: function( recipients ){ this._addRecipients('bcc', recipients ); return this; }

,	body: function( str, append /*=false*/ ){
		if( !( append || false ) ) this.config.body = '';
		this.config.body += this._parseArgumentValue( str );
		return this;
	}
,	subject: function( str ){
		this.config.subject = this._parseArgumentValue( str );
		return this;
	}
,	attach: function(paths){
		if( paths.constructor.toString().indexOf("Array") == -1 )
			paths = [paths];
		
		while(paths.length)
			this.config.attachments.push( paths.shift() );
		
		return this;
	}
,	_addRecipients: function( key, recipients ){
		if( recipients.constructor.toString().indexOf("Array") == -1 )
			recipients = recipients.split(/[,;]/g);
		
		while( recipients.length ) {
			this.config.recipients[key].push( recipients.shift() );
		}
	}
,	_parseArgumentValue: function( str ){
		if( str.indexOf('@')!=0 ) return str;
		
		Assert.Fail('File Descriptors not supported in this version.')
	}
,	ready: function(){
		return !Boolean( this.missingRequirements().length );
	}
,	missingRequirements: function() {
		var ret = [];
		if( this.config.recipients.to.length == 0) ret.push('Recipient: To');
		if( this.config.body.length == 0) ret.push('Body');
		if( this.config.subject.length == 0) ret.push('Subject');
		return ret;
	}
});