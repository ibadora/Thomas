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
      
    # 出力：word_type.txtの作成
      file = open("word_counted.txt", 'w')
      file.write for_write
      file.close 
  end

  def tf(word_counted)
    #　type_counter(en_wiki)で作成したファイル(word_counted.txt)をハッシュに格納
    tf = Hash::new()
    # 各記事に対してTfを求める．
    open(word_counted, 'r') do |counted|
      while line = counted.gets
        line_splited = line.split("\t")
        title = line_splited[0]
        length = line_splited.length
        #記事内の全タイプ数計算
        i = 1
        total = 0.0
        line_splited[1..length].each do |e|
          if (i % 2) == 0 then
            total = total + e.to_f
          end
          i += 1
        end
        
        # TF(Term-Frequency)を格納したハッシュを作成
        i = 0
        type = Hash::new()
        line_splited[0..length].each do |e|
          if i % 2 != 0 then #eが数字のとき
            type[e] = line_splited[i+1].to_f / total
          end
          i += 1
        end
        tf[title] = type
      end
    end
    tf
  end
  
  def idf(word_counted)
      idf = tf(word_counted)
    # idf保存用ハッシュ作成
    
    # ハッシュidfを初期化
    idf.each_value do |value|
      value.each_key do |key|
        value[key] = 0.0
      end
    end
    
    # 登場するドキュメント数を計算
    total = 0
    total = idf.length # 総記事数
    idf.each_value do |value|
      value.each_key do|word|
        idf.each_value do|hash|
          if hash.member?(word) then
            value[word] = value[word] + 1 # DFをカウント
          end
        end
      end
    end
    
    # IDFをidfに設定．
    idf.each_value do |value|
      value.each_key do|word|
        value[word] = total / value[word] #DF->IDF変換
        value[word] = Math.log2(value[word].to_f) # log2
      end
    end
    idf
  end
  
  # TfIdfをtfidf.data.txtに書き出し
  def tfidf(word_counted)
      tf_hash = tf(word_counted).clone
      idf_hash = idf(word_counted).clone
    
    p tf_hash
    p idf_hash
    
    # TfIdf格納用ハッシュ作成．深いコピー
    tfidf = Marshal.load(Marshal.dump(tf_hash))
    
    
    # ハッシュtfidfを初期化
    tfidf.each_value do |value|
      value.each_key do |key|
        value[key] = 0.0
      end
    end
    # Tf-Idfを計算
    tf_hash.each_pair do |article, hash_tf|
      hash_tf.each_key do |key, value_tf|
        tfidf[article][key] = hash_tf[key] * idf_hash[article][key]
      end
    end
    
    # ファイル書き込み準備
    for_write = ""
    i = 0
    tfidf.each_pair do |title, hash|
      p title
      for_write << title.gsub("\n", "")
      hash.each_pair do |key, value|
        for_write << "\t" + key + "\t" + value.to_s
      end
      for_write << "\n"
    end
       
  # 出力：word_type.txtの作成
    file = open("tfidf.data.txt", 'w')
    file.write for_write
    file.close 

  end
  
end 

# 使い方::=はじめにtype_counter()で処理用ファイルを作る
# できたら以下のようにtest.tfidf()を実行
test = TfIdf_Thomas.new()
#test.type_counter("path_to_english_wikipedia_generated_by_wp2txt")
#test.tf("word_counted.txt.test.txt")
test.tfidf("word_counted.txt.test.txt")