WL('=====================================');
var results = ACL.permute(
					'C:\\testdir',
					ACL.examples.is_readable,
					{},
					{reduction:REDUCE.ALL}
				);




WL(''.pad(40,'='));
WL('TEST COUNT:    '+results.length);
WL('TESTS PASSED:  '+Array.countValues( results, true ) );
WL('TESTS SKIPPED: '+Array.countValues( results, null ) );
WL('TESTS FAILED:  '+Array.countValues( results, false ) );
WL(''.pad(40,'='));
WL('Output logs are located at:');
WL('  {config.log_base}'.Format());