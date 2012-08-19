
class JavaObject < Hash
end

class JavaReturnNothing
end

class JavaClass
	attr_accessor :static_fields, :static_methods, :instance_methods
	def initialize(name)
		@static_fields = Hash.new
		@static_methods = Hash.new
		@instance_methods = Hash.new
		@instance_fields = Hash.new
	end
end

class ClassPool
	def initialize
		@classes = Hash.new
	end

	def get_class(name)
		@classes.fetch(name)
	end
	
	def load_classpath
		java_lang_system = JavaClass.new('java/lang/System')
		java_lang_string_builder = JavaClass.new('java/lang/StringBuilder')
		java_io_print_stream = JavaClass.new('java/io/PrintStream')
		@classes['java/lang/System'] = java_lang_system
		@classes['java/lang/StringBuilder'] = java_lang_string_builder
		@classes['java/io/PrintStream'] = java_io_print_stream
		#
		java_lang_string_builder.instance_methods['<init>:()V'] = lambda {
			|this|
			this['str'] = ""
		}
		java_lang_string_builder.instance_methods['append:(Ljava/lang/String;)Ljava/lang/StringBuilder;'] = lambda {
			|this, str|
			this['str'] += str
			return this
		}
		java_lang_string_builder.instance_methods['append:(I)Ljava/lang/StringBuilder;'] = lambda {
			|this, int|
			this['str'] += int.to_s
			return this
		}
		java_lang_string_builder.instance_methods['toString:()Ljava/lang/String;'] = lambda {
			|this|
			return this['str']
		}
		java_io_print_stream.instance_methods['println:(Ljava/lang/String;)V'] = lambda {
			|this, str|
			puts str
			return JavaReturnNothing
		}
		
		


		java_lang_system.static_fields['out'] = JavaObject.new({'io' => ::IO.new(STDOUT.fileno, "w")})
		
	end
end

module Java
	module Lang
		class String
			def __init
				return self
			end
		end

		class System
			def self.static_field_out
				Java::Io::PrintStream.new.__init
			end
		end

		class StringBuilder
			def __init
			end
		end
	end

	module Io
		class PrintStream
			def __init
				@io = ::IO.new(STDOUT.fileno)
				return self
			end
		end
	end
end
