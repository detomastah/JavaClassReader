=begin

    u4             magic;
    u2             minor_version;
    u2             major_version;
    u2             constant_pool_count;
    cp_info        constant_pool[constant_pool_count-1];
    u2             access_flags;
    u2             this_class;
    u2             super_class;
    u2             interfaces_count;
    u2             interfaces[interfaces_count];
    u2             fields_count;
    field_info     fields[fields_count];
    u2             methods_count;
    method_info    methods[methods_count];
    u2             attributes_count;
    attribute_info attributes[attributes_count];

=end


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

class ConstantInfo
end

class FieldRefInfo < ConstantInfo
	attr_accessor :class_index, :name_and_type_index
	
	def initialize(f)
		@class_index = f.read_u2
		@name_and_type_index = f.read_u2
	end
end

class MethodRefInfo < FieldRefInfo
end

class InterfaceMethodRefInfo < FieldRefInfo
end

class ClassInfo < ConstantInfo
	attr_accessor :name_index

	def initialize(f)
		@name_index = f.read_u2
	end
end

class StringInfo < ConstantInfo
	attr_accessor :string_index

	def initialize(f)
		@string_index = f.read_u2
	end
end

class Utf8Info < ConstantInfo
	attr_accessor :length, :bytes

	def initialize(f)
		@length = f.read_u2;
		@bytes = f.read(@length)
		#puts @bytes
	end
end

class NameAndTypeInfo < ConstantInfo
	attr_accessor :name_index, :descriptor_index

	def initialize(f)
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


class JavaClassReader
	def initialize(file)
		@file = file
	end

	def read
		read_magic
		@minor = @file.read_u2
		read_major
		@pool_count = @file.read_u2
		read_constant_pool
		@access_flags = @file.read_u2
		@this_class = @file.read_u2
		@super_class = @file.read_u2
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
		(@pool_count - 1).times do
			constant_type_id = @file.read_u1
			constant_class = JavaConstantClasses[constant_type_id]
			#puts constant_class		
			constant = constant_class.new(@file)
			@constant_pool << constant
		end
	end

	
end

BigEndianFile.open("DoWhileExample.class", "rb") do |f|
	reader = JavaClassReader.new(f)
	reader.read
	puts reader.inspect
end