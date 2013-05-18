chai = require 'chai'
chai.should()
PantaRhei = require '../src/PantaRhei'

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

describe 'Flow', ->  
	
	describe 'create the flow', ->
		it 'accept a new worker with .use method', (done)->
			flow = new Flow 'test', null
			flow
				.use({id: 'test3', run: (shared, next) -> next()})
				.queue.length.should.be.eql 1
				done()

		it 'cache a reference to the flow in the worker _flow attribute', (done)->
			flow = new Flow 'test', null
			dummyWorker = (shared, next)->
				next()
			flow
				.use(dummyWorker)
				.queue.length.should.be.eql 1
			dummyWorker._flow.should.be.eql flow
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

		it 'accept a data check statement and add it in the worker queue', (done)->
			flow = new Flow 'test', []
			onComplete = (shared) ->
				flow.queue.length.should.be.equal 3
				flow.off()
				done()

			flow
				.use(test1)
				.check({'test': true})
				.use(test2)
				.on('complete', onComplete)
				.run({test: true})
	
	describe 'flow events', ->
		it 'dispatch a complete event passing the shared obj', (done)->  
			flow = new Flow 'test', [test1, test2]
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
				typeof error.should.be.a 'error'
				flow._paused.should.be.true
				done()
				flow.off()

			flow
				.on('error', onError)
				.run({test: 'test'})

		it 'Should not fire the complete event if an error is throw form a worker', (done)->
			flow = {} = new Flow 'test', [errorTest, test1]
			completed = false
			onError = (error) ->
				typeof error.should.be.a 'error'
				flow._paused.should.be.true

				# fire the check sattus after a timeout to make sure the flow havent been completed
				setTimeout checkStatus, 50
				
			onComplete = ->
				completed = true

			checkStatus = ->
				completed.should.be.false
				flow.off()
				done()

			flow
				.on('error', onError)
				.on('complete', onComplete)
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

	describe 'controlling the flow', ->
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

		it 'should be possible to terminate a flow on a chosed step', (done)->
			flow = {} = new Flow 'test', []
			terminated = false
			allRunned = false

			onComplete = (shared) ->
				terminated.should.be.true
				allRunned.should.be.false
				done()
				flow.off()

			onTerminate = () ->
				terminated = true

			flow
				.on('terminate', onTerminate)
				.on('complete', onComplete)
				.use(
					(shared, next)->
						@terminate()
				)
				.use(
					(shared, next)->
						allRunned = true
						next()
				)
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

		it 'if all the tests are successful it should complete', (done)->
			terminated = false
			allRunned = false
			flow = new Flow 'test', []
			
			onComplete = (shared) ->
				terminated.should.be.false
				allRunned.should.be.true
				done()
				flow.off()

			onTerminate = () ->
				terminated = true

			flow
				.use(test1)
				.check({'test': true, 'num': 1})
				.use(
					(shared, next)->
						allRunned = true
						next()
				)
				.on('terminate', onTerminate)
				.on('complete', onComplete)
				.run({'test': true, 'num': 1})

		it 'if a test fail it should interrupt the flow', (done)->
			terminated = false
			allRunned = false
			flow = new Flow 'test', []
			
			onComplete = (shared) ->
				terminated.should.be.true
				allRunned.should.be.false
				done()
				flow.off()

			onTerminate = () ->
				terminated = true

			flow
				.use(test1)
				.check({'test': false})
				.use(
					(shared, next)->
						allRunned = true
						next()
				)
				.on('terminate', onTerminate)
				.on('complete', onComplete)
				.run({'test': true, 'num': 1})