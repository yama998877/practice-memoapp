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

def save_memo(filename, word)
  File.open(filename, 'w') do |file|
    file.puts(word)
  end
end

def read_memos(memo_files)
  ascending_order_files = Dir.glob('./data/*.json').sort_by { |f| File.mtime(f) }

  ascending_order_files.each do |file|
    memo_files << File.read(file)
  end
end

get '/memos' do
  json_files = []
  read_memos(json_files)

  memos_title_detail = json_files.map { |json_file| JSON.parse(json_file) }
  memo_titles = memos_title_detail.map { |memo| memo['title'] }
  @url_titles = read_memos(json_files).zip(memo_titles) # URLとメモのタイトルを同じ配列に入れる
  erb :index
end

post '/memos' do
  new_memo = {
    'title' => params['title'],
    'detail' => params['detail']
  }
  save_memo("./data/#{SecureRandom.uuid}.json", new_memo.to_json)
  redirect '/memos'
end

get '/memos/new' do
  erb :new
end

get '/memos/:file' do
  @json_file = params[:file]
  exisiting_json_files = Dir.glob('./data/*.json').map { |filename| File.basename(filename) }
  @memo_detail = JSON.parse(File.read("./data/#{@json_file}")) if exisiting_json_files.include?(@json_file)
  erb :detail
end

patch '/memos/:file' do
  edited_memo = {
    'title' => params['title'],
    'detail' => params['detail']
  }
  edited_file_name = "./data/#{params['memo_id']}"
  changing_content = edited_memo.to_json
  save_memo(edited_file_name, changing_content)

  redirect '/memos'
end

delete '/memos/:file' do
  uuid = params['memo_json_file'].delete('.json')
  uuids = Dir.glob('./data/*.json').map { |filename| File.basename(filename, '.json') }
  File.delete("./data/#{uuid}.json") if uuids.include?(uuid)
  redirect '/memos'
end

get '/memos/:file/edit' do
  @file_name = params[:file]
  @memo = JSON.parse(File.read("./data/#{@file_name}"))
  erb :edit
end

not_found do
  '404 Not Found'
end
