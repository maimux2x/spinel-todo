# spinel-todo

[Spinel](https://github.com/matz/spinel)（Matz による Ruby の AOT コンパイラ）で
ネイティブバイナリにコンパイルして使う、CLI の TODO アプリです。

`ARGV` でサブコマンド（`add` / `list` / `done`）を受け取り、`File.read` /
`File.write` で TSV（タブ区切り）ファイルに保存します。

## 特徴・制約メモ

Spinel は `require` / gem / 標準ライブラリ（`json` など）が使えない Ruby の
サブセットをコンパイルします。そのため本アプリでは:

- 永続化は外部依存なしで書ける **TSV 形式**（`String#split` だけで読み書き）
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

> `make install` せずに使う場合は、`spinel` をシンボリックリンクするのではなく
> **本体の `bin` ディレクトリを PATH に追加**してください。Spinel は実行ファイルの
> 隣の `lib/libspinel_rt.a` を参照するため、リンク経由だとライブラリを見失います。

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

保存先は既定で `todos.tsv`。環境変数 `SPINEL_TODO_FILE` で変更できます。

```bash
SPINEL_TODO_FILE=/path/to/mytodos.tsv ./todo list
```

保存される TSV の例（`todos.tsv`）。1 行 = `id <TAB> done(0/1) <TAB> text`:

```
1	0	牛乳を買う
2	1	PRをレビューする
```

テキスト中のタブ・改行は、1 行 1 レコードを保つため追加時に空白へ変換されます。

## CRuby で試す（コンパイル不要）

```bash
ruby todo.rb add "テスト"
ruby todo.rb list
```
