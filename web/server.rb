require 'rubygems'
require 'sinatra'
$:.unshift ".."
require 'writechain'

$store = WriteChain.create(:remote,{ 'storedir' => 'store-http' })

get '/shas' do
  shas = params[:shas].split('.')
  if $store.has_shas?(shas,true)
    "1"
  else
    "0"
  end
end

get '/read/:sha' do
  $store.read_sha(params[:sha])
end

post '/commit' do
  $store.write_commit(params[:sha],params[:message])
  "done"
end

post '/write/:sha' do
  $store.write(params[:data],params[:sha])
end

get '/sync' do
  $store.sync
  "1"
end
