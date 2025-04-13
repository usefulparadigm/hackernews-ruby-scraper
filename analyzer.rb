# analyzer.rb
require 'json'

class HackerNewsAnalyzer
  def initialize(filename)
    @filename = filename
    @articles = JSON.parse(File.read(filename), symbolize_names: true)
    puts "#{@articles.length}개의 기사를 분석합니다..."
  end
  
  def analyze
    # 점수 추출 및 숫자로 변환
    scores = @articles.map do |article|
      score_text = article[:score]
      score_match = score_text.match(/(\d+)/)
      score_match ? score_match[1].to_i : 0
    end
    
    # 기본 통계 계산
    total_score = scores.sum
    avg_score = total_score.to_f / scores.length
    max_score = scores.max
    min_score = scores.select { |s| s > 0 }.min
    
    # 도메인별 글 개수
    domain_counts = Hash.new(0)
    @articles.each do |article|
      domain = article[:site].to_s.empty? ? '(no domain)' : article[:site]
      domain_counts[domain] += 1
    end
    
    # 상위 도메인 추출
    top_domains = domain_counts.sort_by { |_, count| -count }.take(5)
    
    # 결과 출력
    puts "\n===== 분석 결과 ====="
    puts "총 기사 수: #{@articles.length}"
    puts "평균 점수: #{avg_score.round(2)} 포인트"
    puts "최고 점수: #{max_score} 포인트"
    puts "최저 점수: #{min_score} 포인트"
    
    puts "\n상위 5개 도메인:"
    top_domains.each_with_index do |(domain, count), index|
      puts "#{index + 1}. #{domain}: #{count}개 기사"
    end
    
    # 최고 점수 기사 찾기
    top_article = @articles.max_by do |article|
      score_match = article[:score].match(/(\d+)/)
      score_match ? score_match[1].to_i : 0
    end
    
    puts "\n최고 점수 기사:"
    puts "제목: #{top_article[:title]}"
    puts "URL: #{top_article[:url]}"
    puts "점수: #{top_article[:score]}"
    puts "작성자: #{top_article[:author]}"
  end
end

# 최신 파일 찾기
files = Dir['hackernews_*.json'].sort
if files.empty?
  puts "분석할 데이터 파일이 없습니다."
  exit(1)
end

latest_file = files.last
puts "최신 파일 #{latest_file}을 분석합니다."

analyzer = HackerNewsAnalyzer.new(latest_file)
analyzer.analyze
