define (require) ->

  isObject = (value) -> return ['function', 'object'].indexOf(typeof value) > -1 || !!value
  _throw = (value, error) ->
    #console.log 'Value ' + JSON.stringify(value) + ' is ' + error
    throw error

  class Validator
  class StringValidator extends Validator

    constructor: () ->
      @tests = [['string']]

    required: () -> @tests.push(['required']); @
    min: (min) -> @tests.push(['min', min]); @
    max: (max) -> @tests.push(['max', max]); @
    regex: (regex) -> @tests.push(['regex', regex]); @

    #TODO: move error message as constants ?
    @string:   (value) -> if value != undefined && typeof value != 'string' then _throw(value, 'INVALID_TYPE')
    @required: (value) -> if value == null || value == undefined || value.length < 1 then _throw(value, 'REQUIRED')
    @min:      (value, min) -> if value.length < min                        then _throw(value, 'TOO_SHORT')
    @max:      (value, max) -> if value.length > max                        then _throw(value, 'TOO_LONG')
    @regex:    (value, regex) -> if value.match(regex) == null              then _throw(value, "INVALID_FORMAT")

  class Val
    @String: () -> return new StringValidator()

    ###
    # @param value mixed
    # @param schema Validator
    # @return Boolean (if no exception is thrown before)
    ###
    @one: (value, validator) ->
      if validator == undefined then return
      if validator instanceof Validator == false then throw new TypeError('validator should be Validator instance')
      for test in validator.tests
        test2 = test.concat()
        method = test2.shift()
        test2.unshift(value)
        validator.constructor[method].apply(this, test2)
      return true

    ###
    # @param items Object   | hashmap of values
    # @param shemas Object  | hashmap of validator
    # @return Array         | list of error
    # ex: Val.validates({ foo: 1}, {foo: Val.String() })
    ###
    @many: (items, schema) ->
      if isObject(items) == false  then throw new TypeError('items should be a hashmap')
      if isObject(schema) == false then throw new TypeError('schema should be a hashmap')

      errors = []
      validator = null

      for key, value of items
        validator = schema[key]
        try Val.one(value, validator)
        catch e then errors.push [key, e]

      return if errors.length > 0 then errors else null
