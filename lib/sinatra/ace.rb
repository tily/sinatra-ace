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

			def response_xml(&block)
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
			def dispatch!
				@paths.each do |path, opts|
					[:get, :post].each do |x|
						send(x, path) do
							opt = opts.select {|opt| opt[:action] == params['Action'] }
							instance_eval(&opt[:block]) if opt
						end
					end
				end
			end

			def action(action, path='/', &block)
				@paths ||= Hash.new {|h, k| h[k] = [] }
				@paths[path] << {action: action, block: block}
			end
		end

	end
end

# register for classic style
Sinatra.register Sinatra::Ace::Dsl
Sinatra.helpers Sinatra::Ace::Helper
