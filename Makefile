test: test-unit

test-unit:
	mocha -r coffee-script -r should -R spec test/*.coffee
