

window.HTTP =
	base: ''
	status: {}

	showLoading: ->
		# $('#ajax-loading').stop().fadeIn()

	hideLoading: ->
		# $('#ajax-loading').stop().fadeOut()

	setup: ->
		$.ajaxSetup
			dataType: 'json'
			cache: true
			beforeSend: (xhr, settings) ->
				xhr.setRequestHeader("Cache-Control", "max-age=3600")
			

	call: (type, uri, data) ->
		console.debug('making API call: ' + @base + uri);
		@status[uri] = 'waiting'
		ret = $.ajax (@base + uri),
			data: data
			type: type
			success: (d)=>
				console.debug('SUCCESS: ' + @base + uri)
				@status[uri] = 'success'
				allOK = true
				for uri, state of @status
					if state != 'success'
						allOK = false
				if allOK
					@hideLoading()
			error: =>
				console.error "HTTP error"
				@status[uri] = 'error'
			
		@showLoading()
		return ret

	blocking: (type, uri, data) ->
		console.debug('making API call: ' + @base + uri);
		@status[uri] = 'waiting'
		ret = $.ajax (@base + uri),
			data: data
			type: type
			async: false

		@showLoading()
		return ret

	get: (uri, data) ->
		@call('get', uri, data)

	post: (uri, data) ->
		@call('post', uri, data)