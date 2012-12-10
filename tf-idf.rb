# encoding: utf-8
# Wp2TXTで抽出したWikipediaの全文データからTfIdfを算出．
# 自作バージョン

class TfIdf_Thomas
  # 各記事の単語タイプをカウント　出力：word_type.txt
  def type_counter(en_wiki)
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
    
      for_write = ""
      i = 0
      @ewiki_hash.each_pair {|title, body|
        for_write << title.gsub("\n", "")
        i = i + 1
        p i
        sentences = body.split("\s")
        tf = Hash::new() # TF格納用ハッシュ

        sentences.each {|word|
          striped = word.gsub(/[^A-Za-z]/, "") # 数字，記号除去
          #striped = word.gsub(/[0-9]+/, "") # 数字除去　これはなぜヒットしない？？
          #striped = word.gsub(/\W/, "") # 英数字以外除去　これも？？？？
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
    }
      
    p "書込み中"
      file = open("word_counted.txt", 'w')
      file.write for_write
      file.close 
  end

  def tf(word_counted)
    #　type_counter(en_wiki)で作成したファイル(word_counted.txt)をハッシュに格納
    @tf = Hash::new()
    # 各記事に対してTfを求める．
    open(word_counted, 'r') {|counted|
      while line = counted.gets
        line_splited = line.split("\t")
        title = line_splited[0]
        length = line_splited.length
        #記事内の全タイプ数計算
        i = 1
        total = 0.0
        line_splited[1..length].each {|e|
          if (i % 2) == 0 then
            total = total + e.to_f
          end
          i += 1
        }
        
        # TF(Term-Frequency)を格納したハッシュを作成
        i = 0
        type = Hash::new()
        line_splited[0..length].each {|e|
          if i % 2 != 0 then #eが数字のとき
            type[e] = line_splited[i+1].to_f / total
          end
          i += 1
        }
        @tf[title] = type
      end
    }
    @tf
  end
  
  def idf(word_counted)
    if @tf == nil then
      tf(word_counted)
    end
    # idf保存用ハッシュ作成
    @idf = @tf
    @tfidf = @tf
    
    # ハッシュidfを初期化
    @idf.each_value {|value|
      value.each_key {|key|
        value[key] = 0.0
      }
    }
    
    # 登場するドキュメント数を計算
    total = 0.0
    total = @tf.length # 総記事数
    @idf.each_value {|value|
      value.each_key {|word|
        @idf.each_value {|hash|
          if hash.member?(word) then
            value[word] = value[word] + 1 # DFをカウント
          end
        }
      }
    }
    
    # IDFを@idfに設定．
    @idf.each_value {|value|
      value.each_key {|word|
        value[word] = total / value[word].to_f #DF->IDF変換
        value[word] = Math.log2(value[word].to_f) # log2
      }
    }
    @idf
  end
  
end 

# Test
test = TfIdf_Thomas.new()
#test.tf("word_counted.txt.test.txt")
#test.type_counter("word_counted.txt.test.txt")
test.idf("word_counted.txt.test copy.txt")