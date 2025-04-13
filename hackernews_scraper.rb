# hackernews_scraper.rb
require 'playwright'
require 'json'

class HackerNewsScraper
  def initialize(max_retries: 3)
    @max_retries = max_retries
  end
  
  def scrape
    retries = 0
    
    while retries < @max_retries
      begin
        puts "스크래핑 시작 (시도 #{retries + 1}/#{@max_retries})..."
        articles = scrape_hackernews
        save_articles(articles)
        return articles
      rescue => e
        puts "오류 발생: #{e.message}"
        puts e.backtrace
        retries += 1
        
        if retries >= @max_retries
          puts "최대 재시도 횟수를 초과했습니다."
          raise e
        end
        
        sleep_time = retries * 3
        puts "#{sleep_time}초 후 재시도합니다..."
        sleep(sleep_time)
      end
    end
  end
  
  private
  
  def scrape_hackernews
    articles = []
    
    Playwright.create(playwright_cli_executable_path: './node_modules/.bin/playwright') do |playwright|
      playwright.chromium.launch(headless: false) do |browser|
        puts '브라우저를 시작합니다...'
        
        # 새 컨텍스트 생성
        context = browser.new_context(
          viewport: { width: 1280, height: 800 },
          userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        )
        
        page = context.new_page
        
        # 페이지 설정
        page.set_default_timeout(30000) # 30초 타임아웃
        
        # HackerNews로 이동
        puts 'HackerNews로 이동합니다...'
        page.goto('https://news.ycombinator.com/', waitUntil: 'networkidle')
        
        # 스크린샷 촬영
        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        page.screenshot(path: "hackernews_#{timestamp}.png")
        
        puts '뉴스 기사를 수집합니다...'
        
        # 뉴스 항목 선택자
        items = page.locator('tr.athing')
        count = items.count
        
        puts "#{count}개의 항목을 발견했습니다."
        
        # 각 항목 처리
        (0...count).each do |i|
          item = items.nth(i)
          
          # 필요한 요소 추출
          id = item.get_attribute('id')
          title_element = item.locator('td.title > span.titleline > a')
          title = title_element.text_content
          url = title_element.get_attribute('href')
          
          site_element = item.locator('span.sitestr')
          site = site_element.count > 0 ? site_element.text_content : ''
          
          # 다음 행 찾기
          subtext = page.locator("tr:has(#score_#{id})").last
          
          # 점수 추출
          score_element = subtext.locator('.score')
          score = score_element.count > 0 ? score_element.text_content : 'No score'
          
          # 댓글 수 추출
          comment_element = subtext.locator("a[href=\"item?id=#{id}\"]").last
          comments = comment_element.count > 0 ? comment_element.text_content : '0 comments'
          
          # 작성자 추출
          author_element = subtext.locator('.hnuser')
          author = author_element.count > 0 ? author_element.text_content : 'Unknown'
          
          articles << {
            id: id,
            title: title,
            url: url,
            site: site,
            score: score,
            comments: comments,
            author: author
          }
        end
        
        puts "#{articles.length}개의 기사를 수집했습니다."
      end
    end
    
    articles
  end
  
  def save_articles(articles)
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "hackernews_#{timestamp}.json"
    
    File.write(filename, JSON.pretty_generate(articles))
    puts "결과를 #{filename}에 저장했습니다."
    
    filename
  end
end

scraper = HackerNewsScraper.new
begin
  scraper.scrape
  puts "스크래핑이 성공적으로 완료되었습니다."
rescue => e
  puts "스크래핑 실패: #{e.message}"
end
