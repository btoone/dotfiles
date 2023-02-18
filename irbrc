require "rubygems"
require "awesome_print"

# Use awesome_print as the default formatter
AwesomePrint.irb!

# Enable auto-indenting
IRB.conf[:AUTO_INDENT] = true

# Add a global method to inspect the source of any method
def view_source_for(object, method)
  location = object.method(method).source_location
  `mvim #{location[0]} +#{location[1]}` if location
  location
end
alias vsf view_source_for

# Pass in the location array from either:
# * User.new.method(:full_name).source_location
# * Module.const_source_location "DateCalculations"
def view_source(location)
  `mvim #{location[0]} +#{location[1]}` if location
  location
end
