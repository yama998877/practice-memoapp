# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'securerandom'
require 'rack/utils'
require 'pathname'
require 'pg'
set :enviroment, :production

conn = PG.connect(dbname: 'memoapp')

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def read_memos
  memos = {}
  conn.exec('SELECT id,title,detail FROM memos') do |result|
    result.each do |row|
      memo = { title: row['title'], detail: row['detail'] }
      uuid = row['id']
      memos[uuid] = memo
    end
  end
  memos
end

def read_memo(memo_id)
  memo = 0
  conn.exec_params('SELECT title,detail FROM memos WHERE id = $1 LIMIT 1', [memo_id]) do |result|
    result.each do |row|
      memo = { title: row['title'], detail: row['detail'] }
    end
  end
  memo
end

def write_memo(uuid, memo_title, memo_detail)
  if read_memos.key?(uuid) == false
    conn.exec_params('INSERT INTO memos VALUES ($1,$2,$3,now())', [uuid, memo_title, memo_detail])
  else
    conn.exec('UPDATE memos SET (title, detail, update_at) = ($1,$2, now()) WHERE id = $3', [memo_title, memo_detail, uuid])
  end
end

get '/memos' do
  erb :index
end

post '/memos' do
  write_memo(SecureRandom.uuid, params[:title], params[:detail])
  redirect '/memos'
end

get '/memos/new' do
  erb :new
end

get '/memos/:id' do
  @uuid = params[:id]
  @memo_detail = read_memo(@uuid)
  erb :detail
end

patch '/memos/:id' do
  uuid = params[:id]
  write_memo(uuid, params[:title], params[:detail])
  redirect '/memos'
end

delete '/memos/:id' do
  uuid = params[:id]
  conn.exec('DELETE FROM memos WHERE id = $1', [uuid])
  redirect '/memos'
end

get '/memos/:id/edit' do
  @uuid = params[:id]
  @memo = read_memo(@uuid)
  erb :edit
end

not_found do
  '404 Not Found'
end
