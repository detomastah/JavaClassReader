require 'class_file_items'

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
end


class_data = JavaClassFile::ClassData.new
class_data.read("DoWhileExample.class")
#m = class_data.methods[1]
#puts m.name
#m.attributes.each {|a| puts a.name }
