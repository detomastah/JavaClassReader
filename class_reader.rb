class BigEndianFile < File
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

class BaseInfo
	def initialize(reader, f)
		@reader = reader
	end
end

class FieldRefInfo < BaseInfo
	attr_accessor :class_index, :name_and_type_index
	
	def initialize(reader, f)
		super
		@class_index = f.read_u2
		@name_and_type_index = f.read_u2
	end
end

class MethodRefInfo < FieldRefInfo
end

class InterfaceMethodRefInfo < FieldRefInfo
end

class ClassInfo < BaseInfo
	attr_accessor :name_index

	def initialize(reader, f)
		super
		@name_index = f.read_u2
	end
end

class StringInfo < BaseInfo
	attr_accessor :string_index

	def initialize(reader, f)
		super
		@string_index = f.read_u2
	end
end

class Utf8Info < BaseInfo
	attr_accessor :length, :bytes

	def initialize(reader, f)
		super
		@length = f.read_u2;
		@bytes = f.read(@length)
		#puts @bytes
	end
end

class NameAndTypeInfo < BaseInfo
	attr_accessor :name_index, :descriptor_index

	def initialize(reader, f)
		super
		@name_index = f.read_u2;
		@descriptor_index = f.read_u2
	end
end

JavaConstantClasses = {
	7 => ClassInfo,
	9 => FieldRefInfo,
	10 => MethodRefInfo,
	11 => InterfaceMethodRefInfo,
	8 => StringInfo,
	3 => :CONSTANT_Integer,
	4 => :CONSTANT_Float,
	5 => :CONSTANT_Long,
	6 => :CONSTANT_Double,
	12 => NameAndTypeInfo,
	1 => Utf8Info,
	15 => :CONSTANT_MethodHandle,
	16 => :CONSTANT_MethodType,
	18 => :CONSTANT_InvokeDynamic
}

class AttributeInfo < BaseInfo
	attr_accessor :attribute_name_index, :attribute_length, :info
	def initialize(reader, f)
		super
		@attribute_name_index = f.read_u2
		@attribute_length = f.read_u4
		@info = f.read(@attribute_length)
	end

	def name
		@reader.constant_pool.fetch(@attribute_name_index).bytes
	end
end

class FieldInfo < BaseInfo
	attr_accessor :access_flags, :name_index, :descriptor_index, :attributes_count, :attributes
	def initialize(reader, f)
		super
		@access_flags = f.read_u2
		@name_index = f.read_u2
		@descriptor_index = f.read_u2
		@attributes_count = f.read_u2
		@attributes = []
		@attributes_count.times do
			@attributes << AttributeInfo.new(reader, f)
		end
	end

	def name
		@reader.constant_pool.fetch(@name_index).bytes
	end
end

class MethodInfo < BaseInfo
	attr_accessor :access_flags, :name_index, :descriptor_index, :attributes_count, :attributes
	def initialize(reader, f)
		super
		@access_flags = f.read_u2
		@name_index = f.read_u2
		@descriptor_index = f.read_u2
		@attributes_count = f.read_u2
		@attributes = []
		@attributes_count.times do
			@attributes << AttributeInfo.new(reader, f)
		end
	end

	def name
		@reader.constant_pool.fetch(@name_index).bytes
	end
end

class JavaClassReader
	attr_reader :constant_pool, :fields, :methods
	
	def initialize(file)
		@file = file
	end

	def read
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
			constant_class = JavaConstantClasses[constant_type_id]
			#puts constant_class		
			constant = constant_class.new(self, @file)
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
		@attributes_count.times { @attributes << AttributeInfo.new(self, @file) }
	end
end

BigEndianFile.open("DoWhileExample.class", "rb") do |f|
	reader = JavaClassReader.new(f)
	reader.read
	m = reader.methods[1]
	puts m.name
	m.attributes.each {|a| puts a.name }
end