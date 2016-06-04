require.config({
  baseUrl: 'build'

  paths:
    templates:   '../../assets/js/templates'
    etc:         'etc'
    modules:     'modules'
    helpers:     'helpers'

    underscore:             '../public/underscore-min'
    backbone:               '../public/backbone.min'
    jquery:                 '../public/jquery.min'
    'backbone.marionette':  '../public/backbone.marionette.min'
    twilio:                 '//static.twilio.com/libs/twiliojs/1.2/twilio.min'

    TweenMax:       "../public/greensock/TweenMax",
    TweenLite:      "../public/greensock/TweenLite",
    CSSPlugin:      "../public/greensock/plugins/CSSPlugin",
    TimelineLite:   "../public/greensock/TimelineLite",
    TimelineMax:    "../public/greensock/TimelineMax",
    EasePack:       "../public/greensock/easing/EasePack"

    shim:
      underscore: {exports : '_'}
      'backbone.marionette': {deps:['backbone']}

})

require ['app']
