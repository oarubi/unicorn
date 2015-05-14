module XpathRepo
	# XpathRepoFile = File.join(File.dirname(__FILE__),'xpath_repository')
	ParamHolder = /%.*?%/
	CommentInitial = /^#.*/
	SectionHolder = /^\s*\[([A-Za-z_]*?)\]\s*$/

	@@repos = []
	@@repos << {:file=>File.open(File.join(File.dirname(__FILE__),'xpath_repo_global.txt'), 'r'), :section=>{}}
	at_exit { @@repos.each {|repo| repo[:file].close} }

	def self.register_repo filepath
		if File.exist?(filepath)
			@@repos << {:file=>File.open(filepath, 'r'), :section=>{}} 
		end
	end

	def buildxpath(type, hash)
		xpaths = []

		#puts "\ntype: #{type.to_s}, hash: #{hash.to_s}"
		@@repos.reverse.each do |repo|
			xpaths << get_xpath(repo, type, hash)
		end

		xpaths = xpaths.flatten.uniq

		#puts "Xpaths: #{xpaths}"

		xpaths
	end

	def get_xpath(repo, type, hash)
		file = repo[:file]
		section = repo[:section]
		xpath = []

		sk = 0
		if section.keys.include?(type)
			sk = section[type]
		elsif not section.empty?
			sk = section.values.max
		end
		# puts "seek : #{sk}th line"

		inkeys = hash.keys
		maxln = section.values.max
		hitsect = false # got the section related to the type
		file.seek 0
		file.each_with_index do |line, number|
			next if number < sk

			lc = line.strip.gsub(CommentInitial, "")
			next if lc.empty?

			smt = lc.match(SectionHolder)
			if smt
				if (not maxln) or (number > maxln)
					section[smt[1].to_sym] = number
				end

				if hitsect
					break
				else
					hitsect = true if type == smt[1].to_sym
				end

				next
			end

			unusedparam = hash.dup
			if hitsect
				flg = true
				lc.gsub!(ParamHolder) do |holder|
					param = holder[1...-1].to_sym
					unless inkeys.include?(param)
						flg = false
						break
					end
					unusedparam.delete param
					hash[param].to_s
				end
				hash.values.each do |value|
					next unless value.split(' ').length > 1
					s = ''
					value.split(' ').each {|v| s+="[contains(.,'#{v}')]"}
					lc = lc.gsub("[contains(.,'#{value}')]", s)
				end
				xpath << lc if flg and unusedparam.empty?
			end
		end

		# puts "sections got : " + section.to_s

		xpath
	end	
end

if __FILE__ == $0
XpathRepo::register_repo('C:\Automation\targaryen\targaryen\features\support\xpath_repo_local.txt')
include XpathRepo
puts buildxpath(:checkbox, :locator=>"asd asd")

end