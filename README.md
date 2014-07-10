# sinatra-ace

## Summary

Sinatra Extension for ACE (AWS Compatible Environment).

## Features

* Friendly DSL (action, version, path)
* Specialized Helpers

## Sample

Run this app:

	require 'sinatra'
	require 'sinatra/ace.rb'
	require 'sequel'
	
	DB = Sequel.sqlite
	DB.create_table :dreams do
		primary_key :id
		String :name
		String :description
	end
	Dreams = DB[:dreams]
	
	action 'CreateDream' do
		dream_id = Dreams.insert(:name => params['DreamName'])
		response_xml do |xml|
			xml.Dream do
				xml.DreamId dream_id
				xml.DreamName params['DreamName']
			end
		end
	end
	
	version '2014-07-11' do
		action 'CreateDream' do
			dream_id = Dreams.insert(:name => params['DreamName'], :description => params['Description'])
			response_xml do |xml|
				xml.Dream do
					xml.DreamId dream_id
					xml.DreamName params['DreamName']
					xml.Description params['Description']
				end
			end
		end
	end
	
	path '/:DreamId' do
		action 'GetDreamDetail' do
			dream = Dreams[:id => params['DreamId']]
			response_xml do |xml|
				xml.Dream do
					xml.DreamId dream[:id]
					xml.DreamName dream[:name]
					xml.Description dream[:description]
				end
			end
		end
	end
	
	dispatch!

And you can get:

	$ curl "http://localhost:4567/?Action=CreateDream&DreamName=Nightmare"
	<?xml version="1.0" encoding="UTF-8"?>
	<CreateDreamResponse>
	  <CreateDreamResult>
	    <Dream>
	      <DreamId>2</DreamId>
	      <DreamName>Nightmare</DreamName>
	    </Dream>
	  </CreateDreamResult>
	  <ResponseMetadata>
	    <RequestId>6c68b49d-239a-4777-b82f-a21151e9be42</RequestId>
	  </ResponseMetadata>
	</CreateDreamResponse>
	$ curl "http://localhost:4567/?Action=CreateDream&DreamName=DayDream&Description=just+lazed+in+the+pool&Version=2014-07-11"
	<?xml version="1.0" encoding="UTF-8"?>
	<CreateDreamResponse>
	  <CreateDreamResult>
	    <Dream>
	      <DreamId>3</DreamId>
	      <DreamName>DayDream</DreamName>
	      <Description>just lazed in the pool</Description>
	    </Dream>
	  </CreateDreamResult>
	  <ResponseMetadata>
	    <RequestId>2b875603-f685-4872-a316-7e2ddd4c356d</RequestId>
	  </ResponseMetadata>
	</CreateDreamResponse>
	$ curl "http://localhost:4567/3?Action=GetDreamDetail"
	<?xml version="1.0" encoding="UTF-8"?>
	<GetDreamDetailResponse>
	  <GetDreamDetailResult>
	    <Dream>
	      <DreamId>3</DreamId>
	      <DreamName>DayDream</DreamName>
	      <Description>just lazed in the pool</Description>
	    </Dream>
	  </GetDreamDetailResult>
	  <ResponseMetadata>
	    <RequestId>225697f4-2577-432b-aa78-c6f18cec7c05</RequestId>
	  </ResponseMetadata>
	</GetDreamDetailResponse>
