Google Analytics Tracking Code For Mobile Written by Ruby
=========================================================

Google Analyticsの携帯用トラッキングコードをRubyで書きました。

Version
-------

+ 0.0.1 2010/11/14リリース

Usage 
-----

本家の設置の仕方と同じです。

共有ライブラリなどに記述します。
    GA_ACCOUNT = "YOUR ACCOUNT HERE"
    GA_PIXEL = "/ga.rb"
    def google_analytics_get_image_url
      url = ""
      url << GA_PIXEL + "?"
      url << "utmac=" + GA_ACCOUNT
      url << "&utmn=" + rand(0x7fffffff).to_s
      referer = ENV["HTTP_REFERER"]
      query = ENV["QUERY_STRING"]
      path = ENV["REQUEST_URI"]
      unless referer
        referer = "-"
      end
      url << "&utmr=" + CGI.escape(referer)
      if path
        url << "&utmp=" + CGI.escape(path)
      end
      url << "&guid=ON"
   
      url.gsub "&", "&amp"
    end

</body>タグの直前に貼り付けてください。
    %{<img src="#{google_analytics_get_image_url}" />}

ga.rbをサーバのルートディレクトリに保存してください。

パーミッションを忘れずに755にしてください。

Todo
----

+ Railsプラグインも作るよ！
 
copyright 2010 waco, released under the MIT license 
