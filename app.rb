# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'securerandom'
require 'rack/utils'
require 'pg'
set :enviroment, :production

conn = PG.connect(dbname: 'memoapp')

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def read_memos(conn)
  memos = {}
  conn.exec('SELECT id,title,detail FROM memos') do |result|
    result.each do |row|
      memos[row['id']] = { title: row['title'], detail: row['detail'] }
    end
  end
  memos
end

def read_memo(conn, memo_id)
  memo = nil
  conn.exec_params('SELECT title,detail FROM memos WHERE id = $1 LIMIT 1', [memo_id]) do |result|
    result.each do |row|
      memo = { title: row['title'], detail: row['detail'] }
    end
  end
  memo
end

def create_memo(conn, uuid, memo_title, memo_detail)
  conn.exec_params('INSERT INTO memos VALUES ($1,$2,$3,now())', [uuid, memo_title, memo_detail]) unless read_memos(conn).key?(uuid)
end

def update_memo(conn, uuid, memo_title, memo_detail)
  conn.exec('UPDATE memos SET (title, detail, update_at) = ($1,$2, now()) WHERE id = $3', [memo_title, memo_detail, uuid])
end

get '/memos' do
  @memos = read_memos(conn)
  erb :index
end

post '/memos' do
  create_memo(conn, SecureRandom.uuid, params[:title], params[:detail])
  redirect '/memos'
end

get '/memos/new' do
  erb :new
end

get '/memos/:id' do
  @uuid = params[:id]
  @memo_detail = read_memo(conn, @uuid)
  erb :detail
end

patch '/memos/:id' do
  uuid = params[:id]
  update_memo(conn, uuid, params[:title], params[:detail])
  redirect '/memos'
end

delete '/memos/:id' do
  uuid = params[:id]
  conn.exec('DELETE FROM memos WHERE id = $1', [uuid])
  redirect '/memos'
end

get '/memos/:id/edit' do
  @uuid = params[:id]
  @memo = read_memo(conn, @uuid)
  erb :edit
end

not_found do
  '404 Not Found'
end
