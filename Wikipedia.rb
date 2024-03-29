# encoding: utf-8
# Wikipedia.rb deals with Wikipedia dumps(XML) in English/Japanese and
# text files generated by WP2TXT.
##############################################################################
# Author: Thomas ISHIGAKI
# Developement started on 3/12/2012
##############################################################################
require 'engtagger' #POS Tagger
require 'tf_idf'
require 'stemmer' #Porter Algorithm

class EngWiki

  def initialize()
    #@ewiki_files = ["Resources/en_articles/enwiki-latest-pages-articles.xml-001.txt"]
    dir = "Resources/en_articles/"
    @ewiki_files = Dir::entries(dir).grep(/\.(txt)$/) {|f| dir + f}
    @ewiki_dump = "Resources/enwiki-latest-pages-articles.xml"
    @ewiki_files_stemmed = ["ewiki_stemmed.txt"]
    @article_name = ""
    @sentence_stemmed = ""
  end

  # WP2TXTで抽出した記事タイトルと見出し，本文のうち，本文のみをステミングする．
  # ewiki_stemmed.txtというファイルが書き出される．
  def stemming()
    @ewiki_files.each {|wiki_file|
      open(wiki_file, 'r') { |wiki|
        @i = 0
        while line = wiki.gets
          if line =~ /\[\[.+\]\]/ then #記事タイトルの行を読み込んだ場合
            if @i == 0 then 
              file = open("ewiki_stemmed.txt", "w")
              @article_name = line
              @i = 1
            else
              if (@article_name.split("\s").size < 10) && (@sentence_stemmed != "") then
                p "writing\s\s" + @article_name
                file.write @article_name
                @sentence_stemmed << "\n"
                file.write @sentence_stemmed
                @article_name = line
                @sentence_stemmed = "" 
              else
                @article_name = line
                @sentence_stemmed = "" 
              end
            end
            @sentence_stemmed = ""   
          elsif line =~ /^\=\=\=/  then #H3見出し付き
            #Do nothing
          elsif line =~ /^\=\=/  then #H2見出し付き
            #Do nothing
          else #本文
            sentence = line.gsub(/\/|\)|\(|\,|\"/, "")
            sentence = line.split("\s")
            sentence.each {|word| @sentence_stemmed << "\s" + word.stem_porter} 
          end
        end 
      }
    }
  end
  
  # 本文内の各単語を要素とする配列を格納した配列を返す．
  def get_vector()
    vector = []
    @ewiki_files_stemmed.each {|stemmed_file|
      open(stemmed_file, 'r') { |wiki|
        while line = wiki.gets
          if line =~ /\[\[.+\]\]/ then #記事タイトルの行を読み込んだ場合
            #Do nothing
          else #本文
            vector << line.split("\s")
          end
        end 
      }
    }
    vector
  end
  
  # tfidf情報を格納したハッシュを要素とする配列が返る．例えば，
  # [{'b' => 0.0602, 'a' => etc...}, {etc...}]
  def get_tfidf()
    test = get_vector()
    tfidf = TfIdf.new(test)
    result = tfidf.tf_idf
    result
  end
  
  # ダンプから記事タイトルとそれに対応する日本語エントリーを抽出
  # eng_to_jp.txtというファイルを出力
  # 使うWikipediaダンプは上の@ewiki_dumpに設定．
  def extract_translation()
    file = open("eng_to_jp.txt", "a") #追記モードでオープン
    open(@ewiki_dump, 'r') {|wiki|
      jp_title = ""
      en_title = ""
      joined_title = ""
      while line = wiki.gets
        if line =~ /<title>(.+)<\/title>/ then
          en_title = $+
        elsif line =~ /^\[\[ja:(.+)\]\]/ then #対訳ページが存在する場合
          jp_title = $+
          if en_title =~ /\((disambiguation)|(List of|Category)|(Template)|(File)|(Wikipedia:)/ then
            # Do nothing
          elsif jp_title =~ /\((曖昧さ)|(List of)|(Category)|(Template)|(^ファイル)/ then
              # Do nothing

          else
            joined_title = jp_title + "\t" + en_title + "\n"
            file.write joined_title
          end
        end
      end
    }
  end
  
  # WP2TXTで抽出した記事から日本語版が存在しない記事を取り除く
  def remove_unconnected_article()
    union_list = []
    jp_en = []
    for_write = ""
    article_name = ""
    article_name_check = ""
    counter = 0
    i = 0
    
    # 英語版がある日本語版記事を配列union_listに格納
    open("union.txt", "r") { |u|
      while line = u.gets
        jp_en = line.split("\t")
        union_list << jp_en[1]  
      end
    }
    
    union_list.each {|union| p union} 
    
    p "-----------------------------------------------------------"
    
    @ewiki_files.each {|wiki_file|
      open(wiki_file, 'r') { |wiki|
        while line = wiki.gets
          if line =~ /^\[\[(.+)\]\]/ then #記事タイトルの行を読み込んだ場合
            if i == 0 then #最初のタイトルの読み込み
              file = open("enarticle_selected.txt", "a")
              article_name = line
              i = 1
            else # ２回目以降
              # if文の条件    
              # 10単語以上のタイトルは除外．本文を持たない記事は除外．
              # 英語記事を持たない記事は除外
              artist_name_check = article_name.gsub(/\[\[|\]\]/, "")
              p artist_name_check + "\sChecking"
              if (for_write != "") && (union_list.index(artist_name_check) != nil) then
                p "Writing\s\s" + article_name
                file.write article_name
                for_write << "\n"
                counter = counter + 1
                p counter
                file.write for_write
                article_name = line
                for_write = "" 
              else
                article_name = line
                for_write = "" 
              end
            end
            for_write = ""   
          elsif line =~ /^\=\=\=/  then #H3見出し付き
            #Do nothing
          elsif line =~ /^\=\=/  then #H2見出し付き
            #Do nothing
          else #本文
            sentence = line.gsub(/\/|\)|\(|\,|\"/, "")
            sentence = line.split("\s")
            sentence.each {|word| for_write << "\s" + word} 
          end
        end 
        i = 0
      }
    }
  end

  
  attr_reader :ewiki_files
   
end

class JaWiki
  def initialize()
    #@jwiki_test = ["./Resources/jp_articles/jawiki-20120601-pages-articles.xml-001.txt"]
    dir = "Resources/jp_articles/"
    @jwiki_test = Dir::entries(dir).grep(/\.(txt)$/) {|f| dir + f}
    
    @jwiki_dump = "./Resources/jawiki-20120601-pages-articles.xml"
  end
  
  # ダンプから記事タイトルとそれに対応する英語エントリーを抽出
  # jp_to_eng.txtというファイルを出力
  # 使うWikipediaダンプは上の@jwiki_dumpに設定．
  def extract_translation()
    file = open("jp_to_eng.txt", "a") #追記モードでオープン
    open(@jwiki_dump, 'r') {|wiki|
      jp_title = ""
      en_title = ""
      joined_title = ""
      while line = wiki.gets
        if line =~ /<title>(.+)<\/title>/ then
          jp_title = $+
        elsif line =~ /^\[\[en:(.+)\]\]/ then
          en_title = $+
          if en_title =~ /\((disambiguation)|(List of|Category)|(Template)|(File)|(Wikipedia:)/ then
            # Do nothing
          elsif jp_title =~ /\((曖昧さ)|(List of)|(Category)|(Template)|(^ファイル)/ then
              # Do nothing
          else
            joined_title = jp_title + "\t" + en_title + "\n"
            file.write joined_title
          end
        end
      end
    }
  end
  
  # WP2TXTで抽出した記事から英語版が存在しない記事を取り除く
  def remove_unconnected_article()
    union_list = []
    jp_en = []
    for_write = ""
    article_name = ""
    article_name_check = ""
    i = 0
    counter = 0
    
    # 英語版がある日本語版記事を配列union_listに格納
    open("union.txt", "r") { |u|
      while line = u.gets
        jp_en = line.split("\t")
        union_list << jp_en[0]  
      end
    }
    
    union_list.each {|union| p union} 
    
    p "-----------------------------------------------------------"
    
    @jwiki_test.each {|wiki_file|
      open(wiki_file, 'r') { |wiki|
        while line = wiki.gets
          if line =~ /^\[\[(.+)\]\]/ then #記事タイトルの行を読み込んだ場合
            if i == 0 then #最初のタイトルの読み込み
              file = open("jparticle_selected.txt", "a")
              article_name = line
              i = 1
            else # ２回目以降
              # if文の条件    
              # 10単語以上のタイトルは除外．本文を持たない記事は除外．
              # 日本語記事を持たない記事は除外
              artist_name_check = article_name.gsub(/\[\[|\]\]|\n/, "")
              p artist_name_check + "Checking"
              if (for_write != "") && (union_list.index(artist_name_check) != nil) then
                p "Writing\s\s" + article_name
                file.write article_name + "\n" + for_write
                counter = counter + 1
                p counter
                article_name = line
                for_write = "" 
              else
                article_name = line
                for_write = "" 
              end
            end
            for_write = ""   
          elsif line =~ /^\=\=\=/  then #H3見出し付き
            #Do nothing
          elsif line =~ /^\=\=/  then #H2見出し付き
            #Do nothing
          else #本文
            sentence = line.gsub(/\/|\)|\(|\,|\"/, "")
            sentence = line.split("\n")
            sentence.each {|word| for_write << word} 
          end
        end 
        i = 0
      }
    }
  end
  
  attr_reader :jwiki
end

class Processing
  #訳語を見つける．
  def disambiguation(noun_hash)
  end
  # 文章中の名詞をKey, 登場回数をValueとするハッシュを返す．
  def get_noun(text)
    tag = EngTagger.new
    tagged = tag.add_tags(text)
    nouns = tag.get_nouns(tagged)
    nouns
  end
  
  # 行数を数える.ファイルへのpathを引数にする．
  def count_line(file)
    i = 0
    open(file, 'r') {|wiki|
      while wiki.gets
        i = i + 1
      end
    }
    i
  end

  # eng_to_jp.txtとjp_to_eng.txtを結合
  def get_union()
    en = []
    ja = []
    
    open("eng_to_jp.txt", 'r') { |wiki|
      while line = wiki.gets
        en << line
      end
    }
    
    open("jp_to_eng.txt", 'r') { |wiki|
      while line = wiki.gets
        ja << line
      end
    }
    
    union = (en | ja)
    f = open("union.txt", 'a')
    union.each {|u|
      f.write u
    }
  end
  
end

##################################
# for Test

#a = Processing.new()
#a.get_noun("This is a test for future use.").each_key {|key| p key}
#p a.count_line("union.txt")
#a.get_union()

#b = EngWiki.new()
#b.remove_unconnected_article()
#b.extract_translation()

#c = JaWiki.new()
#c.extract_translation()
#c.remove_unconnected_article()

