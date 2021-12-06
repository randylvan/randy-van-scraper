defmodule Scraper do
  @moduledoc """
  Documentation for `Scraper`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Scraper.hello()
      :world

  """

  def main do


    {url1, url2, url3, url4, url5} = {"https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685/page1", "https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685/page2",
    "https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685/page3",
    "https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685/page4",
    "https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685/page5"}


    reviews1 = Scraper.get_review_content(url1)
    reviews2 = Scraper.get_review_content(url2)
    reviews3 = Scraper.get_review_content(url3)
    reviews4 = Scraper.get_review_content(url4)
    reviews5 = Scraper.get_review_content(url5)

    all_reviews = reviews1 ++ reviews2 ++ reviews3 ++ reviews4 ++ reviews5
      #html
      #|> Floki.find("div.review-entry p.review-content")
      #|> Enum.map(fn({_, _, [review]}) -> review end)

    #reviews_content = Scraper.get_review_content(reviews)


    #Scraper.get_response url2
    #Scraper.get_response url3
    #Scraper.get_response url4
    #Scraper.get_response url5



  end

  def get_response(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok,body}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts "Not found :("
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
    end
  end

  def get_review_content(url) do
    {:ok, response} = Scraper.get_response url
    {:ok, html} = Floki.parse_document(response)
    reviews =
    html
    |> Floki.find("div.review-entry p.review-content")
      |> Enum.map(fn({_, _, [review]}) -> review end)
  end

  def get_positive_reviews() do

  end

  def check_review_and_assign_score() do

  end

  def compare_score() do

  end

end
