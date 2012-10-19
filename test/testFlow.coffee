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
			id: 'errorWorker'
			run: (shared, next) ->
				err = new Error('something went wrong')
				next(err)
		}

		it 'accept a new worker with .use method', (done)->
			flow = new Flow 'test', null
			flow
				.use({id: 'test3', run: (shared, next) -> next()})
				.queue.length.should.be.eql 1
				done()

		it "add an uniq id for the worker if it's not provided by the constructor", (done)->
			anWk = (shared,next) ->
				next()

			flow = new Flow 'test', [anWk]
			onStep = (shared, worker) ->
				worker.id.should.not.be.empty
				flow.off()
				done()

			flow
				.on('step', onStep)
				.run()

		it "add an uniq id for the worker if it's not provided with the use method", (done)->
			anWk = (shared,next) ->
				next()

			flow = new Flow 'test'
			onStep = (shared, worker) ->
				worker.id.should.not.be.empty
				flow.off()
				done()

			flow
				.use(anWk)
				.on('step', onStep)
				.run()

		it 'dispatch a complete event passing the shared obj', (done)->  
			flow = new Flow 'test', [test1, test2], {test: 'test'}
			onComplete = (shared) ->
				shared.should.include.keys 'test'
				flow.off()
				done()

			flow
				.on('complete', onComplete)
				.run({test: 'test'})

		it 'dispatch an error event passing the Error as an argument and pause', (done)->
			flow = {} = new Flow 'test', [errorTest, test1]
			onError = (error) ->
				error.should.be.a 'error'
				flow._paused.should.be.true
				done()
				flow.off()

			flow
				.on('error', onError)
				.run({test: 'test'})

		it 'If an error is trown the event will return, as the second argument, the worker id', (done)->
			flow = {} = new Flow 'test', [errorTest, test1]
			onError = (error, wkId) ->
				wkId.should.be.equal 'errorWorker'
				done()
				flow.off()

			flow
				.on('error', onError)
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

		it 'should dispatch a step event passing the shared object and the worker', (done) ->
			test1.id = 'test1'
			flow = {} = new Flow 'test', [test1]
			onStep = (shared, worker) ->
				shared.should.include.keys 'test'
				worker.id.should.be.equal 'test1'
				done()
				flow.off()
			flow
				.on('step', onStep)
				.run({"test": "test"})

	describe 'pause', ->
	describe 'stop', ->
	describe 'reset', ->