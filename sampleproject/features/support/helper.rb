# encoding: utf-8
############################################################################################
#Functions
############################################################################################

############################################################################################
#Web functions
############################################################################################


############################################################################################
#Call-backs
############################################################################################
def build_req_data_json(hashdata)
  return nil if hashdata.length == 0
  hashdata.to_json
end

def default_content_type
  'json'
end

require "base64"
def build_headers(hashdata)
  hashdata['Content-Type'] = "application/#{default_content_type}"
  #hashdata[:accept] = default_content_type
  #hashdata[:Authorization] ||= " Basic #{Base64.encode64("#{USERNAME}:#{PASSWORD}")}"
  return hashdata
end

def login_as(username, password)
  set_auth(:username => username, :password => password)
end