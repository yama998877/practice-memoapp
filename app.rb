# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'rack/utils'
require 'pathname'
set :enviroment, :production

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

DATA_DIR = File.join(File.dirname(__FILE__), 'data')

def read_memos
  memos = {}
  Dir.glob("#{DATA_DIR}/*.json").sort_by { |f| File.mtime(f) }.map do |f|
    memo = JSON.parse(File.read(f), symbolize_names: true)
    uuid = File.basename(f, '.json')
    memos[uuid] = memo
  end
  memos
end

def read_memo(memo_uuid)
  read_memos[memo_uuid]
end

def write_memo(filename, word)
  File.open(filename, 'w') do |file|
    file.puts(word)
  end
end

get '/memos' do
  erb :index
end

post '/memos' do
  new_memo = {
    title: params[:title],
    detail: params[:detail]
  }
  write_memo("./data/#{SecureRandom.uuid}.json", new_memo.to_json)
  redirect '/memos'
end

get '/memos/new' do
  erb :new
end

get '/memos/:id' do
  @json_file = params[:id]
  @memo_detail = read_memo(@json_file)
  erb :detail
end

patch '/memos/:id' do
  uuid = params[:id]
  edited_memo = {
    title: params[:title],
    detail: params[:detail]
  }
  edited_file_name = "./data/#{uuid}.json"
  changing_content = edited_memo.to_json
  write_memo(edited_file_name, changing_content) unless read_memo(uuid).nil?
  redirect '/memos'
end

delete '/memos/:id' do
  uuid = params[:id]
  File.delete("./data/#{uuid}.json") unless read_memo(uuid).nil?
  redirect '/memos'
end

get '/memos/:id/edit' do
  @file_name = params[:id]
  @memo = read_memo(@file_name)
  erb :edit
end

not_found do
  '404 Not Found'
end
