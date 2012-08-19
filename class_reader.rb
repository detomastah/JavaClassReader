require 'class_file_items'
require 'base_classes'

module JavaClassFile
	module BigEndianMethods
		def read_u4
			self.read(4).unpack("N").first
		end

		def read_u2
			self.read(2).unpack("n").first
		end

		def read_u1
			self.read(1).unpack("C").first
		end
	end
	
	class BigEndianFile < File
		include BigEndianMethods
	end

	class ClassData
		attr_reader :constant_pool, :fields, :methods

		def read(file_path)
			@file = BigEndianFile.open(file_path, "rb")
					
			read_magic
			@minor = @file.read_u2
			read_major
			@constant_pool_count = @file.read_u2
			read_constant_pool
			@access_flags = @file.read_u2
			@this_class = @file.read_u2
			@super_class = @file.read_u2
			@interfaces_count = @file.read_u2
			read_interfaces
			@fields_count = @file.read_u2
			read_fields
			@methods_count = @file.read_u2
			read_methods
			@attributes_count = @file.read_u2
			read_attributes

			@file.close
		end

		private
		def read_magic
			@magic = @file.read_u4
			raise "Not a class file" if @magic != 0xCAFEBABE
		end

		def read_major
			@major = @file.read_u2
			raise "Not Java SE 6 class" if @major != 0x32
		end

		def read_constant_pool
			@constant_pool = [nil] #zero index is not used, since indexing starts from 1 to pool_count - 1
			(@constant_pool_count - 1).times do
				constant_type_id = @file.read_u1
				constant = ConstantInfoFactory.produce(constant_type_id, self, @file)
				@constant_pool << constant
			end
		end

		def read_interfaces
			@interfaces = []
			@interfaces_count.times { @interfaces << @file.read_u2 }
		end

		def read_fields
			@fields = []
			@fields_count.times { @fields << FieldInfo.new(self, @file) }
		end

		def read_methods
			@methods = []
			@methods_count.times { @methods << MethodInfo.new(self, @file) }
		end

		def read_attributes
			@attributes = []
			@attributes_count.times { @attributes << AttributeInfoFactory.produce(self, self, @file) }
		end
	end


	class StackFrame
		attr_accessor :pc, :code, :stack
		def initialize(vm, code, constant_pool, prev_stack_frame = nil, vals_to_push = [])
			@vm = vm
			@code = code
			@prev_stack_frame = prev_stack_frame
			@constant_pool = constant_pool
			@pc = 0
			@stack = []
			vals_to_push.each {|val| self.push(val) }
		end

		def push(val)
			@stack.push(val)
		end

		def pop
			@stack.pop
		end

		def top
			@stack.last
		end

		def get_index_arg
			index1 = @code[@pc + 1]
			index2 = @code[@pc + 2]
			(index1 << 8) + index2
		end

		def get_pc_arg
			@code[(@pc + 1)..(@pc + 2)].reverse.unpack('s').first
		end

		def exec
			opcode = @code[@pc]
			case opcode
			when 0x03 #iconst_0
				
				push(0)
				@pc += 1
			when 0x08 #iconst_5

				push(5)
				@pc += 1
			when 0x3c #istore_1
				
				@stack[1] = pop
				@pc += 1
			when 0x1b #iload_1
				
				push(@stack[1])
				@pc += 1
			when  0xb2 #getstatic
				
				index = get_index_arg
				class_index = @constant_pool[index].class_index
				name_and_type_index = @constant_pool[index].name_and_type_index
				class_name_index = @constant_pool[class_index].name_index
				method_name_index = @constant_pool[name_and_type_index].name_index
				descriptor_index = @constant_pool[name_and_type_index].descriptor_index
				class_name = @constant_pool[class_name_index].bytes
				method_name = @constant_pool[method_name_index].bytes
				descriptor = @constant_pool[descriptor_index].bytes
				push(@vm.class_pool.get_class(class_name).static_fields.fetch(method_name))
				@pc += 3
			when 0xbb #new
				index = get_index_arg
				class_name_index = @constant_pool[index].name_index
				class_name = @constant_pool[class_name_index].bytes
				#klass = class_name.split("/").collect {|n| n.capitalize}.inject(Object) {|memo,name| memo = memo.const_get(name); memo}
				push(JavaObject.new)
				@pc += 3
			when 0x59 #dup
				
				push(top)
				@pc += 1
			when 0xb7 #invokespecial
				
				index = get_index_arg
				class_index = @constant_pool[index].class_index
				name_and_type_index = @constant_pool[index].name_and_type_index
				class_name_index = @constant_pool[class_index].name_index
				method_name_index = @constant_pool[name_and_type_index].name_index
				descriptor_index = @constant_pool[name_and_type_index].descriptor_index
				class_name = @constant_pool[class_name_index].bytes
				method_name = @constant_pool[method_name_index].bytes
				descriptor = @constant_pool[descriptor_index].bytes
				method_name += ":" + descriptor
				method = @vm.class_pool.get_class(class_name).instance_methods.fetch(method_name)
				args = []
				method.arity.times { args << pop()}
				args = args.reverse
				method.call(*args)
				@pc += 3
			when 0x12 #ldc
				
				index = @code[@pc + 1]
				constant = @constant_pool[index]
				if constant.class == StringInfo
					push(@constant_pool[constant.string_index].bytes)
				else
					raise "Unknown class"
				end
				@pc += 2
			when 0xb6 #invokevirual
				
				index = get_index_arg
				class_index = @constant_pool[index].class_index
				name_and_type_index = @constant_pool[index].name_and_type_index
				class_name_index = @constant_pool[class_index].name_index
				method_name_index = @constant_pool[name_and_type_index].name_index
				descriptor_index = @constant_pool[name_and_type_index].descriptor_index
				class_name = @constant_pool[class_name_index].bytes
				method_name = @constant_pool[method_name_index].bytes
				descriptor = @constant_pool[descriptor_index].bytes
				method_name += ":" + descriptor
				method = @vm.class_pool.get_class(class_name).instance_methods.fetch(method_name)
				
				args = []
				method.arity.times { args << pop()}
				args = args.reverse
				retval = method.call(*args)
				push(retval) if retval.class != JavaReturnNothing
				@pc += 3
			when 0x84 #iinc
				@stack[@code[@pc + 1]] += @code[@pc + 2]
				@pc += 3
			when 0xa1 #if_icmplt
				index = get_pc_arg
				val2 = pop
				val1 = pop
				if val1 < val2
					@pc += index
				else
					@pc += 3
				end
			when 0xb1
				return JavaReturnNothing
			else
				raise "Unknown OPCODE: " + opcode.to_s(16)
			end
			exec
		end
	end
end

class VirtualMachine
	attr_accessor :class_pool
	def initialize
		@class_pool = ClassPool.new
		@class_pool.load_classpath
		
		class_data = JavaClassFile::ClassData.new
	end
end


class_data = JavaClassFile::ClassData.new
class_data.read("DoWhileExample.class")

main_method = class_data.methods.find {|m| m.name == "main"}

JavaClassFile::StackFrame.new(VirtualMachine.new, main_method.code, class_data.constant_pool, nil, ["aaa", nil]).exec

#puts m.name
#m.attributes.each {|a| puts a.name }
