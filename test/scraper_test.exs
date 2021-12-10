defmodule ScraperTest do
  use ExUnit.Case
  doctest Scraper

  @html_review_rating """
  <html>
  <head>
  <title>Review Rating</title>
  </head>
  <body>
    <div class="content">
      <div class="margin-bottom-sm line-height-150">
        <span class="italic font-16 bolder notranslate">by ribsarethebest</span>
      </div>
      <div class="pull-left pad-left-md pad-right-md bg-grey-lt margin-bottom-md review-ratings-all review-hide">
      <!-- REVIEW RATING - CUSTOMER SERVICE -->
      <div class="table width-100 pad-left-none pad-right-none margin-bottom-md">
              <div class="tr">
                  <div class="lt-grey small-text td">Customer Service</div>
                  <div class="rating-static-indv rating-50 margin-top-none td"></div>
              </div>
                      <!-- REVIEW RATING - QUALITY OF WORK -->
              <div class="tr margin-bottom-md">
                  <div class="lt-grey small-text td">Quality of Work</div>
                  <div class="rating-static-indv rating-50 margin-top-none td"></div>
              </div>
                      <!-- REVIEW RATING - FRIENDLINESS -->
              <div class="tr margin-bottom-md">
                  <div class="lt-grey small-text td">Friendliness</div>
                  <div class="rating-static-indv rating-50 margin-top-none td"></div>
              </div>
                      <!-- REVIEW RATING - PRICING -->
              <div class="tr margin-bottom-md">
                  <div class="lt-grey small-text td">Pricing</div>
                  <div class="rating-static-indv rating-50 margin-top-none td"></div>
              </div>
                      <!-- REVIEW RATING - EXPERIENCE -->
              <div class="tr margin-bottom-md">
                  <div class="td lt-grey small-text">Overall Experience</div>
                  <div class="rating-static-indv rating-50 margin-top-none td"></div>
              </div>
          <!-- REVIEW RATING - RECOMMEND DEALER -->
          <div class="tr">
              <div class="lt-grey small-text td">Recommend Dealer</div>
              <div class="td small-text boldest">
                  Yes
              </div>
          </div>
      </div>
    </div>
  </body>
  </html>
  """

  test "retrieve review body" do
    result = "Jesse was great and we will be coming back!"

    {:ok, html} =
      Floki.parse_document(
        "<p><span class=review-title>Jesse was great</span><span class=review-title> and we will be coming back!</span></p>"
      )

    review_body = Scraper.get_review_body(html)
    assert review_body == result
  end

  test "retrieve review user" do
    result = "ribsarethebest"
    {:ok, html} = Floki.parse_document(@html_review_rating)
    assert Scraper.get_review_user(html) == result
  end

  test "retrieve review stars" do
    result = "*"
    assert Scraper.get_review_stars("10") == result
  end

  test "value does not match any stars" do
    result = 0
    assert Scraper.get_review_stars("100") == result
  end

  test "calculate review score" do
    content = "I am in love with your review! I wish everyone could see how amazing your shop is."
    pos_words = ["great", "awesome", "amazing", "love"]

    assert Scraper.get_review_score(content, pos_words) == 2
  end

  test "receive path and return a map of values" do
    result = ["zenith", "zest", "zippy"]
    path = Path.absname("files/word-example.txt")

    assert Scraper.get_list(path) == result
  end

  test "retrieve ratings" do
    {:ok, response} = Floki.parse_document(@html_review_rating)
    result = ["*****", "*****", "*****", "*****", "*****", "Yes"]

    assert Scraper.get_review_ratings(response) == result
  end
end
