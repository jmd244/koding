kd             = require 'kd'
whoami         = require 'app/util/whoami'
showError      = require 'app/util/showError'
CustomLinkView = require 'app/customlinkview'
KodingSwitch   = require 'app/commonviews/kodingswitch'
hasIntegration = require 'app/util/hasIntegration'

module.exports = class HomeAccountIntegrationsView extends kd.CustomHTMLView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry \
      'AppModal--account integrations', options.cssClass

    super options, data

    @supportedProviders = Object.keys @providers =
      github: 'GitHub'
      gitlab: 'GitLab'

    @linked     = {}
    @switches   = {}
    @containers = {}

    mainController = kd.getSingleton 'mainController'
    @supportedProviders.forEach (provider) =>

      @linked[provider] = no
      foreignEvent = "ForeignAuthSuccess.#{provider}"
      mainController.on foreignEvent, @lazyBound 'handleForeignAuth', provider

      @switches[provider] = new KodingSwitch
        cssClass: 'integration-switch'
        callback: (state) =>
          if state
            @link provider
            @switches[provider].setOn no
          else
            @unlink provider
            @switches[provider].setOff no

      @switches[provider].makeDisabled()

      @addSubView @containers[provider] = new kd.CustomHTMLView
        cssClass: 'container hidden'

      @containers[provider].addSubView new kd.CustomHTMLView
        partial: "#{@providers[provider]} Integration"

      @containers[provider].addSubView @switches[provider]


  handleForeignAuth: (provider) ->

    @fetchOAuthInfo =>
      if @linked[provider]
        kd.utils.defer => new kd.NotificationView
          title: "Your #{@providers[provider]} integration is now enabled."


  viewAppended: ->

    @fetchOAuthInfo()


  fetchOAuthInfo: (callback = kd.noop) ->

    me = whoami()
    me.fetchOAuthInfo (err, foreignAuth) =>
      return showError err  if err

      @supportedProviders.forEach (provider) =>

        @linked[provider] = foreignAuth?[provider]?
        @switches[provider].setDefaultValue @linked[provider]
        @switches[provider].makeEnabled()


      do callback


  show: ->

    super

    for provider in @supportedProviders
      if hasIntegration provider
      then @containers[provider].show()
      else @containers[provider].hide()


  link: (provider) ->

    kd.singletons.oauthController.redirectToOauthUrl { provider }
    new kd.NotificationView
      title: "Redirecting to #{@providers[provider]}..."


  unlink: (provider) ->

    me = whoami()
    me.unlinkOauth provider, (err) =>
      return showError err  if err

      new kd.NotificationView
        title: "Your #{@providers[provider]} integration is now disabled."

      @linked[provider] = no


  getLoaderView: ->

    new kd.LoaderView
      cssClass   : 'main-loader'
      showLoader : yes
      size       :
        width    : 25
        height   : 25

