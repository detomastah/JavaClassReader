require 'class_file_items'
require 'base_classes'


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
			if constant.class == Java::ClassFile::ItemInfo::StringInfo
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

class VirtualMachine
	attr_accessor :class_pool
	def initialize
		@class_pool = ClassPool.new
		@class_pool.load_classpath
	end
end


class_definition = Java::ClassFile::ClassDefinition.new
class_definition.read("DoWhileExample.class")

main_method = class_definition.methods.find {|m| m.name == "main"}

StackFrame.new(VirtualMachine.new, main_method.code, class_definition.constant_pool, nil, ["aaa", nil]).exec

#puts m.name
#m.attributes.each {|a| puts a.name }
