# encoding: utf-8
# EDR電子化辞書から名詞だけを抽出する．
# <出力>::=<英単語> <品詞タグ> <日本語訳>
# <日本語訳> ::= <日本語訳>|空
require "kconv"

def extract_noun(line)
  result = ""
  splited = line.split(/\t/)
  if splited[2] =~ /EN\d/ then
  
    splited[1].gsub!("\"", "") # ２単語以上で構成される名詞には"がつくので削除．
  
    # Put each Japanese term into array(splited_jjp)
    splited_jp = splited[8].split(/^0\||\/\/0\||\|x/)
    splited_jp.delete("") #空の要素は削除
    #日本語訳にカッコ "()" "<>" 付きの追加情報がついている場合に対応．"〜"も削除
    splited_jp.each {|element| 
      element.gsub!(/\"\(.+?\)|\"/, "")
      element.gsub!(/<<.+>>/, "")
      element.gsub!("〜", "")
    }
   
    # result
    result << splited[1] #-> Term in English
    result << "\t" + splited[2]
    splited_jp.each {|element| result << "\t" + element} #-> Terms in Japanese
    result << "\n"
  end
  result
end

lines = 0
for_write = ""

# for_writeに名詞と語義を格納
open("./Resources/EDR/EJB.DIC.UTF8") {|file|
  while l = file.gets
    for_write << extract_noun(l)
  end
}

File.write("nouns.txt", for_write)