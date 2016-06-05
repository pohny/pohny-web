root = '../js/'
require.config({
  baseUrl: 'build'

  paths:
    modules:     'modules'
    helpers:     'helpers'

    underscore:             root + 'underscore-min'
    backbone:               root + 'backbone.min'
    jquery:                 root + 'jquery.min'
    'backbone.marionette':  root + 'backbone.marionette.min'
    twilio:                 root + 'twilio.min'

    shim:
      underscore: {exports : '_'}
      'backbone.marionette': {deps:['backbone']}
      twilio: { exports: 'twilio', deps: ['jquery'] }

})
