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
    base_url = "https://www.dealerrater.com/dealer/McKaig-Chevrolet-Buick-A-Dealer-For-The-People-dealer-reviews-23685/page"
    IO.puts("Please wait while we uncover the worst offenders of overly positive reviews for the following dealer: McKaig Chevrolet Buick")
    Scraper.get_reviews(base_url, 5);
  end

  def get_reviews(url, pages) do
    Enum.map(1..pages, fn x ->
      Scraper.get_review_content("#{url}#{x}")
    end)
    #|> List.flatten
  end

  @spec get_review_body(
          binary
          | [
              binary
              | {:comment, binary}
              | {:pi | binary, binary | [{any, any}], list}
              | {:doctype, binary, binary, binary}
            ]
        ) :: nonempty_binary
  def get_review_body (review) do
    review_head = Floki.find(review, ".review-title")
    |> Floki.text
    |> String.trim

    review_tail = Floki.find(review, ".review-whole")
    |> Floki.text
    |>String.trim
    "#{review_head} #{review_tail}"
  end

  def get_review_user(review) do
    Floki.find(review, "span.italic.font-16.bolder.notranslate")
          |>Floki.text
          |>String.replace("by ", "")
  end

  def get_review_ratings(review) do
    Floki.find(review, ".review-ratings-all")
          |> Enum.map(fn rating ->
            Floki.find(rating, ".tr")
            |> Enum.map(fn ind_ratings ->
              title = Floki.find(ind_ratings, "div.lt-grey.small-text.td")
              |> Floki.text
              |> String.replace(" ", "_")
              |> String.downcase
              |> String.to_atom()

              ind_rating = Floki.find(ind_ratings, "div.rating-static-indv")
              |> Floki.attribute("class")
              |> Enum.map(fn x-> String.replace(x,~r/[^\d]/, "") end)
              |> Enum.map(fn x -> Scraper.get_number(x) end )
              |> List.first(0)

              ind_rating =
                cond do
                  ind_rating == 0 -> ind_ratings
                                     |> Floki.find("div.td.small-text.boldest")
                                     |> Floki.text
                                     |> String.trim
                  true -> ind_rating
              end
              %{title => ind_rating}
            end)
          end)
  end



  def get_number(value) do
      cond do
        value == "10" -> 1
        value == "20" -> 2
        value == "30" -> 3
        value == "40" -> 4
        value == "50" -> 5
        true -> "No value found"
    end
  end

  def get_list(path) do
      File.stream!(path)
      |>Enum.map(fn x -> String.trim(x) end )
  end


  @spec get_response(binary) :: any
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
    positive_words = get_list("/Users/rvan/Desktop/projects/ElixirProjects/rvan_scraper/scraper/lib/positive-words.txt")
    {:ok, body} = Scraper.get_response url
    {:ok, html} = Floki.parse_document(body)
    reviews =
      html
      |> Floki.find("div.review-entry")
      |> Enum.map(fn review ->
          review_body = Scraper.get_review_body(review)
          review_user = Scraper.get_review_user(review)
          ratings = Scraper.get_review_ratings(review)
          score = Scraper.get_score(review_body, positive_words)
        %{review_body: review_body,user: review_user,ratings: ratings,score: score}
      end)
      {:ok, reviews}

  end

  def get_score(content, positive_words) do
    positive_words
    |> Enum.map(fn x ->
      if String.contains?(content,x) == true do
        1
      else
        0
      end
    end )
    |> Enum.sum
  end
end
