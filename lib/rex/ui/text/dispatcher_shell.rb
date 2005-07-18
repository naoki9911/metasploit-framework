require 'rex/ui'

module Rex
module Ui
module Text

###
#
# DispatcherShell
# ---------------
#
# The dispatcher shell class is designed to provide a generic means
# of processing various shell commands that may be located in
# different modules or chunks of codes.  These chunks are referred
# to as command dispatchers.  The only requirement for command dispatchers is
# that they prefix every method that they wish to be mirrored as a command
# with the cmd_ prefix.
#
###
module DispatcherShell

	###
	#
	# CommandDispatcher
	# -----------------
	#
	# Empty template base class for command dispatchers
	#
	###
	module CommandDispatcher

		def initialize(shell)
			self.shell = shell
			self.tab_complete_items = []
		end

		def commands
		end
		
		def print_error(msg = '')
			shell.print_error(msg)
		end

		def print_status(msg = '')
			shell.print_status(msg)
		end

		def print_line(msg = '')
			shell.print_line(msg)
		end

		def print(msg = '')
			shell.print(msg)
		end

		def update_prompt(prompt)
			shell.update_prompt(prompt)
		end

		#
		# No tab completion items by default
		#
		attr_accessor :shell, :tab_complete_items

	end

	#
	# DispatcherShell derives from shell
	#
	include Shell

	#
	# Initialize the dispatcher shell
	#
	def initialize(prompt, prompt_char = '>')
		super

		self.dispatcher_stack = []
	end

	#
	# Performs tab completion on shell input if supported
	#
	def tab_complete(str)
		items = []

		# Next, try to match internal command or value completion
		# Enumerate each entry in the dispatcher stack
		dispatcher_stack.each { |dispatcher|
			# If it supports commands, query them all
			if (dispatcher.respond_to?('commands'))
				items.concat(dispatcher.commands.to_a.map { |x| x[0] })
			end

			# If the dispatcher has custom tab completion items, use them
			items.concat(dispatcher.tab_complete_items || [])
		}

		items.find_all { |e| 
			e =~ /^#{str}/
		}
	end

	# Run a single command line
	def run_single(line)
		arguments = parse_line(line)
		method    = arguments.shift
		found     = false

		reset_color if (supports_color?)

		if (method)
			entries = dispatcher_stack.length

			dispatcher_stack.each { |dispatcher|
				begin
					if (dispatcher.respond_to?('cmd_' + method))
						eval("
							dispatcher.#{'cmd_' + method}(*arguments)
							found = true")
					end
				rescue
					output.print_error("Error while running command #{method}: #{$!}")
				end

				# If the dispatcher stack changed as a result of this command,
				# break out
				break if (dispatcher_stack.length != entries)
			}

			if (found == false)
				unknown_command(method, line)
			end
		end

		return found
	end

	#
	# If the command is unknown...
	#
	def unknown_command(method, line)
		output.print_error("Unknown command: #{method}.")
	end

	# Push a dispatcher to the front of the stack
	def enstack_dispatcher(dispatcher)
		self.dispatcher_stack.unshift(dispatcher.new(self))
	end

	# Pop a dispatcher from the front of the stacker
	def destack_dispatcher
		self.dispatcher_stack.shift
	end



	attr_accessor :dispatcher_stack

end

end
end
end
