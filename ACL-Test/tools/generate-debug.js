/* Bootstrap scripting library js.js */ 
with(new ActiveXObject("Scripting.FileSystemObject")){for(var each in paths=(".;"+WScript.ScriptFullName.replace(/(.*\\)(.*)/g,"$1")+"..\\lib\\ext;"+(new ActiveXObject("WScript.Shell").Environment("PROCESS")("PATH"))).split(";")){if(FileExists(js=BuildPath(paths[each],"js.js"))){eval(OpenTextFile(js,1,false).ReadAll());break}}};
/* Include prototype.js */ 
eval(include("{$ScriptPath}..\\lib\\ext\\prototype.js"));

/***********************************************************************\
| README:                                                               |
|                                                                       |
| This script takes any script that uses eval(include(...)) to source   |
| external scripts and generates a new script that includes the         |
| contents of such files at the point they would have been included.    |
|                                                                       |
| This allows the interpreter to be aware of the source and report      |
| line numbers of issues, which can then be looked up in the READ_ONLY  |
| generated script.                                                     |
|                                                                       |
\***********************************************************************/
var USAGE = 
	'USAGE: {0} [script [debugScriptName]]'.Format( WScript.ScriptName )
;

	
	
	
	
	
	
	
// Set up some useful constants
var FOR_READING = 1
,	FOR_WRITING = 2
,	FOR_APPENDING = 8
;	

function WL(line) {
	WScript.Stdout.WriteLine(line);
	return line;
}
WL( $$.WSHShell.CurrentDirectory );
function IncludeFile( path ) {
	WL('importing '+path)
	path = path.Format();
	var pathNice = getRelativePath( '{$ScriptPath}'.Format(), path )
	,	ret = []
	,	lineNumber = 0
	;
	ret.push('//#  INCLUDE: {0}'.Format( pathNice ) );
	try {
		var fileStream = $$.fso.openTextFile( path.Format(), FOR_READING )
	} catch ( e ) { Assert.Fail('Could\'nt load file: [{0}]', path.Format() ); }
	while( !fileStream.AtEndOfStream ) {
		lineNumber++;
		var line = fileStream.ReadLine();
		matches = line.match( /eval\(\s*include\(\s*(['"])(.*)\1\s*\)\s*\)\s*;?/ );
		if( matches ) {
			ret.push( IncludeFile( matches[2] ) );
			ret.push('//# CONTINUE: {0}@{1}'.Format( pathNice, ( lineNumber + 1 ) ) );
		} else {
			line = line.replace(/\t/g,'    ');
			ret.push( 
				line + 
				('// '+(''+lineNumber).pad(4)).pad(120-line.length) +
				' '+pathNice
			);
		}
	}
	
	return ret.join('\n');
}

function generateDebugOf( script, debugScript ) {
	var header = '/'+'**#!'+['',
		'Generated {0}'.Format( (new Date()).getTime() )
	,	'This is a READ-ONLY file to help debug output in JScript implementation.'
	,	''
	,	'Because JScript does not support #include and it is impossible to include'
	,	'scripts into the current scope, workarounds depend on eval() but that '
	,	'breaks error reporting, since the interpreter isn\'t aware of the line '
	,	'numbers of code that is eval()\'d. The included pftt-debug.bat script '
	,	'pre-compiles everything into a single file (this file), which can be used'
	,	'to look up the line number and filename of the offending code.'
	,	''
	,	'USAGE: '
	,	'  >pftt-debug runTestsFromConfig();'
	,	''
	].join('\r\n * ') + '\r\n *'+'/';
	
	script = script.Format();
	(dbg=script.split('.')).splice(-1,0,'debug')
	var debugScript = debugScript || dbg.join('.')
	
	$Globals.$ScriptPath = $$.fso.GetParentFolderName( script ) + '\\';
	
	// if debugScript already exists, remove the READ-ONLY attribute and delete it
	// but ONLY if it starts with the first 12 characters of {header}
	if( $$.fso.FileExists( debugScript ) ) {
		if( 
			$$.fso.GetFile( debugScript ).Size > 20
			&& ($$.fso.OpenTextFile( debugScript, FOR_READING )).Read(20) != header.substring(0,20) 
		){
			Assert.Fail('\ndebug script [{0}] exists and appears to not be generated. \n{1}'.Format( debugScript, USAGE ) );
		}
		$$( 'attrib {0} -R', debugScript );
		$$.fso.DeleteFile( debugScript );
	}
	
	var debugScriptStream = $$.fso.createTextFile( debugScript, true, false ) 
	;
	
	debugScriptStream.Write( 
		header + '\r\n' + 
		IncludeFile( script )
	);
		
	debugScriptStream.Close();

	// Make it read-only
	$$( 'attrib {0} +R', debugScript );

	return debugScript;
}

var objArgs = WScript.Arguments
;
switch( objArgs.length ){
	case 1:
		generateDebugOf( objArgs(0) );
		break;
	case 2:
		generateDebugOf( objArgs(0), objArgs(1) );
		break;
	default:
		WL( USAGE );
}