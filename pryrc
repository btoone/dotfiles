require "rubygems"
require "awesome_print"

Pry.print = proc { |output, value| output.puts value.ai }

Pry.commands.alias_command 'c', 'continue'
Pry.commands.alias_command 's', 'step'
Pry.commands.alias_command 'n', 'next'
