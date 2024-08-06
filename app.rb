# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'securerandom'
require 'rack/utils'
require 'pathname'
require 'pg'
set :enviroment, :production

CONN = PG.connect(dbname: 'memoapp')

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def read_memos(memo_id = 'id,title,detail')
  if memo_id == 'id,title,detail'
    memos = {}
    CONN.exec("SELECT #{memo_id} FROM memos") do |result|
      result.each do |row|
        memo = { title: row['title'], detail: row['detail'] }
        uuid = row['id']
        memos[uuid] = memo
      end
    end
  else
    memos = 0
    CONN.exec_params('SELECT title,detail FROM memos WHERE id = $1', [memo_id]) do |result|
      result.each do |row|
        memo = { title: row['title'], detail: row['detail'] }
        memos = memo
      end
    end
  end
  memos
end

def write_memo(uuid, memo_title, memo_detail)
  if read_memos.key?(uuid) == false
    CONN.exec_params('INSERT INTO memos VALUES ($1,$2,$3,now())', [uuid, memo_title, memo_detail])
  else
    CONN.exec('UPDATE memos SET (title, detail, update_at) = ($1,$2, now()) WHERE id = $3', [memo_title, memo_detail, uuid])
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
  @memo_detail = read_memos(@uuid)
  erb :detail
end

patch '/memos/:id' do
  uuid = params[:id]
  write_memo(uuid, params[:title], params[:detail])
  redirect '/memos'
end

delete '/memos/:id' do
  uuid = params[:id]
  CONN.exec('DELETE FROM memos WHERE id = $1', [uuid])
  redirect '/memos'
end

get '/memos/:id/edit' do
  @uuid = params[:id]
  @memo = read_memos(@uuid)
  erb :edit
end

not_found do
  '404 Not Found'
end
