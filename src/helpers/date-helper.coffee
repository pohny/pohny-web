define (require) ->
  _ = require 'underscore'

  _split = (date) -> return date.toISOString().split('T')

  class DateHelper

    @DAY_SEC: 60 * 60 * 24
    @WEEK_SEC: DateHelper.DAY_SEC * 7

    @DAY_MSEC: DateHelper.DAY_SEC * 1000
    @WEEK_MSEC: DateHelper.WEEK_SEC * 1000

    @DAYS = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday']
    @MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December']

    @getTimestampInSec: (date) ->
      if date == undefined then date = new Date()
      if _.isDate(date) == false then throw new TypeError("getFormattedDate requires a date object")
      return Math.floor( date.getTime() / 1000)

    @getYYYYMMDD: (date) ->
      if date == undefined then date = new Date()
      if _.isDate(date) == false then throw new TypeError("getYYYYMMDD requires a date object")
      return parseInt(_split(date)[0].replace(/-/g, ''))

    @formatDateTime: (date) ->
      if date == undefined then date = new Date()
      if _.isDate(date) == false then throw new TypeError("getHHmm requires a date object")
      d = _split(date)
      d[0] = if d[0] == _split(new Date())[0] then "Today" else d[0].replace(/-/g, '/')
      return d[0] + ', ' + d[1].split(':').slice(0, 2).join(':')

    @formatTime: (date) ->
      if date == undefined then date = new Date()
      if _.isDate(date) == false then throw new TypeError("formatTime requires a date object")
      return _split(date)[1].split(':').slice(0, 2).join(':')

    @formatDate: (date) ->
      if date == undefined then date = new Date()
      if _.isDate(date) == false then throw new TypeError("getHHmm requires a date object")
      return _split(date)[0].replace(/-/g, '/')

    ###
    @formatDayDate: (date) ->
      if date == undefined then date = new Date()
      if _.isDate(date) == false then throw new TypeError("formatDay requires a date object")
      return DateHelper._getDayName(date) + " " + date.getDate()
    ###

    @formatDayMonthDate: (date) ->
      if date == undefined then date = new Date()
      if _.isDate(date) == false then throw new TypeError("formatDay requires a date object")
      return date.getDate() + " " + DateHelper._getMonthName(date)

    @_getDayName: (date) ->
      return @DAYS[date.getDay()].slice(0, 3)

    @_getMonthName: (date) ->
      return @MONTHS[date.getMonth()].slice(0, 3)


    @_getMinDiff: (d1, d2) ->
      return (d1.getHours() - d2.getHours()) * 60 + d1.getMinutes() - d2.getMinutes()

    @_getSecDiff: (d1, d2) ->
      return Math.floor (d1.getTime() - d2.getTime()) / 1000

    @autoFormatDate: (date) ->
      if date == undefined then date = new Date()
      if _.isDate(date) == false then throw new TypeError("autoFormatDate requires a date object")
      res = null
      now = new Date()
      res = switch
        when date.getYear() < now.getYear() then DateHelper.formatDate(date)
        when date.getMonth() < now.getMonth() then DateHelper.formatDayMonthDate(date)
        when now.getDate() - date.getDate() > 2  then DateHelper.formatDayMonthDate(date)
        when now.getDate() - date.getDate() > 0  then DateHelper._getDayName(date)
        #when now.getHours() - date.getHours() > 0  then "" + now.getHours() - date.getHours() + 'h'
        when  DateHelper._getMinDiff(now, date) > 59  then "Today"
        when  DateHelper._getSecDiff(now, date) > 59  then Math.floor(DateHelper._getSecDiff(now, date) / 60 ) + 'm'
        else 'Now'
      return res

    @autoFormatDateTime: (date) ->
      ret = @autoFormatDate(date)
      now = new Date()
      if DateHelper._getMinDiff(now, date) > 59  then ret += ', ' + DateHelper.formatTime(date)
      return ret
