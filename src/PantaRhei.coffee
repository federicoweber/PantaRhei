### 
	PantaRhei.js v 0.2.0
	
	(c) 2012 Federico Weber
	distributed under the MIT license.
	federicoweber](http://federicoweber.com)
###

# save a reference to the global object
root = this

# Define the top-level namespace
PantaRhei = {}

# require underscore and backbone for testing
if (exports?)
	PantaRhei = exports;
	_ = require 'underscore'
	Backbone = require 'backbone'

# check for backbone existence in the browser
if root.Backbone?
	Backbone = root.Backbone
	_ = root._

# if backbone is missing throw an error
if Backbone is undefined
	throw "Please import Backbone to use this library"

# Nest top-level namespace into Backbone
root.PantaRhei = PantaRhei
VERSION = PantaRhei.VERSION = "0.2.0"

# ## Flow
#
# The purpose of a **Flow** is to ease the declaration and execution 
# of a chain of consecutive tasks. Like preparing the data for a new page.
#
# The Flow will take care of extecuting the various
# workers in the given order.
#
# It is possible to directly pass to the constructor the queue
# If the id is not provided it will generate an uniq one
Flow = class PantaRhei.Flow
	constructor: (@id = _.uniqueId('flow_'), @queue = new Array()) ->
		@_currentWorker = {}

		# assign an uniq name ad id to the workers
		@_naming worker for worker in @queue

		# return the Flow to enable cascade coding
		return this
#	### Methods
	#	#### use
	# This method is used to append a new worker in the queue 
	# it will throw an error if the worker is noth properly structured
	use: (worker) ->
		if _.isFunction(worker.run) or _.isFunction(worker)
			@_cacheFlow worker
			@_naming worker
			@queue.push worker
		else
			throw new Error "Provide a proper worker"

		# return the Flow to enable cascade coding
		return this
	# ### check
	# This is used to add a test worker on the queue.
	# It will test the provides key and value pairs against the shared object.
	# If the test do faile the flow will be interrupted.
	# As sole parameter it accept an object.
	check: (valuesToTest)->
		worker = new ValueChecker(valuesToTest)
		@_cacheFlow worker
		@_naming worker
		@queue.push worker
		return this

	# ### run
	# This is the method used to actually run the flow
	# if the @shared object is not provided it create an empty one
	run: (@shared = {}) ->
		if @queue.length is 0
			throw new Error "The workers queue is empty"
		else
			@_paused = false
			# create a running copy of the queue. This is usefull to allow multiple consecutive run.
			@_runningQueue = _.clone @queue
			# reverse the queueu to run everthing int the proper order
			@_runningQueue.reverse()
			# fire the run event
			@trigger('run', @shared)
			# run the first worker
			@_next()

		# return the Flow to enable cascade coding
		return this

	# #### Pause
	# Simply pause the flow
	pause: ->
		@_paused = true
		@trigger('pause', @shared)

		# return the Flow to enable cascade coding
		return this
	
	# #### Resume
	# Resume a paused Flow
	resume: ->
		@_paused = false
		@trigger('resume', @shared)
		@_next()

		# return the Flow to enable cascade coding
		return this

	# #### Terminate
	# This is used to interrupt the flow at will; it will empty the running queue and throw a **terminate** and a **done** event.
	terminate: ->
		@_runningQueue = []
		@trigger('terminate', @shared)
		@_next()
		
		# return the Flow to enable cascade coding
		return this
	
	# kill: ->
	# 	# return the Flow to enable cascade coding
	# 	return this

	# #### _cacheFlow
	# this is an internal function to store a reference to the flow into the worker
	_cacheFlow: (worker) ->
		worker._flow = this

	# #### _naming
	# this is an internal function to an name and an id to the worker to ease debugging
	# the given name is equal to the worker id
	_naming: (worker) ->
		
		# add the id if it's not provided
		unless worker.id?
			if !uniqId?
				uniqId = _.uniqueId('worker_')
			worker.id = uniqId

	# #### _next
	# this private method is used to actually run the worker 
	# it's also passed as the **next** callback to each worker
	_next: (error) ->

		# if an error is passed in fire the error event and pause the flow
		if error
			@pause()
			@trigger('error', error, @_currentWorker.id)
		else
			# kill the previous worker
			if @_currentWorker and _.isFunction @_currentWorker.kill
				@_currentWorker.kill()

			# run the worker queue
			if @_runningQueue.length > 0
				@_currentWorker = @_runningQueue.pop()

				# run the worker if it provide the run method
				if @_currentWorker and _.isFunction @_currentWorker.run
					cNext = _.bind(@_next, this)
					@trigger('step', @shared, @_currentWorker)
					@_currentWorker.run(@shared, cNext)

				# run the worker if it's a function
				else if @_currentWorker and _.isFunction @_currentWorker
					@trigger('step', @shared, @_currentWorker)
					cNext = _.bind(@_next, this)
					@_currentWorker(@shared, cNext)

				else
					throw new Error "The #{@_currentWorker.id} cannot be executed"
			
			# fire the **complete** event if the queue have been succesfully runned
			else
				# TODO: set the app as notBusy
				@trigger('complete', @shared)

# enable events for the Flow
_.extend(Flow.prototype, Backbone.Events)

# ## Worker
#
# define the Worker 

Worker = class PantaRhei.Worker

	constructor: (@id = _.uniqueId('worker_')) ->
	# ### Attributes
	# #### _flow
	# This is a cached reference to the flow to which the worker belong and it's setted by the Flow
	_flow: undefined
	# ### Methods

	# #### run
	# Used by the flow to execute the worker.
	# It's meant to be overridden, if not it will pass an error to the flow
	# It accept the following mandatory arguments:
	#
	# - **shared** object, which purpose is to act as a vehicle of data among the various worker;
	# - **next** to call next step of the flow
	run: (@shared, @next) ->
		# run the next worker
		@next(new Error('run must be overridden'))

	# #### kill
	# This is runned by the Flow before running the next worker
	# It's meant to be overridden, if not it will throw an error
	kill: ->
		throw new ReferenceError "kill must be overridden "

_.extend(Worker.prototype, Backbone.Events)
# ### Value Checker
# This is a special worker that is automatically created by the Flow.check method.
# The only required attribute is @valuesToTest object that contains all the key value pairs to test.
# If any of the test fail the worker will interrupt the flow
class ValueChecker extends Worker
	constructor: (@valuesToTest, @id = _.uniqueId('valueChecker_')) ->
	run: (shared, next) ->
		checkValues = _.chain(@valuesToTest)
			.pairs()
			.map(
				(el)->
					if shared[el[0]] is el[1] then true else false
			)
			.value()

		if _.indexOf(checkValues, false) > -1
			@_flow.terminate()
		else
			next()

	kill: ->

# ---
# Borrowed the Backbone style extend
Flow.extend = Worker.extend = Backbone.View.extend
