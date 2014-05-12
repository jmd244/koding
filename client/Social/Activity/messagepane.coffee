class MessagePane extends KDTabPaneView

  constructor: (options = {}, data) ->

    options.type    or= ''
    options.cssClass  = "message-pane #{options.type}"

    super options, data

    channel           = @getData()
    {itemClass, type} = @getOptions()

    @listController = new ActivityListController
      itemClass     : itemClass
      lastToFirst   : yes  if type is 'message'

    @listView = @listController.getView()

    unless type in ['post', 'message']
      @input = new ActivityInputWidget {channel}
      @input.on 'Submit', @listController.bound 'addItem'


  viewAppended: ->

    @addSubView @input  if @input
    @addSubView @listView
    @populate()


  populate: ->

    @fetch (err, items) =>

      return KD.showError err  if err

      console.time('populate')
      @listController.hideLazyLoader()
      @listController.listActivities items
      console.timeEnd('populate')


  fetch: (callback)->

    {appManager}            = KD.singletons
    {name, type, channelId} = @getOptions()
    data                    = @getData()
    options                 = {name, type, channelId}

    # if it is a post it means we already have the data
    if type is 'post'
    then KD.utils.defer -> callback null, [data]
    else appManager.tell 'Activity', 'fetch', options, callback


  refresh: ->

    document.body.scrollTop            = 0
    document.documentElement.scrollTop = 0

    @listController.removeAllItems()
    @listController.showLazyLoader()
    @populate()
