define (require) ->

  return (stream = null) ->
    navigator.getUserMedia = (navigator.getUserMedia ||
      navigator.webkitGetUserMedia ||
      navigator.mozGetUserMedia ||
      navigator.msGetUserMedia)

    audioCtx = new (window.AudioContext || window.webkitAudioContext)()
    source = null
    drawVisual = null

    analyser = audioCtx.createAnalyser()
    analyser.minDecibels = -90
    analyser.maxDecibels = -10
    analyser.smoothingTimeConstant = 0.85

    canvas = document.getElementById('visualizer')
    canvasCtx = canvas.getContext("2d")


    visualize = (stream) ->
      source = audioCtx.createMediaStreamSource(stream)
      source.connect(analyser)
      WIDTH = canvas.width
      HEIGHT = canvas.height

      analyser.fftSize = 256
      bufferLength = analyser.frequencyBinCount
      #console.log(bufferLength)
      dataArray = new Uint8Array(bufferLength)

      canvasCtx.clearRect(0, 0, WIDTH, HEIGHT)


      draw = () ->
        drawVisual = requestAnimationFrame(draw)
        analyser.getByteFrequencyData(dataArray)

        canvasCtx.fillStyle = 'white'
        canvasCtx.fillRect(0, 0, WIDTH, HEIGHT)

        #canvasCtx.font = "20px Lucida Console"
        #canvasCtx.fillStyle = 'red'
        #canvasCtx.textAlign = "center"
        #canvasCtx.fillText("Microphone:", WIDTH/2, 25)

        barWidth = (WIDTH / bufferLength) * 2.5
        barHeight
        x = 0

        for i in [0..bufferLength]
          barHeight = dataArray[i]
          canvasCtx.fillStyle = 'rgb(' + (barHeight+100) + ',50,50)'
          #canvasCtx.fillRect(x,HEIGHT-barHeight/2,barWidth,barHeight/2)
          canvasCtx.fillRect(x,HEIGHT/2-barHeight/4,barWidth,barHeight/2)
          x += barWidth + 1

      draw()

    if navigator.getUserMedia
      if stream
        visualize(stream)
      else
        navigator.getUserMedia { audio: true }, visualize, (err) -> console.log('The following gUM error occured: ' + err)
    else
      console.log('getUserMedia not supported, no mic visualisation')

