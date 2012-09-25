chai = require 'chai'
chai.should()
PantaRhei = require '../src/PantaRhei'

describe 'Flow', ->  
	describe 'run', ->
		Flow = PantaRhei.Flow
		test1 = test2 = {
			run: (shared, next) ->
				next()
		}
		errorTest = {
			run: (shared, next) ->
				err = new Error('something went wrong')
				next(err)
		}

		it 'accept a new worker with .use method', ->
			flow = new Flow 'test', null
			flow
				.use({id: 'test3', run: (shared, next) -> next()})
				.queue.length.should.be = 1

		it 'dispatch a run and complete event passing the shared obj', ->  
			flow = new Flow 'test', [test1, test2], {test: 'test'}
			onComplete = onRun = (shared) ->
				shared.should.include.keys 'test'
				flow.off()
			flow
				.on('complete', onComplete)
				.on('run', onRun)
				.run({test: 'test'})

		it 'dispatch an error event passing the Error as an argument and pause', ->
			flow = {} = new Flow 'test', [errorTest, test1]
			onError = (err) ->
				error.should.be.a 'error'
				flow._pause.should.be true
				flow.off()

			flow
				.on('error', (error) ->)
				.run({test: 'test'})

		it 'should be possible to resume a flow', (done)->
			flow = {} = new Flow 'test', [errorTest, test1]
			
			onComplete = (shared) ->
				done()
				flow.off()

			onPause = (err) ->
				resume = ->
					flow.resume()
				setTimeout resume, 50

			flow
				.on('complete', onComplete)
				.on('pause', onPause)
				.run()

		it 'should be possible to run the flow twice', (done) ->
			flow = {} = new Flow 'test', [test1, test2]
			onComplete = (shared) ->
				if (shared.runnTime is 2)
					done()
					flow.off()
				else
					flow.run({"runnTime": 2})

			flow
				.on('complete', onComplete)
				.run({"runnTime": 1})

	describe 'pause', ->
	describe 'stop', ->
	describe 'reset', ->