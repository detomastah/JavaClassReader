module JavaClassFile
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

	class ConstantInfoFactory
		@@classes = {
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

		def self.produce(constant_type_id, reader, file)
			@@classes.fetch(constant_type_id).new(reader, file)
		end
	end

end