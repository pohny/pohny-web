=========
pohny-web
=========

This application is a web client phone written in javascript.
It's using websocket and a bit of http to communicate with an instance of pohny-server.
Phone client manage contacts, conversation (via sms), and calling features.

**Some screenshots**:

> Add Contact:

  .. image:: https://raw.githubusercontent.com/pohny/pohny-web/master/assets/add_contact.png
     :alt: Add contact
     :width: 100%
     :align: left

> List Contact:

  .. image:: https://raw.githubusercontent.com/pohny/pohny-web/master/assets/contacts.png
     :alt: List contact
     :width: 100%
     :align: left

> List Conversations:

  .. image:: https://raw.githubusercontent.com/pohny/pohny-web/master/assets/conversations.png
     :alt: List Conversation
     :width: 100%
     :align: left

> Chat:

  .. image:: https://raw.githubusercontent.com/pohny/pohny-web/master/assets/conversation.png
     :alt: Chat
     :width: 100%
     :align: left

> Phone: http://puu.sh/pg4JL/b8b916eeba.png

  .. image:: https://raw.githubusercontent.com/pohny/pohny-web/master/assets/voice.png
     :alt: Phone
     :width: 100%
     :align: left



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
