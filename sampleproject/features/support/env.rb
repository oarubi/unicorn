# encoding: utf-8
############################################################################################
#Paramaters
############################################################################################
require File.join(File.dirname(__FILE__), 'config.rb')
##################################################################################
#This section will define the driver
##################################################################################
require File.join(File.expand_path('../../../../lib', __FILE__), 'DSL.rb')

Before do
	set_default_driver "restful" 
	get_connection
end

config :driver=>"restful", 
	:web_host=>"#{APP_PROTOCAL}://#{APP_HOST}:#{APP_PORT}"

config :driver=>"capybara", 
	:web_host=>"#{APP_PROTOCAL}://#{APP_HOST}:#{APP_PORT}", 
	:browser=>:chrome,#:poltergeist, 
	:local_repo=>File.join(File.dirname(__FILE__), 'xpath_repo_local.txt'),
	:default_wait_time=>3

# config :driver=>"sikuli",
# 	:similarity => 0.8,
# 	:image_path => File.dirname(__FILE__)+'/../../images',
# 	:default_wait_time=>30

require File.join(File.dirname(__FILE__), 'helper.rb')

Before "@web" do
	set_default_driver "capybara" 
end

#Read command paramter of --out, will be used if it's html to generate better formatted output
#for report
AfterConfiguration do |configuration|
	if configuration.formats and configuration.formats[0] 
		#puts configuration.formats[0][0]
		$exe_output = configuration.formats[0][0]
	end
end

##################################################################################
#This section will define the execution order
#Please turn this feature off if you need to execute with tags.
##################################################################################
execution_order = false
if execution_order
	require File.dirname(__FILE__)+'/patch_execution_order.rb'
end