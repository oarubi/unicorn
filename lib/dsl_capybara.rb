# encoding: utf-8
module DSLSet
  module DSLCapybara
    require 'capybara'
    require 'capybara/dsl'
    require 'capybara/rspec/matchers'
    #require 'capybara/poltergeist'
    extend Capybara::DSL

    ## override capybara methods or add new methods
    class << self
        def config cfgs
          puts cfgs.to_s
          unless cfgs.keys.include?(:web_host) and cfgs.keys.include?(:browser)
            puts "parameters you should input are :web_host and :browser"
            exit 1
          end

          Capybara.app_host = cfgs[:web_host]
          browser = cfgs[:browser]
          # if browser == :poltergeist
          #   Capybara.default_driver = :poltergeist
          #   Capybara.register_driver :poltergeist do |app|
          #       options = {
          #           :js_errors => true,
          #           :timeout => 120,
          #           :debug => false,
          #           :phantomjs_options => ['--load-images=no', '--disk-cache=false'],
          #           :inspector => true,
          #       }
          #       Capybara::Poltergeist::Driver.new(app, options)
          #   end
          # else
            Capybara.register_driver :selenium do |app|
              Capybara::Selenium::Driver.new(app, :browser => browser)
            end
            Capybara.javascript_driver = browser         
            Capybara.default_driver = :selenium
          # end
          register_local_repo(cfgs[:local_repo]) if cfgs.keys.include?(:local_repo)
          Capybara.default_wait_time = cfgs[:default_wait_time] if cfgs.keys.include?(:default_wait_time)

          #Settings changed since v2.1, use the old config
          # Capybara.configure do |config|
          #   config.match = :one
          #   config.exact_options = true
          #   config.ignore_hidden_elements = true
          #   config.visible_text_only = true
          # end
        end

        def fill_in(locator, options={})
            raise "Must pass a hash containing 'with'" if not options.is_a?(Hash) or not options.has_key?(:with)
            if locator.nil? or locator.length == 0
              #No locator found, fill_in the Nth input box
              options[:index] ||= 0
              all('input')[options[:index]].set(options[:with].encode("GBK", "utf-8", :invalid => :replace,:undef => :replace, :replace => ""))
              return
            end
            sucFlg = false
            hash = options.dup
            hash.delete(:with)
            hash[:locator] = locator if locator and (not locator.empty?)
            default_xpaths(:input, hash) do |ele, idx|
              ele.set(options[:with]) 
              sucFlg = true unless sucFlg
              true  # tell "default_xpaths()" I am satisfied with this element
            end

            unless sucFlg
              puts "Locating #{locator} by id or name."
              find(:fillable_field, locator).set(options[:with])
            end
        end

        def select(value, options={})
            sucFlg = false
            hash = options.dup
            default_xpaths(:combo, hash) do |ele, idx|
                if options.has_key?(:from)
                    ele.find(:option, value).select_option
                else
                    ele.select_option
                end
                sucFlg = true unless sucFlg
                true  # tell "default_xpaths()" I am satisfied with this element
            end

            unless sucFlg
                if options.has_key?(:from)
                    find(:select, options[:from]).find(:option, value).select_option
                else
                    find(:option, value).select_option
                end
            end
        end

        def click_button(locator, options={})
            sucFlg = false

            hash = options.dup
            hash[:locator] = locator if locator and (not locator.empty?)
            index = hash.delete(:index)
            default_xpaths(:button, hash) do |ele, idx|
                if ele and ((idx and index and idx == index) or (idx.nil? or index.nil?))
                  ele.click 
                  #puts "Button #{locator} got clicked."
                  sucFlg = true unless sucFlg
                  break true  # tell "default_xpaths()" I am satisfied with this element
                else
                  p "Something went wrong. #{locator} #{ele}, #{idx}"
                end
            end
            raise "Unable to locate button: locator=#{locator}, options=#{options}" unless sucFlg
        end

        def attach_file(locator, path, options={})

            Array(path).each do |p|
              raise Capybara::FileNotFound, "cannot attach file, #{p} does not exist" unless File.exist?(p.to_s)
            end
            sucFlg = false

            hash = options.dup
            hash[:locator] = locator if locator and (not locator.empty?)
            index = hash.delete(:index)
            default_xpaths(:input, hash) do |ele, idx|
                if ele and ((idx and index and idx == index) or (idx.nil? or index.nil?))
                  ele.set(path) 
                  sucFlg = true unless sucFlg
                  break true  # tell "default_xpaths()" I am satisfied with this element
                end
            end

            find(:file_field, locator, options).set(path)          
        end
        def click_link(locator, options={})
            sucFlg = false
            hash = options.dup
            hash[:locator] = locator if locator and (not locator.empty?)
            default_xpaths(:link, hash) do |ele, idx|
                ele.click
                sucFlg = true unless sucFlg
                break true  # tell "default_xpaths()" I am satisfied with this element, and bye-bye!
            end

            unless sucFlg
              eles = all(:link, locator)
              if options[:index] and eles and eles.length > 1
                eles[options[:index]].click
              else
                find(:link, locator).click
              end
            end
        end 

        #The checkbox at the left side of label will be choosen by default.
        #Use :left_label if want to choose right side checkbox of a label     
        def check(locator, options={}, checked = true)
          #p locator
            sucFlg = false
            hash = options.dup
            hash[:locator] = locator if locator and (not locator.empty?)
            #p hash
            default_xpaths(:checkbox, hash) do |ele, idx|
              ele.set(checked)
              sleep 1
              sucFlg = true unless sucFlg
              true  # tell "default_xpaths()" I am satisfied with this element
            end

            if !(sucFlg or options[:left_label])
              #p 'should not be here.'
              find(:checkbox, locator, options).set(true)
            end
        end
        def uncheck(locator, options = {})
            check(locator, options, false)
        end
        
        #The radio button at the right side of label will be choosen by default.
        #Use :right_label if want to choose left side radio button of a label
        def choose(locator, options={})
            sucFlg = false
            hash = options.dup
            hash[:locator] = locator if locator and (not locator.empty?)
            default_xpaths(:radio, hash) do |ele, idx|
              ele.set(true)
              sleep 1
              sucFlg = true unless sucFlg
              true  # tell "default_xpaths()" I am satisfied with this element
            end

            unless sucFlg
              options = options.delete_if {|key, value| ![:text, :visible, :between, :count, :maximum, :minimum, :checked, :unchecked].include?(key)}
              puts options, locator
              find(:radio_button, locator).set(true)
            end
        end

        def click_tab(tab_name)
          xpaths = buildxpath(:tab, {:tab_name => tab_name})
          find_object_by_xpath(xpaths).click
        end

        def select_line(line_identifier)
          xpaths = buildxpath(:table_line, {:line_identifier => line_identifier})
          if line_identifier.include?(' ')
            newxpaths = xpaths.dup
            s = ''
            line_identifier.split(' ').each do |locator|
              s += "[contains(.,'#{locator}')]"
            end
            newxpaths.map! {|xpath| xpath.gsub!("[contains(.,'#{line_identifier}')]", s) }
            xpaths.concat(newxpaths)
          end
          ele = find_object_by_xpath(xpaths)
          ele.click 
        end
        def find_line(line_identifier)
          xpaths = buildxpath(:table_line, {:line_identifier => line_identifier})
          #p xpaths
          if line_identifier.include?(' ')
            newxpaths = xpaths.dup
            s = ''
            line_identifier.split(' ').each do |locator|
              s += "[contains(.,'#{locator}')]"
            end
            newxpaths.map! {|xpath| xpath.gsub!("[contains(.,'#{line_identifier}')]", s) }
            xpaths.concat(newxpaths)
          end
          ele = find_object_by_xpath(xpaths)
          ele 
        end
        def find_iframe(options)
          if options[:xpath]
            return find_object_by_xpath([options[:xpath]])
          else  
            xpaths = buildxpath(:iframe, options)
            return find_object_by_xpath(xpaths)
          end
        end
        def find_button(locator)
            hash = {}
            hash[:locator] = locator if locator and (not locator.empty?)
            default_xpaths(:button, hash) do |ele, idx|
                return ele
            end
        end
        def find_input(locator)
            options = {}
            options[:locator] = locator
            default_xpaths(:input, options) do |ele, idx|
                return ele
            end
        end
        def close_alert(acceptance = true)
          if acceptance
            page.driver.browser.switch_to.alert.accept 
          else
            page.driver.browser.switch_to.alert.dismiss
          end
        end

        def has_been_checked?(locator, options = {})
          begin
            options = options.dup
            options[:locator] = locator if locator and locator.length > 0
            #p options
            xpaths = buildxpath(:checkbox, options)
            return find_object_by_xpath(xpaths).checked?
          rescue => e
            puts e.message
            puts e.backtrace
            raise "Error occured when check result for #{locator}, #{e.message}"
          end
          return false
        end
        def has_been_chosen?(locator, options = {})
          begin
            options = options.dup
            options[:locator] = locator
            #p options
            xpaths = buildxpath(:radio, options)
            return find_object_by_xpath(xpaths).selected?
          rescue => e
            puts e.message
            puts e.backtrace
            raise "Error occured when check result for #{locator}, #{e.message}"
          end
          return false
        end

        def has_select?(locator, options = {})        
          options = options.dup
          options[:from] = locator
          xm = options.dup
          xm.delete :selected
          default_xpaths(:combo, xm) do |ele, idx|
            return ele.find(:option, options[:selected]).selected?
          end
          options, selected = [options, if options.has_key?(:selected) then {:selected => options.delete(:selected)} else {} end]
          has_xpath?(XPath::HTML.select(locator, options), selected)
        end
        def maximize
          Capybara.current_session.driver.browser.manage().window().maximize()
        end
        def clear_browser_cookies
          browser = Capybara.current_session.driver.browser
          if browser.respond_to?(:clear_cookies)
            # Rack::MockSession
            browser.clear_cookies
          elsif browser.respond_to?(:manage) and browser.manage.respond_to?(:delete_all_cookies)
            # Selenium::WebDriver
            browser.manage.delete_all_cookies
          else
            raise "Don't know how to clear cookies. Weird driver?"
          end
        end
      def find_xpath(xpath)
        #p xpath
        obj = page.find(:xpath, xpath)
        #p obj
        #obj = obj[0] if obj and obj.class == Array
        #p obj
        #p obj.text
        #p obj.value
        return obj
      end
    private
        require File.join(File.dirname(__FILE__), 'xpath_repo.rb')
        include XpathRepo 
        def register_local_repo filepath
          XpathRepo.register_repo(filepath)
        end

        #Return the first matched object by given xpaths
        def find_object_by_xpath(xpaths)
          err = []
          x = Capybara.default_wait_time
          begin
            Capybara.default_wait_time = 0.1
            i = 0
            while i < x*10
              begin
                xpaths.each do |xpath|
                  begin
                    obj = page.find(:xpath => xpath)
                    if obj
                      #p xpath
                      return obj 
                    end
                  rescue => e
                    if e.class == Capybara::Ambiguous
                      eles = page.all(:xpath, xpath)
                      eles.each do |ele|
                        obj = ele
                        if obj.visible?
                          #p xpath
                          return obj 
                        end
                      end
                    elsif e.class != Capybara::ElementNotFound
                      raise e
                    end
                  end
                end   
              rescue => ex
              end
              i += 1
            end 
          rescue => er
          ensure
            Capybara.default_wait_time = x
          end
        end

        def default_xpaths type, hash
          x = Capybara.default_wait_time
          sucFlg = false
          list = []
          begin
            i = 0
            Capybara.default_wait_time = 0.1
            while i < x*10 and !sucFlg
              begin
                buildxpath(type, hash).each do |xpath|
                  #puts xpath
                  begin
                    ele = find(:xpath, xpath)
                    if ele.visible?
                      #puts xpath
                      sucFlg = yield ele 

                      break if sucFlg
                    end
                  rescue => e
                    if e.class == Capybara::Ambiguous
                      puts "Capybara::Ambiguous match found for xpath: #{xpath}"
                      all(:xpath, xpath).each_with_index do |ele, idx| 
                        if ele.visible?
                          sucFlg |= yield ele, idx 
                          break if sucFlg
                        end
                      end
                    else
                      #puts e
                      list << e
                    end
                  end
                end

                unless sucFlg 
                  #puts "Locating #{locator} by id or name."
                  if type == :input
                    sucFlg = yield find(:fillable_field, hash[:locator]) 
                  else
                    sucFlg = yield find(type, hash[:locator]) if hash[:locator] and hash[:locator].length > 0
                  end
                end
              rescue => eex
              end
              i += 1
            end
          rescue => ee
          ensure
            Capybara.default_wait_time = x
          end
        end        
    end
  end
end
