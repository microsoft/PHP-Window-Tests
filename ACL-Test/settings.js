config.set({
	'log_base': '{$ScriptPath}logs\\'.Format() + ( new Date ).iso8601( )
,	'logs': [
			new LogHelper.Console( LOG.VERBOSE
			),
			new LogHelper.File(   LOG.ACL_PERMUTATION_RESULT
								, '{config.log_base}\\results.log'
			),
			new LogHelper.File(   LOG.ACL_PERMUTATION_PASS
								, '{config.log_base}\\results.pass.log'
			),
			new LogHelper.File(   LOG.ACL_PERMUTATION_FAIL
								, '{config.log_base}\\results.fail.log'
			),
			new LogHelper.File(   LOG.ACL_PERMUTATION_SKIP
								, '{config.log_base}\\results.skip.log'
			)
		]
});

