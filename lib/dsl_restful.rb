module DSLSet
	module DSLRestful
		require 'rest_client'
		require "base64"
		require "nori"
		require 'json'
		
		class << self

	        def config cfgs
	          puts "Calling config: #{cfgs.to_s}"
	          unless cfgs.keys.include?(:web_host)
	            puts "parameters you should input are :web_host"
	            exit 1
	          end
	          $web_host = cfgs[:web_host]
	        end

			def visit(uri)
				cleanup
				$uri = uri
				$properties ||= {}
			end

			def set_auth(options)
				$headers[:Authorization] = "Basic #{Base64.encode64("#{options[:username]}:#{options[:password]}")}"
			end

			def fill_in(locator, options = {})
				$properties ||= {}
				if locator.split('/').length > 0
					hash = options[:with]
					#p hash
					locator.split('/').reverse.each do |node|
						if locator =~ /^#{node}/
							$properties[node.downcase] = hash
						else
							hash = {node => hash}
						end
					end
					#p $properties

				else
					$properties[locator.downcase] = options[:with]
				end
				
			end

			def get(url)
				delegate(:get, url, $properties)
			end

			alias :retrieve :get

			def put(url)
				delegate(:put, url, self.send("build_req_data_#{get_content_type}", $properties))
			end

			alias :update :put

			def post(url)
				delegate(:post, url, self.send("build_req_data_#{get_content_type}", $properties))
			end	

			alias :create :post
			
			def delete(url)
				delegate(:delete, url, $properties)
			end

			def page()
				self
			end
			def read_id(resp_body, xpath = nil)
				self.send("read_id_#{get_content_type}", resp_body, xpath)
			end			
			def resp_body()			
				if $response					
					if $response.class == String
						return $response
					elsif $response.class == RestClient::Unauthorized
						return nil
					else
						return $response.body 
					end
				end
			end
			def result_data
				if default_content_type == 'xml'
					nori.parse(resp_body)
				elsif default_content_type == 'json'
					begin
						s = JSON.parse(resp_body)
						return s
					rescue => e
						puts e
					end
				end
			end
			def resp_code
				if $response					
					if $response.class == String
						return $response
					elsif $response.class == RestClient::Unauthorized
						return $response.http_code
					else
						return $response.code 
					end
				end
			end
			def has_content?(text)
				return $response =~ /#{text}/
			end
			def has_no_content?(text)
				return !has_content?(text)
			end
			private
			def cleanup
				$properties = {}
				$headers ||= {}
				auth = $headers[:Authorization]
				$headers = {}
				$headers[:Authorization] = auth
				$content_type = nil
			end

			def delegate(call, url, data)
				requrl = build_req_url(call, url, data)
				appurl = "#{$web_host}#{$uri+requrl}" 
				build_headers($headers)
				begin
					puts "#{call} #{appurl}"
					if call =~ /get|retrieve|delete/						
						$response = RestClient.send(call, URI.encode(appurl), $headers)
					else
						$headers[:content_type] = "application/#{default_content_type}"
						$headers[:accept] = default_content_type
						if $exe_output == 'html' and data
							puts to_html(data)
						else
							puts data
						end
						$response = RestClient.send(call, appurl, data, $headers)
					end
				rescue => ex
					#p ex.class
					autinfo = ''
					if $headers[:Authorization]
						autinfo = Base64.decode64($headers[:Authorization].split(' ')[1])
					end
					er = "Server failed to process the request, #{ex.message}\nheaders: #{$headers}, #{autinfo}\ndata: \n#{data}"
					puts er
					raise er if ex.message =~ /500/
					$response = ex.message
					return
				end

				#Set session id
				if $response and $response.code >= 200 and $response.code < 300
					if $response.headers[:content_type]
						$content_type = $response.headers[:content_type]
					end
					if $response.cookies['_applicatioN_session_id']
						set_session($response.cookies['_applicatioN_session_id'])
						#p $headers
					else
						#puts "Seesion not found from cookie. #{$response.cookies} #{$response.headers}"
					end
					format_data = $response.body
					if $content_type =~ /xml/ and format_data
						#puts "Formatting output with xml format"
						doc = Nokogiri::XML($response.body){ |x| x.noblanks }
						format_data = doc.to_xml(:indent => 2, :encoding => 'UTF-8')
						if $exe_output == 'html'
							format_data = to_html(format_data)
						end

					end
					puts "Response code: #{$response.code}, Response body:\n#{format_data}"
				else
					puts "Response code: #{$response.code}, Response body: #{$response.body}" if $response
				end	
				$response
			end

			def to_html(xml)
				return nil if xml.nil?
				s = xml.gsub('<','&lt;')
				s.gsub!('>','&gt;')
				'<pre>'+s+'</pre>'
			end
			def get_content_type
				if $content_type
					t = $content_type.scan(/\/([a-z]*)/)
					if t and t[0] and t[0].class ==Array
						#puts "#{$content_type} #{t}"
						return t[0][0]
					end
					return "Unable to parse content type from #{$content_type}"
				else
					puts "No content type, use default: #{default_content_type}"
				end
				default_content_type
			end
			def set_session(sessionid)
				$headers[:session] = {:session_id => sessionid}
			end
			def build_req_url call, method, data
				appurl = method && method.length > 0 ? "/#{method}" : ''
				if call =~ /get|retrieve/
					query = ''	
					data.each do |key, value|
						query += "#{key}=#{value}&"
					end
					#query.delete!(/\&$/)
					if query.length > 0
						appurl += "?#{query}"
					end
				end
				return appurl
			end
		    def nori
		      return @nori if @nori

		      nori_options = {
		        :strip_namespaces     => true,
		        :convert_tags_to      => lambda { |tag| tag.snakecase.to_sym},
		        :advanced_typecasting => true,
		        :parser               => :nokogiri
		      }

		      non_nil_nori_options = nori_options.reject { |_, value| value.nil? }
		      @nori = Nori.new(non_nil_nori_options)
		    end
		end
	end
end

