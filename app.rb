# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'rack/utils'
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
  # File.open(filename).close
end

def read_memo
  # ファイルがあるか確認して一覧表示する
  return [] unless Dir.exist?('./data')

  Dir.open('./data').each_child do |f|
    File.read("./data/#{f}").split
  end
end

get '/' do
  json_files = []
  @memo_path = Dir.glob('./data/*.json').sort_by { |f| File.mtime(f) }
  @memo_path.each do |file|
    p json_files << File.read(file)
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

post '/' do
  memo_hash = {}
  @title = params['title']
  @title << 'タイトルがありません' if @title.strip.empty?
  memo_hash['title'] = h(params['title'])
  memo_hash['detail'] = h(params['detail'])
  save_memo("./data/#{SecureRandom.uuid}.json", memo_hash.to_json)
  @names = read_memo
  @memo_path = Dir.children('./data/').sort_by { |f| File.mtime("./data/#{f}") }
  redirect '/'
  erb :index
end

patch '/' do
  new_memo_hash = {}
  params['title'] << 'タイトルがありません' if params['title'].strip.empty?
  new_memo_hash['title'] = h(params['title'])
  new_memo_hash['detail'] = h(params['detail'])
  update_file = params['json']
  changing_content = new_memo_hash.to_json
  save_memo("./data/#{update_file}", changing_content)

  redirect '/'
end

delete '/' do
  params
  delete_file = params['json']
  File.delete("./data/#{delete_file}")
  redirect '/'
end

get '/new' do
  erb :new
end

get '/data/:file' do
  @json_file = params[:file]

  @memo_detail = JSON.parse(File.read("./data/#{@json_file}"))
  @memo_detail['title']
  erb :detail
end

get '/new/data/:file' do
  @file_name = params[:file]
  @memo = JSON.parse(File.read("./data/#{@file_name}"))
  @memo['title']
  @memo['detail']
  erb :new_detail
end

not_found do
  '404 Not Found'
end
