# Usage:
# https://gist.github.com/btoone/099da5fb29149bec881636d8c501c4a3
# 
# Rails
# Step 1: write a gist with a file named __script__.rb
# Step 2: copy and paste the function def below into Rails console
# Step 3: run `eval_gist("the-gist-id-from-the-url")`
# Step 4: GOTO Step 3
# 
# Ruby
# Start an IRB session and load this file
# $ irb
# > load 'eval_gist.rb'
# > eval_gist("the-gist-id-from-the-url")
#
require 'uri' 
require 'net/http'
require 'json'

def eval_gist(gist_id)
  uri = URI("https://api.github.com/gists/#{gist_id}")
  req = Net::HTTP::Get.new(uri)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    resp = http.request(req)
    eval(JSON.parse(resp.body).dig("files", "__script__.rb", "content"))
  end
end
