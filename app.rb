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
  Dir.glob("#{DATA_DIR}/*.json").sort_by { |f| File.mtime(f) }.map do |f|
    memo = JSON.parse(File.read(f))
    memo[:uuid] = f.gsub(%r{./data/|.json}, '')
    memo
  end
end

def read_memo(memo_uuid)
  read_memos.detect { |memo_data| memo_data.value?(memo_uuid) }
end

def write_memo(filename, word)
  return if filename.include?('..')

  File.open(filename, 'w') do |file|
    file.puts(word)
  end
end

get '/memos' do
  @url_titles = read_memos.map { |memo_url| memo_url.values_at('title', :uuid) }
  erb :index
end

post '/memos' do
  new_memo = {
    'title' => params['title'],
    'detail' => params['detail']
  }
  write_memo("./data/#{SecureRandom.uuid}.json", new_memo.to_json)
  redirect '/memos'
end

get '/memos/new' do
  erb :new
end

get '/memos/:file' do
  @json_file = params[:file]
  @memo_detail = read_memo(@json_file)
  erb :detail
end

patch '/memos/:file' do
  edited_memo = {
    'title' => params['title'],
    'detail' => params['detail']
  }
  edited_file_name = "./data/#{params[:file]}.json"
  changing_content = edited_memo.to_json
  write_memo(edited_file_name, changing_content)

  redirect '/memos'
end

delete '/memos/:file' do
  uuid = params[:file]
  uuids = read_memos.map { |memo| memo[:uuid] }
  File.delete("./data/#{uuid}.json") if uuids.include?(uuid)
  redirect '/memos'
end

get '/memos/:file/edit' do
  @file_name = params[:file]
  @memo = JSON.parse(File.read("./data/#{@file_name}.json"))
  erb :edit
end

not_found do
  '404 Not Found'
end
