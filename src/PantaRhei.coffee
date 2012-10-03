### 
	PantaRhei.js v 0.0.1
	
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
VERSION = PantaRhei.VERSION = "0.0.1"

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
		# return the Flow to enable cascade coding
		return this
#	### Methods
#	#### use
# This method is used to append a new worker in the queue 
# it will throw an error if the worker is noth properly structured
	use: (worker) ->
		if _.isFunction(worker.run) or _.isFunction(worker)
			@queue.push worker
		else
			throw new Error "Provide a proper worker"

		# return the Flow to enable cascade coding
		return this

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

	pause: ->
		@_paused = true
		@trigger('pause', @shared)

		# return the Flow to enable cascade coding
		return this

	resume: ->
		@_paused = false
		@trigger('resume', @shared)
		@_next()

		# return the Flow to enable cascade coding
		return this

	kill: ->

			# return the Flow to enable cascade coding
			return this

# this private method is used to actually run the worker 
# it's also passed as the **next** callback to each worker
	_next: (error)->
		# kill the previous worker
		if @_currentWorker and _.isFunction @_currentWorker.kill
			@_currentWorker.kill()

		# if an error is passed in fire the error event and pause the flow
		if error
			@pause()
			@trigger('error', error)

		# run the worker queue
		else if @_runningQueue.length > 0
			@_currentWorker = @_runningQueue.pop()

			# run the worker if it provide the run method
			if @_currentWorker and _.isFunction @_currentWorker.run
				cNext = _.bind(@_next, this)
				@trigger('step', @shared, @_currentWorker)
				@_currentWorker.run(@shared, cNext)

			# run the worker if it's a function
			else if @_currentWorker and _.isFunction @_currentWorker
				cNext = _.bind(@_next, this)
				@_currentWorker(@shared, cNext)

			else
				throw new Error "The #{@_currentWorker.id} worker does not provide a run method"
		
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

# ---
# Borrowed the Backbone style extend
Flow.extend = Worker.extend = Backbone.View.extend