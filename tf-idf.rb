# encoding: utf-8
# Wp2TXTで抽出したWikipediaの全文データからTfIdfを算出．
# 自作バージョン

class TfIdf_Thomas
  def initialize(en_wiki)
    @ewiki_hash = Hash::new()
    p "Preparating for Wikipedia in English"
  
    # 英語：奇数行（記事タイトル）をkey，偶数行（本文）をValueに設定    
    ewiki = open(en_wiki, 'r')  
    i = 0
    while line = ewiki.gets
      i = i + 1
      p i
      @ewiki_hash[line.gsub("\n", "")] = (ewiki.gets).gsub("\n", "")
    end
    ewiki.close 
  end
  
  # Tf(Term-frequency)を計算　出力：tf.txt
  def tf()
    for_write = ""
    i = 0
    @ewiki_hash.each_pair {|title, body|
      for_write << title.gsub("\n", "")
      i = i + 1
      p i
      sentences = body.split("\s")
      tf = Hash::new() # TF格納用ハッシュ

      sentences.each {|word|
        striped = word.gsub(/[^A-Za-z]/, "") # 数字除去
        #striped = word.gsub(/[0-9]+/, "") # 数字除去　これはなぜヒットしない？？
        #striped = word.gsub(/\W/, "") # 英数字以外除去
        if (striped != "") && tf.key?(striped) then
          tf[striped] += 1
        else
          tf[striped] = 1
        end
      }

      tf.each_pair{|key, value|  
        if key != "" then
          for_write << "\t" + key + "\t" + value.to_s
        end
      }
 
      for_write << "\n"
      
      i = i + 1
      if i % 1000 == 0 then
        p i
      end
    }
      
    p "書込み中"
      file = open("tf.txt", 'w')
      file.write for_write 
  end

  def idf
  end

  def tfidf
  end
end

# Test
test = TfIdf_Thomas.new("enarticle_selected.txt")
test.tf()