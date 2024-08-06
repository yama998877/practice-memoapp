# メモアプリ

メモを保存、更新、削除することができます。

## ダウンロード方法

```zsh
git clone https://github.com/yama998877/practice-memoapp
```

## 必要なGemのインストール

```ruby
  bundle install
```

## データベース作成方法

PostgreSQLをインストールしていない場合はインストールから始めて下さい。

```sql
psql -U ユーザ名 --ログイン
```

```sql
CREATE DATABASE memoapp;
```

```sql
\q --ログアウト
```

## テーブルの作成方法

```sql
psql -U ユーザ名 -d memoapp --作成したデータベースにログイン
```

```sql
CREATE TABLE memos ( 
  id UUID PRIMARY KEY,
  title VARCHAR(255),
  detail TEXT,
  update_at timestamp );
```

```sql
\q --ログアウト
```

## 起動方法

```ruby
bundle exec ruby app.rb
```

## 使い方、仕様

新規作成ボタンを押すとメモのタイトルと内容を入力をするフォームに移動します。

保存するタイトルと内容が決まったら保存ボタンを押します。（タイトルを入力しなかった場合、保存後のメモのタイトルは「タイトルがありません」に自動的になります。）

保存ボタンを押すとtopページに移動し、メモのタイトルが表示されます。

メモのタイトル、内容を変更、または削除したい場合はメモのタイトルをクリックします。(変更の保存は新規作成とほぼ同じです。)

削除は削除ボタンを押すと完了します。復元はできません。

変更したメモはページの一番下に移動します。
