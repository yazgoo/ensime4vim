# ensime4vim

tools to be able to use ensime with vim

# demo

![alt tag](https://raw.github.com/yazgoo/ensime4vim/master/demo.gif)

# howto

You need to clone this repository first.
All the following commands should be run from your scala directory.

First you need ensime sbt plugin:    
    
    $ echo addSbtPlugin("org.ensime" % "ensime-sbt" % "0.1.7") >> ~/.sbt/0.13/plugins/plugins.sbt

Then, generate .ensime file:

    $ sbt gen-ensime

In a new terminal, start ensime server:

    /path/to/ensime4vim/start_ensime.sh .ensime

In another terminal, start ensime bridge:

    /path/to/ensime4vim/ensime.rb

Finally, launch vim with the plugin and the file(s) you want to edit:

    vim -S /path/to/ensime4vim/ensime.vim src/scaloid/example/HelloScaloid.scala
