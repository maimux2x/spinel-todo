# todo.rb -- Spinel (Ruby AOT compiler) で動く CLI TODO アプリ
#
# Spinel は require / gem / 標準ライブラリ（json など）が使えないため、
# 永続化は外部依存なしで書ける TSV（タブ区切り）形式で行う。
# 1 行 = "id <TAB> done(0/1) <TAB> text"。読み書きは String#split だけで済む。
# Todo は型推論しやすいよう Hash ではなくクラスで表現する。
#
# 使い方:
#   ./todo add <text>   TODO を追加
#   ./todo list         一覧表示
#   ./todo done <id>    完了にする
#
# データは TSV ファイル（既定: todos.tsv）に File.read / File.write で保存する。

# ---- データモデル -----------------------------------------------------------

class Todo
  attr_accessor :id, :text, :done

  def initialize(id, text, done)
    @id = id
    @text = text
    @done = done
  end
end

# ---- 永続化（TSV） ----------------------------------------------------------

def load_todos(path)
  todos = []
  src = ""
  begin
    src = File.read(path)
  rescue
    return todos
  end
  src.split("\n").each do |line|
    next if line == ""
    parts = line.split("\t")
    next if parts.length < 3
    id = parts[0].to_i
    done = parts[1] == "1"
    text = parts[2]
    todos << Todo.new(id, text, done)
  end
  todos
end

def save_todos(path, todos)
  s = ""
  todos.each do |t|
    flag = t.done ? "1" : "0"
    s << t.id.to_s << "\t" << flag << "\t" << t.text << "\n"
  end
  File.write(path, s)
end

# テキストにタブ・改行が混ざると 1 行 1 レコードが壊れるので追加時に除去する。
def sanitize(text)
  text.gsub("\t", " ").gsub("\n", " ").gsub("\r", " ")
end

# ---- サブコマンド -----------------------------------------------------------

def cmd_add(todos, text)
  next_id = 1
  todos.each do |t|
    next_id = t.id + 1 if t.id >= next_id
  end
  clean = sanitize(text)
  todos << Todo.new(next_id, clean, false)
  puts "Added ##{next_id}: #{clean}"
end

def cmd_list(todos)
  if todos.length == 0
    puts "No todos yet."
    return
  end
  todos.each do |t|
    mark = t.done ? "x" : " "
    puts "[#{mark}] #{t.id}. #{t.text}"
  end
end

def cmd_done(todos, id)
  found = false
  todos.each do |t|
    if t.id == id
      t.done = true
      found = true
    end
  end
  if found
    puts "Marked ##{id} as done."
  else
    puts "No todo with id #{id}."
  end
end

def usage
  puts "TODO app (Spinel)"
  puts "usage:"
  puts "  todo add <text>   add a todo"
  puts "  todo list         list todos"
  puts "  todo done <id>    mark a todo as done"
end

# ---- エントリポイント -------------------------------------------------------

def main
  path = ENV["SPINEL_TODO_FILE"] || "todos.tsv"
  cmd = ARGV[0]
  todos = load_todos(path)

  if cmd == "add"
    if ARGV.length < 2
      puts "usage: todo add <text>"
      return
    end
    cmd_add(todos, ARGV[1])
    save_todos(path, todos)
  elsif cmd == "list"
    cmd_list(todos)
  elsif cmd == "done"
    if ARGV.length < 2
      puts "usage: todo done <id>"
      return
    end
    cmd_done(todos, ARGV[1].to_i)
    save_todos(path, todos)
  else
    usage
  end
end

main
