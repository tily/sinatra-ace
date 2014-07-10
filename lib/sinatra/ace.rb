require 'sinatra/base'

module Sinatra
	module Ace
		module Helper
			def request_id
				@request_id ||= SecureRandom.uuid
			end

			def requested_action
				params['Action']
			end

			def requested_version
				params['Version']
			end

			def attributes
				@attributes ||= (1..10).to_a.inject({}) do |attributes, i|
					if (name = params["Attribute.#{i.to_s}.Name"]) && (value = params["Attribute.#{i.to_s}.Value"])
						attributes[name] = value
					end
					attributes
				end
			end

			def response_xml
				builder do |xml|
					xml.instruct!
					xml.tag!("#{requested_action}Response") do
						xml.tag!("#{requested_action}Result") do
							yield(xml)
						end
						xml.ResponseMetadata { xml.RequestId request_id }
					end
				end
			end

			def error_xml(type, code, message)
				builder do |xml|
					xml.instruct!
					xml.ErrorResponse do
						xml.Error do
							xml.Type type
							xml.Code code
							xml.Message message
						end
						xml.ResponseMetadata { xml.RequestId request_id }
					end
				end
			end
		end


		module Dsl
			attr_reader :actions

			def action(action, options={}, &block)
				@actions ||= Array.new
				raise 'Error: path was specified at two places' if options[:path] && @path
				raise 'Error: version was specified at two places' if options[:version] && @version
				path = @path || options[:path] || '/'
				version = @version || options[:version] || nil
				@actions << {action: action, block: block, path: path, version: version}
			end

			def version(version)
				original_version = @version
				@version = version
				yield
				@version = original_version
			end

			def path(path)
				original_path = @path
				@path = path
				yield
				@path = original_path
			end

			def dispatch!
				paths = @actions.map {|action| action[:path] }.uniq
				paths.each do |path|
					[:get, :post].each do |x|
						send(x, path) do
							actions = self.class.actions.select do |action|
								action[:path] == env['sinatra.route'].split(' ').last &&
								action[:action] == requested_action &&
								[requested_version, nil].include?(action[:version])
							end
							raise 'Error: action was not found' if actions.empty? # TODO: raise custom error
							action = actions.find {|action| action[:version] == requested_version } || actions.first
							logger.info "calling action: #{action}"
							instance_eval(&action[:block])
						end
					end
				end
			end
		end

	end
end

# register for classic style
Sinatra.register Sinatra::Ace::Dsl
Sinatra.helpers Sinatra::Ace::Helper
