# spinel-todo

[Spinel](https://github.com/matz/spinel)（Matz による Ruby の AOT コンパイラ）で
ネイティブバイナリにコンパイルして使う、CLI の TODO アプリです。

`ARGV` でサブコマンド（`add` / `list` / `done`）を受け取り、`File.read` /
`File.write` で JSON ファイルに保存します。

## 特徴・制約メモ

Spinel は `require` / gem / 標準ライブラリ（`json` など）が使えない Ruby の
サブセットをコンパイルします。そのため本アプリでは:

- JSON のエンコード／デコードを**自前で実装**（`todo.rb` 内）
- TODO は型推論しやすいよう `Hash` ではなく `Todo` クラスで表現

しています。コードは通常の CRuby でもそのまま動くので、コンパイル前に
`ruby todo.rb ...` で動作確認できます。

## ビルド

Spinel のセットアップ（[本家 README](https://github.com/matz/spinel) 参照）:

```bash
git clone https://github.com/matz/spinel
cd spinel
make deps   # libprism を取得（初回のみ）
make        # コンパイラをビルド
sudo make install PREFIX=/usr/local   # 任意
```

本アプリをビルド:

```bash
spinel todo.rb -o todo   # ./todo が生成される
```

## 使い方

```bash
./todo add "牛乳を買う"     # TODO を追加
./todo add "PR をレビュー"
./todo list                 # 一覧表示
./todo done 1               # id=1 を完了にする
./todo                      # 使い方を表示
```

実行例:

```
$ ./todo add "牛乳を買う"
Added #1: 牛乳を買う
$ ./todo list
[ ] 1. 牛乳を買う
$ ./todo done 1
Marked #1 as done.
$ ./todo list
[x] 1. 牛乳を買う
```

保存先は既定で `todos.json`。環境変数 `SPINEL_TODO_FILE` で変更できます。

```bash
SPINEL_TODO_FILE=/path/to/mytodos.json ./todo list
```

保存される JSON の例（`todos.json`）:

```json
[
  {
    "id": 1,
    "text": "牛乳を買う",
    "done": true
  }
]
```

## CRuby で試す（コンパイル不要）

```bash
ruby todo.rb add "テスト"
ruby todo.rb list
```
