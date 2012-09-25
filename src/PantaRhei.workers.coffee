# ## Workers
#
# this is a collection of usefull workers

# define the workers namespace
workers = PantaRhei.workers = {}

# ### iddle 
# this can be used to pause the flow for the given time in milliseconds
Iddle = class workers.Iddle extends Worker
	constructor: (@duration, @id = _.uniqueId('iddle_')) ->
	run: (@shared, @next) ->
		onTimeout = ->
			@next()
		setTimeout onTimeout, @duration

		return this
	kill: ->
		return null


# ### JSON Loader 
# Load a JSON or JSONP from a given url
# The target url must be provided passing a **jsonUrl** to the constructor
# the result is passed in the options with the **jsonData** Array
# and can be retrived passing the loader id as an array key es. jsonData['loader_01']
#
# if ajax is unable to load the json it will pass the error with **textStatus** to the callback stack
# and **errorThrown** and **XMLHttpRequest** in the options
JsonLoader = class workers.JsonLoader extends Worker
	constructor: (@jsonUrl, @id = _.uniqueId('jsonLoader_')) ->
	run: (@shared, @next) ->
		that = this
		# load the json
		if @jsonUrl?
			$.getJSON(
				@jsonUrl, ->
			)
			.success	(data, textStatus, jqXHR) ->
					# create the array to hold the loaded data
					if !that.shared.jsonData
						that.shared.jsonData = new Array()
					# assign the data to the array using the id as a key
					that.shared.jsonData[that.id] = data
					that.next()

			.error (XMLHttpRequest, textStatus, errorThrown) ->
					that.shared.loadedData = null
					that.shared.errorThrown = errorThrown
					that.shared.XMLHttpRequest = XMLHttpRequest
					that.next new Error textStatus

		# pass an error if the jsonUrl is missing
		else 
			next new Error('Please provide an url')
	kill: ->

# #### Load assets
# This method is provided to cache a series of images before showing the page
# to provide the images to load pass an array of string in **options.assets**
LoadAssets = class workers.LoadAssets extends Worker
	constructor: (@assets, @id = _.uniqueId('assetsLoader_')) ->
	run: (@shared, @next) ->
		that = this
		# Check for the assets array
		if _.isArray @assets
			totalNum = @assets.length
			numLoaded = 0
			onError = ->
				that.next new Error "Error loading the asset"
			onLoad = ->
				numLoaded +=1 ;
				if numLoaded is totalNum 
					that.shared.assetsPreloaded = true
					that.next()

			_.each @assets, (url) ->
				img = new Image()
				img.onload = onLoad
				img.onerror = onError
				img.src = url

		# pass an error if the assets are missing
		else
			next new Error 'Please provide some assets'
	kill: ->