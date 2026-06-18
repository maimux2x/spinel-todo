# todo.rb -- Spinel (Ruby AOT compiler) で動く CLI TODO アプリ
#
# Spinel は require / gem / 標準ライブラリ（json など）が使えないため、
# JSON の読み書きは自前で実装している。Todo は型推論しやすいよう
# Hash ではなくクラスで表現する。
#
# 使い方:
#   ./todo add <text>   TODO を追加
#   ./todo list         一覧表示
#   ./todo done <id>    完了にする
#
# データは JSON ファイル（既定: todos.json）に File.read / File.write で保存する。

# ---- データモデル -----------------------------------------------------------

class Todo
  attr_accessor :id, :text, :done

  def initialize(id, text, done)
    @id = id
    @text = text
    @done = done
  end
end

# ---- JSON 出力（自前実装） --------------------------------------------------

def json_escape(s)
  out = ""
  i = 0
  n = s.length
  while i < n
    c = s[i]
    if c == "\\"
      out << "\\\\"
    elsif c == "\""
      out << "\\\""
    elsif c == "\n"
      out << "\\n"
    elsif c == "\t"
      out << "\\t"
    elsif c == "\r"
      out << "\\r"
    else
      out << c
    end
    i += 1
  end
  out
end

def todos_to_json(todos)
  s = "[\n"
  i = 0
  n = todos.length
  while i < n
    t = todos[i]
    s << "  {\n"
    s << "    \"id\": "
    s << t.id.to_s
    s << ",\n"
    s << "    \"text\": \""
    s << json_escape(t.text)
    s << "\",\n"
    s << "    \"done\": "
    if t.done
      s << "true"
    else
      s << "false"
    end
    s << "\n  }"
    if i < n - 1
      s << ","
    end
    s << "\n"
    i += 1
  end
  s << "]\n"
  s
end

# ---- JSON 入力（自前実装） --------------------------------------------------
#
# 自分で書き出すスキーマ（id / text / done を持つオブジェクトの配列）に
# 特化した最小パーサ。状態は @pos に持ち、型が混ざらないよう値の型ごとに
# メソッドを分けている。

class JsonParser
  def initialize(src)
    @src = src
    @pos = 0
    @len = src.length
  end

  def cur
    return "" if @pos >= @len
    @src[@pos]
  end

  def skip_ws
    while @pos < @len
      c = @src[@pos]
      if c == " " || c == "\n" || c == "\t" || c == "\r"
        @pos += 1
      else
        break
      end
    end
  end

  def parse_string
    s = ""
    skip_ws
    return s if cur != "\""
    @pos += 1 # 開きクォート
    while @pos < @len
      c = @src[@pos]
      if c == "\""
        @pos += 1
        break
      elsif c == "\\"
        @pos += 1
        e = @src[@pos]
        if e == "n"
          s << "\n"
        elsif e == "t"
          s << "\t"
        elsif e == "r"
          s << "\r"
        elsif e == "\""
          s << "\""
        elsif e == "\\"
          s << "\\"
        else
          s << e
        end
        @pos += 1
      else
        s << c
        @pos += 1
      end
    end
    s
  end

  def parse_number
    skip_ws
    start = @pos
    @pos += 1 if cur == "-"
    while @pos < @len
      c = @src[@pos]
      if c >= "0" && c <= "9"
        @pos += 1
      else
        break
      end
    end
    @src[start, @pos - start].to_i
  end

  def parse_bool
    skip_ws
    if cur == "t"
      @pos += 4 # "true"
      return true
    end
    @pos += 5 # "false"
    false
  end

  def skip_value
    skip_ws
    c = cur
    if c == "\""
      parse_string
    elsif c == "t"
      @pos += 4
    elsif c == "f"
      @pos += 5
    else
      parse_number
    end
  end

  def parse_object
    id = 0
    text = ""
    done = false
    skip_ws
    @pos += 1 if cur == "{"
    skip_ws
    while @pos < @len && cur != "}"
      key = parse_string
      skip_ws
      @pos += 1 if cur == ":"
      skip_ws
      if key == "id"
        id = parse_number
      elsif key == "text"
        text = parse_string
      elsif key == "done"
        done = parse_bool
      else
        skip_value
      end
      skip_ws
      if cur == ","
        @pos += 1
        skip_ws
      end
    end
    @pos += 1 if cur == "}"
    Todo.new(id, text, done)
  end

  def parse
    todos = []
    skip_ws
    return todos if @pos >= @len
    @pos += 1 if cur == "["
    skip_ws
    while @pos < @len && cur != "]"
      todos << parse_object
      skip_ws
      if cur == ","
        @pos += 1
        skip_ws
      end
    end
    todos
  end
end

# ---- 永続化 -----------------------------------------------------------------

def load_todos(path)
  src = ""
  begin
    src = File.read(path)
  rescue
    return []
  end
  JsonParser.new(src).parse
end

def save_todos(path, todos)
  File.write(path, todos_to_json(todos))
end

# ---- サブコマンド -----------------------------------------------------------

def cmd_add(todos, text)
  next_id = 1
  todos.each do |t|
    next_id = t.id + 1 if t.id >= next_id
  end
  todos << Todo.new(next_id, text, false)
  puts "Added ##{next_id}: #{text}"
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
  path = ENV["SPINEL_TODO_FILE"] || "todos.json"
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
