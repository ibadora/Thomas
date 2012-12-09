class Processing
  def initialize(en, jp, article_list, edr)
    
    p "Starting..."
    
    @jwiki_hash = Hash::new()
    @ewiki_hash = Hash::new()
    @edr_hash = Hash::new()
    @article_title = Hash::new()
   
    p "Preparating for Wikipedia in Japanese"
    
    # 日本語：奇数行（記事タイトル）をkey，偶数行（本文）をValueに設定
    jwiki = open(jp, 'r')
    while line = jwiki.gets
      @jwiki_hash[line.gsub("\n", "")] = (jwiki.gets).gsub("\n", "")
    end
    jwiki.close
=begin
    p "Preparating for Wikipedia in English"

    # 英語：奇数行（記事タイトル）をkey，偶数行（本文）をValueに設定    
    ewiki = open(en, 'r')  
    while line = ewiki.gets
      @ewiki_hash[line.gsub("\n", "")] = (ewiki.gets).gsub("\n", "")
    end
    @ewiki.close
=end
    p "Preparating for Article Title List."
    list = open(article_list, 'r')
    while line = list.gets
      title = line.split("\t")
      en_title = title[1].gsub("\n", "")
      jp_title = title[0]
      @article_title[en_title] = jp_title
    end

    p "Preparating for EDR Dictionary."
    
    # EDRから抽出した英単語をKey，日本語訳をValueに設定．
    dic = open(edr, 'r')  
    while line = dic.gets
      splited = line.split("\t")
      #訳語が複数ある場合
      length = splited.length
      tail = splited[length - 1].gsub("\n", "") #配列末尾の改行を削除
      splited[(splited.size) -1] = tail
      
      # すでに同じ名前の名詞がハッシュ内に存在すれば結合．なければKeyを作成．
      if @edr_hash.key?(splited[0]) then
        @edr_hash[splited[0]] = @edr_hash[splited[0]] | splited.slice(2..((splited.size) - 1)) 
      else
      @edr_hash[splited[0]] = splited.slice(2..((splited.size) - 1)) #ハッシュに値を設定
    end
    end
    dic.close 
   
    p "Preparation done."
   
  end
  
  def weight_word(article_en, weight_article, word)
    # 対応する日本語版記事
    if @article_title.key?(article_en) then
      jp_article = @article_title[article_en]
      p jp_article
    else
      p "The article in Japanese not found."
    end
    
    #　曖昧性解消する単語の訳語候補
    if @edr_hash.key?(word) then
      p "the word found"
      jp_terms = @edr_hash[word]
      jp_terms.each {|term| p term}
    else
      p "the word not found"
    end
    
    #　登場回数カウント
    count = Hash::new()
    result = Hash::new()
    article_body = @jwiki_hash["[[#{jp_article}]]"]
    jp_terms.each {|word|
      count[word] = article_body.scan(word).size
    }
    count.each_pair {|key, value| print key, ":\t", value, "\n"}
    
    # 登場確率計算
    total = 0.0
    count.each_value {|value| total += value}
    count.each_pair {|key, value| 
      count[key] = (value / total) * weight_article
    }
    count.each_pair {|key, value| print key, ":\t", value, "\n" }
    
  end

  def weight_article()
  end
end

# Test
test = Processing.new("enarticle_selected.txt", "jparticle_selected_for_test.txt", "union.txt", "EDR_nouns.txt")
test.weight_word("Ayesha Takia", 1, "actress")