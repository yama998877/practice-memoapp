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

def read_memo
  # ファイルがあるか確認して一覧表示する
  return [] unless Dir.exist?('./data')

  Dir.open('./data').each_child do |f|
    File.read("./data/#{f}").split
  end
end

get '/memos' do
  json_files = []
  @memo_path = Dir.glob('./data/*.json').sort_by { |f| File.mtime(f) }
  @memo_path.each do |file|
    json_files << File.read(file)
  end

  hashs = []
  json_files.each do |json|
    hashs << JSON.parse(json)
  end

  @titles = []
  hashs.each do |t|
    @titles << t['title']
  end
  @url_titles = @memo_path.zip(@titles) # URLとメモのタイトルを同じ配列に入れる
  erb :index
end

post '/memos' do
  memo_hash = {}
  @title = params['title']
  memo_hash['title'] = params['title']
  memo_hash['detail'] = params['detail']
  save_memo("./data/#{SecureRandom.uuid}.json", memo_hash.to_json)
  @names = read_memo
  @memo_path = Dir.children('./data/').sort_by { |f| File.mtime("./data/#{f}") }
  redirect '/memos'
end

patch '/memos' do
  new_memo_hash = {}
  new_memo_hash['title'] = params['title']
  new_memo_hash['detail'] = params['detail']
  update_file = params['json']
  changing_content = new_memo_hash.to_json
  save_memo("./data/#{update_file}", changing_content)

  redirect '/memos'
end

delete '/memos' do
  delete_file = params['json']
  delete_path = Pathname.new("./data/#{delete_file}")
  File.delete(delete_path) if delete_path.dirname.to_s == './data'
  redirect '/memos'
end

get '/memos/new' do
  erb :new
end

get '/memos/data/:file' do
  @json_file = params[:file]

  @memo_detail = JSON.parse(File.read("./data/#{@json_file}"))
  erb :detail
end

get '/memos/new/data/:file' do
  @file_name = params[:file]
  @memo = JSON.parse(File.read("./data/#{@file_name}"))
  erb :new_detail
end

not_found do
  '404 Not Found'
end
