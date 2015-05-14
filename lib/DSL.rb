# encoding: utf-8
require 'rubygems'
require File.join(File.dirname(__FILE__), 'dsl_capybara.rb')
require File.join(File.dirname(__FILE__), 'dsl_restful.rb')
#require File.join(File.dirname(__FILE__), 'dsl_sikuli.rb')

module DSLSet
	def default_driver
		@@default_driver
	end

	def set_default_driver driver
		driver = "DSL#{driver.capitalize}" unless driver =~ /^DSL/
		if @@dsl_set.keys.include?(driver.to_sym)
			@@default_driver = driver if (driver != @@default_driver)
			if driver.downcase =~ /sikuli/
				require File.join(File.dirname(__FILE__), 'dsl_sikuli.rb')
			end
		else 
			puts "Invalid parameter: #{driver}"	
		end
	end	

	class << self

		def key_words
			@@dsl_set.values.flatten.uniq
		end

		def drivers
			ds = {}

			@@dsl_set.each do |key, value|
				ds[key] = {}
				dm = DSLSet.module_eval(key.to_s)
				value.each do |v|
					ds[key][v] = dm.public_method(v).parameters
				end
			end

			ds
		end

		def init
			@@default_driver = "" # "DSLCapybara"
			@@dsl_set = {}
			DSLSet.constants.collect do |cnst_name|
				m = DSLSet.const_get(cnst_name)
				@@dsl_set[cnst_name] = []
				dm = DSLSet.module_eval(cnst_name.to_s)
				dm.singleton_methods.each do |k|
					@@dsl_set[cnst_name] << k 
				end
			end
			key_words.each do |kw|
				define_method(kw) do |*args, &block|
					driver = @@default_driver
					ps = []
					args.each_with_index do |arg, idx|
						if arg.is_a?(Hash) and arg.keys.include?(:driver)
							driver = arg[:driver]
							th = arg.dup
							th.delete :driver
							ps << th unless th.empty?
							ps += args[(idx+1)..-1]
							break
						else
							ps << arg
						end
					end		

					driver = "DSL#{driver.capitalize}" unless driver =~ /^DSL/
					unless driver and @@dsl_set.keys.include?(driver.to_sym)
						puts "You are setting #{driver} as driver, which is not valid."
						puts "Please choose a driver from #{@@dsl_set.keys.to_s}"
						raise "You are setting #{driver} as driver, which is not valid. Please choose a driver from #{@@dsl_set.keys.to_s}"
					end

					if @@dsl_set[driver.to_sym] and @@dsl_set[driver.to_sym].include?(kw)
						mtd = DSLSet.module_eval(driver).public_method(kw)
						begin
							mtd.call(*ps, &block)
						rescue ArgumentError=>e
							puts "="*50
							puts e.to_s
							puts "method \"#{kw}\" of driver \"#{driver}\" was called"
							puts "expected parameter is #{mtd.parameters.to_s}"
							puts "actual parameters input are " + ps.to_s
							project_dir = File.expand_path(File.join(File.expand_path(__FILE__), '..\..'))
							pd = Regexp.new("^#{project_dir}")
							e.backtrace.each {|line| puts line if line=~pd}
							puts "="*50
						end
					else
						raise "#### driver \"#{driver}\" doesn't exist or it has not method \"#{kw}\" ####"

					end
				end
			end
		end	
	end
end

DSLSet.init
include DSLSet

# if __FILE__
# 	puts "\n\n"
# 	puts DSLSet.drivers
# 	puts "\n\n"
# 	puts DSLSet.key_words.sort
# 	puts "\n\n"
# end