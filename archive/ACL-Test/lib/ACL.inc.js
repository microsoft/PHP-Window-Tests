function WL(l){WScript.StdOut.WriteLine(l);return l;}
var REDUCE = new ConstantNamespace();
REDUCE.registerConstant('REPEAT_INHERITED');
REDUCE.registerConstant('CANCEL_DIRECT');
REDUCE.registerConstant('CANCEL_INHERITED');


// ACL
var ACL = new (Class.create(ConstantNamespace,{
	/**
	 * Test an ACE
	 */
	'test':		function(
					testEffective,
					ACE
				) {
					do {
						if( ACE.isDenied( testEffective ) ) return false;
						if( ACE.isGranted( testEffective ) ) return true;
					} while( ( ACE.parent instanceof AccessControlEntry ) && (ACE = ACE.parent) );
					return true;
				},
	'registerConstant': function(
					$super,
					constantName,
					constantValue
				) {
					$super( constantName, constantValue );
					delete( this.ALL );
				},
	'collide':	function(
					test,
					includeBit /*=false*/
				) {
					if( Object.isUndefined( includeBit ) ) includeBit = false;
					
					var all = this.getAll( includeBit ? undefined : function(s){ return !( /_BIT/.test(s) )} )
					
					for( var k in all ) {
						if(! ( test & all[k] ) )
							delete all[k];
					}
					
					return all;
				},
	'get':		function(
					name
				){
					return this[name];
				},
	'getAll':	function(
					matchFunction
				) { 
					if( Object.isUndefined( matchFunction ) ) 
						matchFunction = function(){return true;};
					var ret = {};
					for( var k in this) {
						if( k==k.toUpperCase() && matchFunction(k) )
							ret[k] = this[k];
					}
					ret.toString = function(){
						var ret = '';
						for( var k in this ){
							ret += k+':'+this[k]+'\n';
						}
						return ret;
					};
					return ret;
				},
	/**
	 * Run a callback function in the context of every selected permutation.
	 * @param {String} directory_root - where you want the ACL structure to be built
	 * @param {Array|Object} return_object - should implement push(),length,and pop()
	 * @param {Function} callback_function( build_path, ace_directives, optional_params )
	 * @param {Object} callback_arguments - passed unmodified to callback_function as optional_params
	 * @param {Object} params; acceptable keys are:
	 *    reduction - bitwise value reducing out certain knon-cancelling permutations.
	 * 	  no_set  - true if we do *not* set ACLs before calling callback_function 
	 */
	permute: function( directory_root, callback_function, callback_arguments, params ){
		var availablePerms = new Array,
			return_object = [],
			permList = this.collide( ACL.FULL ),
			actionList = ['GRANT','DENY'],
			targetList = ['INHERIT','DIRECT'];
		
		// Build up our permList
		for( var p in permList ) {
			for( var a in actionList ) {
				for( var t in targetList ) {
					var perm = {
								'PERM'    : p,
								'ACTION'  : actionList[a],
								'TARGET'  : targetList[t],
								'toString': function(){
												return ( this.TARGET+ ':' +this.ACTION + ' ' + this.PERM ) 
											}
							}
					availablePerms.push(perm);
					//WL( targetList[t] + ' ' + actionList[a] + ' ' + p );
				}
			}
		}
		
		// supply recursive args to recursive _permute function
		this._permute( directory_root, return_object, callback_function, callback_arguments, params, availablePerms );
		
		return return_object;
	},

	/**
	 * Internal code to actually do the permutations, along with reductions
	 * @param {String} directory_root - where you want the ACL structure to be built
	 * @param {Array|Object} return_object - should implement push(),length,and pop()
	 * @param {Function} callback_function( build_path, ace_directives, optional_params )
	 * @param {Object} callback_arguments - passed unmodified to callback_function as optional_params
	 * @param {Object} params; acceptable keys are:
	 *    reduction - bitwise value reducing out certain knon-cancelling permutations.
	 * 	  no_set  - true if we do *not* set ACLs before calling callback_function
	 * @param {Array} available_perms - a list of perms that have not been applied
	 * @param {Array} applied_perms - a list of perms that have been applied
	 */
	_permute: function( directory_root, return_object, callback_function, callback_arguments, params, available_perms, applied_perms ){
		applied_perms = applied_perms || [];
		var reduction = ( 'reduction' in params ? params.reduction : 0 )
		,	do_setup = !( 'no_set' in params ? params.no_set : false )
		;

		// clone input param stacks
		var av_perms = available_perms.slice(0);
		var ap_perms = applied_perms.slice(0);
		
		if( av_perms.length ){ // we have more available perms. go deeper.
			var top_perm = av_perms.pop();

			//descend without
			this._permute(
				directory_root,
				return_object,
				callback_function,
				callback_arguments,
				params,
				av_perms,
				ap_perms
			);
			
			// descend with
			this._permute(
				directory_root,
				return_object,
				callback_function,
				callback_arguments,
				params,
				av_perms,
				ap_perms.concat([top_perm])
			);
		} else {
			// no more available perms. sets are final.
			var parentACE = new AccessControlEntry( directory_root )
			,	childACE = new AccessControlEntry( parentACE )
			;
			for( var k in ap_perms ){
				var targetACE = ( ap_perms[k].TARGET=='DIRECT' ? childACE : parentACE );
				switch(ap_perms[k].ACTION){
					case 'GRANT':
						targetACE.grant( ap_perms[k].PERM );
						break;
					case 'DENY':
						targetACE.deny( ap_perms[k].PERM );
						break;
					default:
				}
			}
			
			// If specified, skip sets with inheritances that are repeated as directs.
			// e.g., if a GRANT READ is inherited, the inheritance is moot if the child also has a GRANT READ.
			if( REDUCE.REPEAT_INHERITED & reduction ){
				for( var p0 in ap_perms ){
					if( ap_perms[p0].TARGET == 'INHERIT'){
						for( var p1 in ap_perms ){
							if( ap_perms[p1].TARGET == 'DIRECT' && 
									ap_perms[p1].PERM == ap_perms[p0].PERM && 
									ap_perms[p1].ACTION == ap_perms[p0].ACTION 
							) {
								return_object.push(null)
								LOG( 'SKIP: INHERITED GRANT {0} IS IGNORED WHEN DIRECT GRANT {0} IS PRESENT'.Format( ap_perms[p0].PERM ),
									LOG.ACL_PERMUTATION_SKIP
								);
								return null;
							}
						}
					}
				}

			}
			
			// if we're granting something that also has a same-level deny, it has no effect.
			// e.g. a DIRECT GRANT READ is *always* overriden by DIRECT DENY READ
			if( REDUCE.CANCEL_DIRECT & reduction ){
				for( var p0 in ap_perms ){
					if( ap_perms[p0].ACTION=='GRANT') {
						for( var p2 in ap_perms ) {
							if(ap_perms[p2].ACTION == 'DENY' && 
									ap_perms[p2].PERM == ap_perms[p0].PERM && 
									ap_perms[p2].TARGET == ap_perms[p0].TARGET  
							) {
								return_object.push(null)
								LOG( 'SKIP: GRANT {0} NEVER OVERRIDES A DENY {0} ON THE SAME OBJECT'.Format( ap_perms[p0].PERM ),
									LOG.ACL_PERMUTATION_SKIP
								);
								return null;
							}
						}
					}
				}
			}
			
			// if we're granting something that also inherits a denial of the same kind, skip it
			// e.g. a INHERITED DENY READ is *always* overriden by DIRECT GRANT READ
			if( REDUCE.CANCEL_INHERITED & reduction ){
				for( var p0 in ap_perms ){
					if( ap_perms[p0].TARGET=='INHERIT' && ap_perms[p0].ACTION=='DENY') {
						for( var p2 in ap_perms ) {
							if(ap_perms[p2].PERM == ap_perms[p0].PERM &&
									ap_perms[p2].ACTION == 'GRANT' && 
									ap_perms[p2].TARGET == 'DIRECT'
							) {
								return_object.push(null)
								LOG( 'SKIP: DIRECT GRANT {0} ALWAYS OVERRIDES AN INHERITED DENY {0}'.Format( ap_perms[p0].PERM ),
									LOG.ACL_PERMUTATION_SKIP
								)
								return null;
							}
						}
					}
				}
			}

			// This perm set is an affector.
			var setup_target = null;
			if( do_setup ){
				var setup_target = childACE.generate();
			}

			var return_value = callback_function( setup_target, childACE, callback_arguments );

			if( do_setup ) childACE.destroy();
			
			return_object.push( return_value )
		}
	},
	/**
	 * Example format of callback_function
	 * @param {String} target - path to the target file
	 * @param {AccessControlObject} ace - the ACE that has been applied
	 * @param {params} the callback_arguments from the original ACL.permute function call
	 *
	 * @return {Object|String|Null} - something that can be push()'d onto ACL.permute's return_object 
	 */
	examples: {
		is_readable: function( target, ace, params ){
			try{
				with( $$.fso.OpenTextFile( target, 1 ) ) {
					var cont = ReadAll()
					close();
				}
			} catch(e){
				var cont = null;
			}
			var readable = Boolean(cont)
			//,	expected = ( R = ACL.test( ACL.READ, ace ) )
			,	expected = ace.is_readable()
			;

			//WL( readable + '\t' + expected );
			return ACL._assert( 'READABLE', readable, expected, ace );
		},
		bogus_errors: function( target, ace, params ){
			var result = Boolean(Math.round(Math.random()))
			,	expected = Boolean(Math.round(Math.random()))
			;
			
			return ACL._assert( 'BOGUS', result, expected, ace );
		},
		is_writable: function( target, ace, params ){
			try{
				$$('cmd /C "echo ' + ( new Date ).getTime() + ' >> ' + file + '"');
				var writable = !Boolean( $StdErr.length );
			} catch (e) {
				var writable = false;
			}

			//var expected = ( ACL.test( ACL.WRITE, ace ) && 
			//					( 	ACL.test( ACL.READ, ace ) || 
			//						ACL.test( ACL.READ, ace.parent ) )
			//					)
			var	expected = ace.is_writable()
			;
			//WL( writable + '\t' + expected );
			return ACL._assert( 'WRITABLE', writable, expected, ace );
		}
	},
	_assert: function( desc, actual, expected, ace ){
		var ret = [];
		ret.push( 'Expected: ' + expected );
		ret.push( 'Actual:   ' + actual );
		ret.push( ' ACL '.pad(40,'-',String.PAD_BOTH) );
		ret.push( ace.toString() );
		ret.push( ''.pad(40,'-',String.PAD_BOTH) );
		var str = ret.join('\n');
		
		if( actual === expected ) {
			LOG( 
				(' PASS: '+ desc +' ').pad(40,'=',String.PAD_BOTH) +'\n'+ str, 
				LOG.ACL_PERMUTATION_PASS 
			);
			return true;
		}

		LOG( 
			(' FAILURE: '+ desc +' ').pad(40,'=',String.PAD_BOTH) +'\n'+ str, 
			( actual? LOG.ACL_PERMUTATION_TOO_PERMISSIVE : LOG.ACL_PERMUTATION_NOT_PERMISSIVE_ENOUGH ) 
		);
		return false;
	},
	'doGrant':				function(
								path,
								perm,
								forUser/* = 'Everyone' */,
								recursive/* = false */
							) {
								if( Object.isUndefined( forUser ) ) forUser = 'Everyone';
								if( Object.isUndefined( recursive ) ) recursive = false;
								
								return this._set({
									'on':path,
									'ot':'file',
									'actn':'ace',
									'ace':'n:'+forUser+';m:grant;p:'+perm,
									'rec': ( recursive ? 'cont_obj' : 'no' )
								});
							},
	'doDeny':				function(
								path,
								perm,
								forUser/* = 'Everyone' */,
								recursive/* = false */
							) {
								if( Object.isUndefined( forUser ) ) forUser = 'Everyone';
								if( Object.isUndefined( recursive ) ) recursive = false;
								
								return this._set({
									'on':path,
									'ot':'file',
									'actn':'ace',
									'ace':'n:'+forUser+';m:deny;p:'+perm,
									'rec': ( recursive ? 'cont_obj' : 'no' )
								});
							},
	'doClear':				function(
								path,
								recursive /* = false */
							) {
								if( Object.isUndefined( recursive ) ) recursive = false;
								
								// clear target item (remove the grant full)
								// setacl -on filesdir/parentdir/existing_file -ot file -actn clear -clr "dacl,sacl"
								
								return this._set({
									'on':path,
									'ot':'file',
									'actn':'clear',
									'clr':'dacl,sacl',
									'rec': ( recursive ? 'cont_obj' : 'no' )
								});
							},
	'doBlock':				function(
								path
							) {
								return this._set({
									'on':	path,
									'ot':	'file',
									'actn':	'setprot',
									'op':	'dacl:p_nc;sacl:p_nc',
									'rec':	'cont_obj'
								});
							},
	'_set':					function(
								args
							) {
								args.toString = function(){
									var r = '';
									for( var k in this ){
										r+= ' -' + k + ' "' + this[k] + '"';
									}
									return r;
								}
								//WL( '\t' + 'setacl' + args );
								return $$( 'setacl' + args );
							},
	'toString':	function() {
					var ret = '';
					var all = this.getAll();
					return ret;
				}
}))();

