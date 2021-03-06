require "kemal"
require "markd"
require "json"

module Policr::Web
  extend self

  class Section
    include JSON::Serializable

    @[JSON::Field(ignore: true)]
    getter prefix : String
    getter title : String
    getter anchor : String
    getter content : String

    def initialize(@prefix, @title, @anchor)
      content = File.read("texts/#{@prefix}_#{anchor}.md")
      content = render content, ["version", "torture_sec"], [VERSION, DEFAULT_TORTURE_SEC]
      @content = Markd.to_html content
    end
  end

  class PageContent
    include JSON::Serializable

    @[JSON::Field(ignore: true)]
    getter prefix : String
    getter title : String
    getter subtitle : String
    getter sections : Array(Section)

    def initialize(@prefix, @title, @subtitle, @sections = Array(Section).new)
    end

    def <<(title : String, anchor : String)
      sections << Section.new @prefix, title, anchor
      self
    end
  end

  QA_PAGE = PageContent.new("qa", "常见问题", "通过本页，解答各种疑惑")
    .<<("审核具体指的什么？", "examine")
    .<<("为什么加群要验证？", "verification")
    .<<("哪种验证方式最好？", "best_verification")
    .<<("为什么要针对清真？", "halal")
    .<<("举报的益处有什么？", "report")
    .<<("验证失败都是假人？", "verification_failure")
    .<<("验证失败的后果是？", "verification_failure_result")
    .<<("不限时验证的害处？", "no_time_limit")
    .<<("解释何为记录模式？", "record_mode")
    .<<("解释何为干净模式？", "clean_mode")
    .<<("定制验证最佳实践？", "best_custom")
    .<<("为何建议信任管理？", "trust_admin")
    .<<("不信任能使用按钮？", "distrust_button_use")
    .<<("来源调查功能意义？", "from")
    .<<("白名单范围有多大？", "whitelist")
    .<<("内联键盘干嘛失效？", "inline_keyboard_invalid")
    .<<("为何突然事后审核？", "afterwards")
    .<<("订阅全局规则好处？", "global_rules")

  ADVANCED_PAGE = PageContent.new("adv", "高级教程", "通过本页，更好的使用")
    .<<("仅限制而不封禁用户", "only_restriction")
    .<<("无错验证的设置方式", "unable_error")
    .<<("欢迎消息的贴纸模式", "sticker_mode")
    .<<("欢迎内容中嵌入链接", "welcome_embed_links")
    .<<("欢迎内容中使用变量", "welcome_embed_vars")
    .<<("给欢迎消息添加按钮", "welcome_add_button")
    .<<("问题模板中嵌入链接", "template_embed_links")
    .<<("问题模板中使用变量", "template_embed_vars")

  PRIVACY_PAGE = PageContent.new("pri", "隐私政策", "通过本页，了解隐私条款")
    .<<("政策说明", "term_desc")
    .<<("消息访问", "message_access")
    .<<("数据存储", "data_storage")

  def home_page?(env : HTTP::Server::Context)
    env.request.path == "/"
  end

  def start(port : Int, prod : Bool, bot : Bot)
    serve_static({"gzip" => false})
    public_folder "static"
    Kemal.config.logger = LoggerHandler.new(Logging.get_logger)

    after_all "/api/*" do |env|
      env.response.content_type = "application/json"
    end

    get "/api/advanced" do
      ADVANCED_PAGE.to_json
    end

    get "/api/qa" do
      QA_PAGE.to_json
    end

    get "/api/privacy" do
      PRIVACY_PAGE.to_json
    end

    get "/ignored_count" do
      bot.ignored_counter.to_s
    end

    get "/" do
      render "src/views/user.html.ecr"
    end

    get "/*" do
      render "src/views/user.html.ecr"
    end

    error 404 do
      "Not Found"
    end

    Kemal.config.env = "production" if prod
    Kemal.run(args: nil, port: port)
  end
end
