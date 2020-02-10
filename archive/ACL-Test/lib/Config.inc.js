var config = new (Class.create({
	initialize: function( base ){
		this._config = {};
		if( base ) this.set( base );
	},
	set: function( path, obj ){
		var args = $A( arguments )
		,	conf = args.pop()
		;
		if( args.length ){
			this._set( this._getSubByPath( args.pop() ), conf )
		} else {
			this._set( this, conf );
		}
		return this;
	},
	_set: function( base, changes ){
		for( var key in changes ){
			var val = changes[key];
			if( Object.isArray(val) ){
				if( !( key in base ) ) base[key]=[];
				base[key]=base[key].concat(val);
			} else {
				if( !( key in base ) ) base[key]={};
				if ( (typeof(key)!='object')){
					base[key] = val;
				} else {
					this._set( base[key], val )
				}
			}
		}
	},
	_getSubByPath: function( path ){
		var route = path.split('.')
		,	base = this;
		;
		while( route.length ){
			var key = route.shift();
			WL(key);
			if( !( key in base ) ) base[key]={};
			base = base[key];
		}
		return base;
	}
}))();