var AccessControlEntry = Class.create({
	'initialize':			function(
								parent
							) {
								this.parent = ( !Object.isUndefined(parent) ? parent : null );
								this.grants = {};
								this.denys = {};
							},
	'grant':				function(
								permission
							) {
								this.grants[permission] = ACL[permission];
								return this;
							},
	'deny':					function(
								permission
							) {
								this.denys[permission] = ACL[permission];
								return this;
							},
	'revokeGrant':			function(
								permission
							) {
								delete this.grants[permission];
								return this;
							},
	'revokeDeny':			function(
								permission
							) {
								delete this.denys[permission];
								return this;
							},
	'getValue':				function(
							) {
								var bits = ( ( this.parent instanceof AccessControlEntry ) ? this.parent.getValue() : ACL.FULL );
								for( var perm in this.grants ) {
									bits = bits | this.grants[perm];
								}
								for( var perm in this.denys ) {
									bits = bits &~ this.denys[perm];
								}
								
								return bits;
							},
	'isGranted':			function(
								testPermission
							) {
								/*var bits = 0;
								for( var g in this.grants) {
									bits = bits | this.grants[g];
								}
								
								return Boolean( ( testPermission & bits ) == testPermission );
								*/
								for( var g in this.grants) {
									if( ( testPermission & this.grants[g] ) == testPermission ) {
									//if( ( this.grants[g] & testPermission ) == this.grants[g] ) {
										return true;
									}
								}
								return false;
							},
	'isDenied':			function(
								testPermission
							) {
								/*
								var bits = 0;
								for( var d in this.denys) {
									bits = bits | this.denys[d];
								}
								
								return Boolean( ( testPermission & bits ) == testPermission );
								*/
								for( var d in this.denys) {
									if( ( testPermission & this.denys[d] ) ) {
									//if( ( this.denys[d] & testPermission ) == this.denys[d] ) {
										return true;
									}
								}
								return false;
							},
	/**
	 * Generate bottom-up, then call this.apply() on the top
	 */
	'generate':				function(
								forUser/* = 'Everyone' */,
								depth/* = 0 */
							) {
								if( Object.isUndefined( depth ) ) depth = 0;
								
								if( this.parent instanceof AccessControlEntry ){
								// If this has a parent ACE, generate the folder for it first
									var parentPath = this.parent.generate( forUser, ( depth + 1 ) );
								} else { 
								// parent is the rootpath. Generate a new folder in the rootPath that blocks.
									var parentPath = $$.fso.BuildPath(
										this.parent,
										$$.fso.GetTempName()
									);
									$$.fso.CreateFolder( parentPath );
									this.block = parentPath;
									ACL.doGrant( parentPath, 'FULL', undefined, true );
									ACL.doBlock( parentPath );
									this.parent = parentPath;
								}
								
								this.path = $$.fso.BuildPath(
										parentPath,
										$$.fso.GetTempName()
									);
								
								// if we're at a depth of zero, target is a file. else, it's a folder,
								if( depth ) {
									$$.fso.CreateFolder( this.path );
								} else {
									var f = $$.fso.CreateTextFile( this.path );
									f.WriteLine( ( new Date() ).getTime() );
									f.Close();
								}
								
								
								if( !depth ) {
									// now let's apply.
									this.apply( forUser );
								}
								return this.path;
							},
	/**
	 * Apply top-down. Strip all, then grant/deny
	 */
	'apply':				function(
								forUser/* = 'Everyone' */
							) {
								ACL.doClear( this.path );
								for( var g in this.grants ){
									ACL.doGrant( this.path, g );
								}
								for( var d in this.denys ){
									ACL.doDeny( this.path, d );
								}
								
								if( this.parent instanceof AccessControlEntry ){
									this.parent.apply();
								} else {
									//ACL.doClear( this.block );
								}
							},
	'destroy':				function(
								depth /* = 0 */
							) {
								if( Object.isUndefined( depth ) ) depth = 0;
								
								ACL.doClear( this.path );
								ACL.doGrant( this.path, 'FULL', undefined, true );
									
								if( this.parent instanceof AccessControlEntry) {
									this.parent.destroy();
								} else if( !Object.isUndefined( this.block ) ) {
									ACL.doClear( this.block, true );
									ACL.doGrant( this.block, 'FULL', undefined, true );
									$$.withRetry( 'rm -rf "{0}"', this.block );
								} else {
									// nothing to see here.
								}
							},
	is_readable:			function(){
								return ACL.test( ACL.READ, this )
							}, 
	is_writable:			function(){
								return ( ACL.test( ACL.WRITE, this ) && 
											( 	ACL.test( ACL.READ, this ) || 
												ACL.test( ACL.READ, this.parent ) )
											)
							}, 
	'toString':			function( not_root /*=false*/ ){
								var ret = [];
								if( !(not_root||false) ) ret.push('APPLIED TO:    '+this.path);
								for( var perm in this.grants )
									ret.push( '  GRANT '+perm );
								for( var perm in this.denys )
									ret.push( '  DENY '+perm );
								if( !Object.keys( this.grants ).length && !Object.keys( this.denys ).length)
									ret.push( '  NONE' );
								if( this.parent instanceof AccessControlEntry ){
									ret.push( 'INHERITS FROM: '+this.parent.path );
									ret.push( this.parent.toString(true) )
								} else if( this.parent ){
									ret.push( 'INHERITS FROM: '+this.parent );
									ret.push( '  BLOCKING GRANT FULL');
								}
								return ret.join('\n');
							} 
});

