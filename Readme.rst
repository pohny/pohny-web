=========
pohny-web
=========

This application is a web client phone written in javascript.
It's using websocket and a bit of http to communicate with an instance of pohny-server.
Phone client manage contacts, conversation (via sms), and calling features.


Requirements
============

- **coffeescript** ("npm install -g coffee-script")

- install pohny-ver - https://github.com/pohny/pohny-ver


Installation
=============

1. clone pohny web repository and open project folder

2. Compile coffee script `npm run build`

3. serve public using any static content provider.

/!\\ Note: you have to serve your content under the same domain you're using for pohny-server


Folder architecture
===================

**public**  = public ressources, static content accessible from outside
*(/path/to/project/public/path/to/something is my.website.com/path/to/something) and contains public resources like the index.php but also the css, js and the images.*

**src**     = coffeescript sources

**build**   = compiled source
