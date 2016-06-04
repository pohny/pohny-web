define (require) ->
  m = {}
  # Debug data
  m.getDebugContacts = () ->
    return [
      {
        phone: "+11111111111",
        name: "kim Jong",
        last_msg: "You: suck balls"
      }, {
        phone: "+11111111112"
        name: "Vladimir Putine",
        last_msg: "wang copter"
      }, {
        phone: "+11111111113"
        name: "Barak"
      }
    ]


  # Debug data
  m.getDebugMessages = () ->
    messages = []
    for i in [0..10]
      messages.push {
        at: Date.now() - Math.pow(2, i) * 100000
        body: "Hello ! " + (Math.pow(12, i))  + " cats in the counter."
        me: i % 2 == 0
      }
    return messages

  return m