LOG.registerConstant('ACL_PERMUTATION_SKIP');
LOG.registerConstant('ACL_PERMUTATION_PASS');
LOG.registerConstant('ACL_PERMUTATION_TOO_PERMISSIVE');
LOG.registerConstant('ACL_PERMUTATION_NOT_PERMISSIVE_ENOUGH');
LOG.registerConstant('ACL_PERMUTATION_FAIL',
						  LOG.ACL_PERMUTATION_TOO_PERMISSIVE
						| LOG.ACL_PERMUTATION_NOT_PERMISSIVE_ENOUGH
					);
LOG.registerConstant('ACL_PERMUTATION_RESULT',
						  LOG.ACL_PERMUTATION_PASS
						| LOG.ACL_PERMUTATION_SKIP
						| LOG.ACL_PERMUTATION_FAIL
					);

// Effective permissions - note the '_BIT' suffix
ACL.registerConstant('READ_BIT');
ACL.registerConstant('WRITE_BIT');
ACL.registerConstant('EXECUTE_BIT');
ACL.registerConstant('SYNCHRONIZE_BIT');
ACL.registerConstant('FULL_DENIAL_BIT');

// Setable permissions
ACL.registerConstant(
	'READ',			ACL.READ_BIT
);
ACL.registerConstant(
	'WRITE',		ACL.WRITE_BIT
);
/*
ACL.registerConstant(
	'LIST_FOLDER',	ACL.READ_BIT | 
					ACL.EXECUTE_BIT 
);*/
/*
ACL.registerConstant(
	'READ_EX',		ACL.READ_BIT | 
					ACL.EXECUTE_BIT | 
					ACL.SYNCHRONIZE_BIT
);*/
ACL.registerConstant(
	'FULL',			ACL.READ_BIT | 
					ACL.EXECUTE_BIT | 
					ACL.SYNCHRONIZE_BIT | 
					ACL.WRITE_BIT
);
