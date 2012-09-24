chai = require 'chai'
chai.should()
PantaRhei = require '../src/PantaRhei'

describe 'Flow', ->  
	describe 'run', ->
		Flow = PantaRhei.Flow
		test1 = test2 = {
			run: (err, options, next) ->
				next()
		}
		errorTest = {
			run: (err, options, next) ->
				err = new Error('something went wrong')
				next(err)
		}

		it 'accept a new worker with .use method', ->
			flow = new Flow 'test', null
			flow
				.use({id: 'test3', run: (err, options, next) -> next()})
				._queue.length.should.be = 1

		it 'dispatch a run and complete event passing the options obj', ->  
			flow = new Flow 'test', [test1, test2], {test: 'test'}
			onComplete = onRun = (options) ->
				options.should.include.keys 'test'
				flow.off()
			flow
				.on('complete', onComplete)
				.on('run', onComplete)
				.run({test: 'test'})

		it 'dispatch an error event passing the Error as an argument and pause', ->
			flow2 = new Flow 'test', [errorTest, test1]
			onError = (err) ->
				error.should.be.a 'error'
				flow._pause.should.be true
				flow2.off()

			flow2
				.on('error', (error) ->)
				.run({test: 'test'})

		it 'should be possible to resume a flow', (done)->
			flow3 = new Flow 'test', [errorTest, test1]
			
			onComplete = (options) ->
				done()
				flow3.off()

			onPause = (err) ->
				resume = ->
					flow3.resume()
				setTimeout resume, 50

			flow3
				.on('complete', onComplete)
				.on('pause', onPause)
				.run()

	describe 'pause', ->
	describe 'stop', ->
	describe 'reset', ->